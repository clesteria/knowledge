#[[Deploy]] #[[Linux]] #[[proxmox]]

## 初期設定

### sshd

- /etc/sshd_config は触らず、/etc/ssh/sshd_config.d に confg を置いて必要なパラメータを上書きする。
- 標準ポートにしないなら、 `${SSHD_PORT}` には、ssh用のポート番号を入れておく。

```shell
cat <<_EOF_ > /etc/ssh/sshd_config.d/10-proxmox.conf
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
Port ${SSHD_PORT:-22}
_EOF_
```

- サービス再起動が必要。

```shell
systemctl restart sshd
```

### 管理用ユーザ追加

- rootで運用前提なのかインストール時にユーザが作られないので自分で作る。
- wheelグループがないので作る。
- `${NEWUSER}` には、ユーザ名を入れておく。

```shell
addgroup --system wheel
useradd ${NEWUSER} -G wheel -m -d /home/${NEWUSER}
```

### doas

- OpenBSDで採用されてる軽量 `sudo` 的コマンド。
  - これを入れても `sudo` が捨てられるわけではないのであまり意味はない。
- wheelグループのみ使用を許可する設定をする。

```shell
apt install doas -y
echo 'permit persist :wheel' >> /etc/doas.conf
doas -C /etc/doas.conf
chmod 400 /etc/doas.conf
```

- 以降、基本的に前項で作った管理用ユーザでログインし直す。

### ファイアウォール

- Proxmoxの操作コマンドである `pvesh` で設定する。
  - `ufw` を入れる手順ばかりだったが、折角専用ツールがあるのだからと使う。
- `${INTERNAL_NETWORK}` は `192.168.1.0/24` というような形式でLANのネットワークアドレスを入れておく。

```shell
doas pvesh create /cluster/firewall/ipset --name management
doas pvesh create /cluster/firewall/ipset/management --cidr ${INTERNAL_NETWORK} --comment 'Local Network'
```

- LAN以外は全部ブロックする。

```shell
doas pvesh set /cluster/firewall/options --enable 1 --policy_in DROP
doas pvesh create /cluster/firewall/rules --action ACCEPT --type in --source +management --enable 1 --comment 'Allow Management LAN Access'
```

- サービス再起動が必要。

```shell
doas systemctl restart pve-firewall
```

### cloudflaredインストール

- 安全に外から接続するために入れる。
- 公式の手順に従う。
- `${CLOUDFLARED_TOKEN}` には、トンネル作成時に表示されたトークンを入れる。

```shell
mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list
apt update
apt install cloudflared
cloudflared service install ${CLOUDFLARED_TOKEN}
```

## ターミナル環境整備

### gitインストール

- homebrew に必要だったので入れる。
  - homebrew は `eza` と `yash` のために必要。

```shell
doas apt install git -y
```

### homebrewインストール

- /home 配下に homebrew 用ディレクトリを作る。

```shell
doas mkdir -p /home/linuxbrew/.linuxbrew
doas chown -R 1000:1000 /home/linuxbrew
```

- 公式の手順に従う。

```shell
cd /home/linuxbrew
curl -L https://github.com/Homebrew/brew/tarball/main | tar xz --strip-components 1 -C .linuxbrew
eval "$(.linuxbrew/bin/brew shellenv)"
brew update --force --quiet
chmod -R go-w "$(brew --prefix)/share/zsh"
```

### yashインストール

- POSIX準拠モードという素敵なモードがあるシェル。
- なんとなく使ってただけの `zsh` よりも軽い気がする。

```shell
brew install yash
```

- ログインシェルにする。

```shell
echo "/home/linuxbrew/.linuxbrew/bin/yash" | doas tee -a /etc/shells
chsh -s /home/linuxbrew/.linuxbrew/bin/yash
```

- .yashrc をサンプルからコピー。

```shell
cp -p /home/linuxbrew/.linuxbrew/Cellar/yash/2.60/share/yash/initialization/sample ~/.yashrc
```

- .yashrc に homebrew 用の設定を追記する。

```shell
cat <<_EOF_ >> .yashrc

# homebrew
if test -e /home/linuxbrew/.linuxbrew/bin/brew; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
_EOF_
```

### ezaインストール

- rust製 `ls` 互換コマンド。
  - これの表示に慣れたので、標準の `ls` だと落ち着かないだけで有効活用はできていない。 

```shell
brew install eza
```

- .yashrc に `ls` として振る舞うためのエイリアスを追加。

```shell
cat <<_EOF_ >> .yashrc

# eza
which eza > /dev/null 2>&1 && alias ls='eza -g'
_EOF_
```

## proxmoxの設定

### WebUIのサブスクリプション通知メッセージ抑止

- via https://qiita.com/flathill/items/01321c48bdf8022fa37e
- 616行目辺りのIF文を修正した。

```shell
vi /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
```

### メール抑止

- システムから送られてくるメールの通知がターミナルに出るのを抑止。
- `postfix` のサービスを停止。

```shell
doas systemctl stop postfix
doas systemctl disable postfix
```

### ログインメッセージ抑止

```shell
doas rm /etc/motd
doas rm /etc/issue
```

## ディスプレイ表示のタイムアウト設定

- `GRUB_CMDLINE_LINUX_DEFAULT` の末尾に `consoleblank=5 nomodeset video=efifb` を追加。

```shell
vi /etc/default/grub
```

- 変更を適用して再起動

```shell
update-grub
reboot
```

- ただし、実際には反映されておらず、ディスプレイは付きっぱなし。

## VM関係

### VM用内部ネットワーク作成

- LANとは隔離したVM用ネットワークを作る。
  - proxmoxの機能ではなく、Linuxの仮想NICを作るだけ。

```shell
cat << _EOF_ | doas tee -a /etc/network/interfaces

auto vmbr1
iface vmbr1 inet static
    address 10.10.10.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
_EOF_
```

- サービス再起動で反映。

```shell
systemctl restart networking
```

### NAT設定

- VM用ネットワークをNATで外部に繋げる。
  - 外からは直接繋がらず、VMからは外に繋がる。

```shell
echo '1' | doas tee /proc/sys/net/ipv4/ip_forward > /dev/null
echo 'net.ipv4.ip_forward = 1' | doas tee /etc/sysctl.d/99-ip-forward.conf > /dev/null
doas sysctl -p /etc/sysctl.d/99-ip-forward.conf
```

```shell
doas iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o vmbr0 -j MASQUERADE
doas apt install iptables-persistent
doas netfilter-persistent save
doas netfilter-persistent reload
```

- サービス再起動で反映。

```shell
doas systemctl restart pveproxy
doas systemctl restart pvedaemon
```

### dnsmasq追加・無効化

- 必要があったので入れたはずだが、どうして無効にしたのかは憶えてない。

```shell
doas apt install -y dnsmasq
doas systemctl stop dnsmasq
doas systemctl disable dnsmasq
```
