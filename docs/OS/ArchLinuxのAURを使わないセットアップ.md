#[[Deploy]] #[[Linux]] #[[Arch Linux]]

できるだけ軽量に済ませたい環境として使うための手順。

## インストール

### ネットワーク設定

- WiFiのアクセス設定をする。

```shell
iwctl station list
iwctl station wlan0 get-networks
iwctl station wlan0 connect <SSID>
iwctl station wlan0 show
```

### インストール

- インストール内容はファイルに保存しているものを使う。
- ユーザー認証は都度設定するのでファイル指定しない。

```shell
archinstall --config /tmp/user_configuration.json
```

## セットアップ

### doas

- OpenBSDで採用されてる軽量 `sudo` 的コマンド。
  - これを入れても `sudo` が捨てられるわけではないのであまり意味はない。
- wheelグループのみ使用を許可する設定をする。
- インストール自体は `archinstall` で実施済み。

```shell
echo 'permit persist :wheel' >> /mnt/etc/doas.conf
```

### ログインシェル変更

- AUR がないので、`zsh` で妥協する。

```shell
chsh -s /usr/bin/zsh
```

### ネットワーク

- `iwd` を有効化。

```shell
doas systemctl enable iwd
doas systemctl start iwd
```

- systemdで設定するため、iwdでの設定を無効化、およびIPv6の無効化。

```shell
cat <<_EOF_ | doas tee -a /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=false

[Network]
EnableIPv6=false
_EOF_
```

- 不要な設定ファイルを削除

```shell
doas rm /etc/systemd/network/20-wlan.network
```

- systemd でのネットワーク設定ファイルを作成。
- 各種変数は先にネットワーク環境に適したアドレス等を入れておく。

```shell
cat <<_EOF_ | doas tee /etc/systemd/network/20-wlan0.network
[Match]
Name=wlan0

[Network]
DHCPServer=false
Address=${WLAN_IPADDRESS}
Gateway=${WLAN_GATEWAY}
DNS=${WLAN_DNS}
_EOF_
```

### sshd

- /etc/sshd_config は触らず、/etc/ssh/sshd_config.d に confg を置いて必要なパラメータを上書きする。
- 標準ポートにしないなら、 `${SSHD_PORT}` には、ssh用のポート番号を入れておく。

```shell
cat <<_EOF_ > /etc/ssh/sshd_config.d/10-default.conf
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
Port ${SSHD_PORT:-22}
_EOF_
```

- デーモンとして起動。

```shell
doas systemctl enable sshd
doas systemctl start sshd
```

### ファイアウォール

- `ufw` を使用する。
- LANからの `ssh` 以外は全部ブロックする。
- `sshd` の設定を標準ポートにしていないなら、 `${SSHD_PORT}` には、ssh用のポート番号を入れておく。
- `${INTERNAL_NETWORK}` は `192.168.1.0/24` というような形式でLANのネットワークアドレスを入れておく。

```shell
doas ufw default DENY
doas ufw allow proto tcp from ${INTERNAL_NETWORK} to any port ${SSHD_PORT:-22}
doas ufw limit ${SSHD_PORT:-22}
doas ufw enable
```

### ノートPCを閉じた時の動作

- ノートPCを閉じた時、電源の状態に関わらず、何もしないように変更する。

```shell
doas sed -i -r "s/^#(HandleLidSwitch[a-zA-Z]*)=.+/\1=ignore/g" /etc/systemd/logind.conf
```

### dotfiles

- 自分の GitHub から dotfiles リポジトリを clone する。
  - `--shallow` を入れたいが、認証が必要になるのでしない。

```shell
ghq get https://github.com/clesteria/dotfiles.git
```

- ホームディレクトリからリポジトリ内ファイルへのシンボリックリンクを作成する。

```shell
cd $(ghq root)/github.com/clesteria/dotfiles
./create_link.sh
```

### コンテナ

- `podman` を使う。
- コンテナレジストリの省略時に補完される内容を定義する。

```shell
mkdir -p ~/.config/containers
cat <<_EOF_ > ~/.config/containers/registries.conf
unqualified-search-registries = ["docker.io"]
short-name-mode = "permissive"
_EOF_
```

### neovim

- LazyVim を入れる。

```shell
git clone --depth 1 https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
nvim
```

### cloudflared

- `pacman` でインストール。
  - `archinstall` でも入れられるかもしれない。

```shell
pacman -S cloudflared
```

- デーモンとして起動。
  - start後に返ってくるのに時間がかかる。

```shell
doas cloudflared service install ${CLOUDFLARED_TOKEN}
doas systemctl enable cloudflared
doas systemctl start cloudflared
```

