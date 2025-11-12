## proxmox

### sshd

```shell
cat << _EOF_ > /etc/ssh/sshd_config.d/10-proxmox.conf
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
_EOF_
```

```shell
systemctl restart sshd
```

### doas

```shell
addgroup --system wheel
ADD_USERNAME="<user>"
useradd ${ADD_USERNAME} -d /home/${ADD_USERNAME}
```

```shell
usermod -aG wheel ${ADD_USERNAME}
apt install doas -y
echo 'permit persist :wheel' >> /etc/doas.conf
doas -C /etc/doas.conf
chmod 400 /etc/doas.conf
```

### pve-firewall


```shell
doas pvesh set /cluster/firewall/options --enable 1 --policy_in DROP
```

```shell
doas pvesh create /cluster/firewall/ipset --name management
doas pvesh create /cluster/firewall/ipset/management --cidr 192.168.100.0/24 --comment 'Local Network'
doas pvesh create /cluster/firewall/rules --action ACCEPT --type in --source +management --enable 1 --comment 'Allow Management LAN Access'
```

```shell
doas systemctl restart pve-firewall
```

### git

homebrewに必要

```shell
doas apt install git -y
```

### homebrew

```shell
doas mkdir -p /home/linuxbrew/.linuxbrew
doas chown -R 1000:1000 /home/linuxbrew
cd /home/linuxbrew
curl -L https://github.com/Homebrew/brew/tarball/main | tar xz --strip-components 1 -C .linuxbrew
eval "$(.linuxbrew/bin/brew shellenv)"
brew update --force --quiet
chmod -R go-w "$(brew --prefix)/share/zsh"
```

### yash

```shell
brew install yash
```

```shell
echo "/home/linuxbrew/.linuxbrew/bin/yash" | doas tee -a /etc/shells
chsh -s /home/linuxbrew/.linuxbrew/bin/yash
```

```shell
cp -p /home/linuxbrew/.linuxbrew/Cellar/yash/2.60/share/yash/initialization/sample ~/.yashrc
cat << _EOF_ >> .yashrc

## homebrew
if test -e /home/linuxbrew/.linuxbrew/bin/brew; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
_EOF_
```

### eza

```shell
brew install eza
```

```shell
cat << _EOF_ >> .yashrc

## eza
if which eza > /dev/null 2>&1; then
  alias ls='eza -g'
  alias ll='eza -lagh --git --time-style full-iso'
fi
_EOF_
```

### WebUI

```shell
vi /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
```

616行目

### postfix

```shell
doas systemctl stop postfix
doas systemctl disable postfix
```

### motd, issue

```shell
doas rm /etc/motd
doas rm /etc/issue
```

### cloudflared

```shell
mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list
apt update
apt install cloudflared
cloudflared service install <token>
```

### display

```shell
vi /etc/default/grub
update-grub
reboot
```

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet consoleblank=5 nomodeset video=efifb"
```

### vnet

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

```shell
systemctl restart networking
```

### NAT

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

```shell
doas systemctl restart pveproxy
doas systemctl restart pvedaemon
```

### lxc

```shell
doas apt install -y dnsmasq
doas systemctl stop dnsmasq
doas systemctl disable dnsmasq
```
