## WSLでのArchLinuxセットアップ

### Install

```powershell
wsl --install archlinux
```

### Init (1)

```shell
passwd
pacman -Syu
pacman -S --noconfirm base-devel git neovim
```

### pacman

```shell
nvim /etc/pacman.conf
```

```text
Color
ILoveCandy
```

```shell
nvim /etc/sudoers
```

```text
%wheel ALL=(ALL:ALL) ALL
```

### User

```shell
USERNAME=
groupadd -g 1000 ${USERNAME}
useradd -d /home/${USERNAME} -g 1000 -u 1000 -G wheel -s /usr/bin/bash -m ${USERNAME}
cat << _EOF_ >> /etc/wsl.conf
[user]
default=${USERNAME}
_EOF_
passwd ${USERNAME}
```

### doas

```shell
pacman -S --noconfirm doas
echo 'permit persist :wheel' >> /etc/doas.conf
```

### reboot

```shell
exit
```

```powershell
wsl -t archlinux
wsl -d archlinux
```

### LazyVim

```shell
git clone --depth 1 https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

```shell
cat << _EOF_ > ~/.config/nvim/lua/plugins/colorscheme.lua
return {
  { "sonph/onehalf" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onehalfdark",
    },
  },
}
```

### yay

```shell
mkdir -p ~/codes/aur && cd $_
git clone --depth 1 https://aur.archlinux.org/yay.git
cd yay
makepkg -si
pacman -Qi yay
```

```shell
yay --sudo doas --save
```

### nim

```shell
yay -S choosenim
```

```shell
nimble stable
```

### yash

```shel
yay -S yash
```

### ghq

```shell
yay -S ghq
```

```shell
mkdir ~/ghq
```

### eza 

```shell
yay -S eza
```

### locale

```shell
doas sed -i -e "s:^#ja_JP.UTF-8:ja_JP.UTF-8:" -e "s:^#en_US.UTF-8:en-US.UTF-8:" /etc/locale.gen
doas doas locale-gen
```

### gemini-cli

```shel
yay -S gemini-cli
```





