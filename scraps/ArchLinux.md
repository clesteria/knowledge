## Arch Linux

### archinstall

```shell
iwctl station list
iwctl station wlan0 get-networks
iwctl station wlan0 connect <SSID>
iwctl station wlan0 show
archinstall
```

#### doas

```shell
echo 'permit persist :wheel' >> /mnt/etc/doas.conf
```

#### Network

```shell
cat <<_EOF_ | sudo tee /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true
```

### zsh

```shell
chsh -s /usr/bin/zsh
```

### Wireless LAN

```shell
doas systemctl enable iwd
doas systemctl start iwd
```

```shell
cat <<_EOF_ | doas tee -a /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=false

[Network]
EnableIPv6=false
```

```shell
cat <<_EOF_ | doas tee /etc/systemd/network/20-wlan0.network
[Match]
Name=wlan0

[Network]
DHCPServer=false
Address=192.168.100.21/24
Gateway=192.168.100.1
DNS=192.168.100.1
_EOF_
```

### sshd

```shell
cat <<_EOF_ > /etc/ssh/sshd_config.d/10-default.conf
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
Port 5963
_EOF_
```

### ufw

```shell
doas ufw default DENY
doas ufw allow proto tcp from 192.168.100.0/24 to any port 5963 
doas ufw limit 5963
doas ufw enable
```

### logind.conf

```shell
doas sed -i -r "s/^#(HandleLidSwitch[a-zA-Z]*)=.+/\1=ignore/g" /etc/systemd/logind.conf
```

### dotfiles

```shell
ghq get https://github.com/clesteria/dotfiles.git --shallow
```

### podman

```shell
mkdir -p ~/.config/containers
cat <<_EOF_ > ~/.config/containers/registries.conf
unqualified-search-registries = ["registry.access.redhat.com", "registry.redhat.io", "docker.io"]
short-name-mode = "permissive"
_EOF_
```

### LazyVim

```shell
git clone --depth 1 https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```
```
```
