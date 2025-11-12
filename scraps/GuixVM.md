## GuixVM

### Create

```shell
doas /sbin/qm create 101 --name guix --memory 2048 --cores 2 --net0 virtio,bridge=vmbr1 --ostype l26 --scsihw virtio-scsi-pci
doas /sbin/qm set 101 --serial0 socket
doas /sbin/qm set 101 --ide2 local:iso/guix-system-install-1.4.0.x86_64-linux.iso,media=cdrom
doas /sbin/qm set 101 --scsi0 local-lvm:vm-101-disk-0
doas /sbin/qm set 101 --boot order=scsi0
```

```shell
doas /sbin/qm start 101
```

### NIC

```shell
herd stop networking
ip l set dev eth0 down
ip a flush dev eth0
ip r flush dev eth0
ip a add 10.10.10.2/24 dev eth0
ip l set dev eth0 up
ip r add default via 10.10.10.1
```

### nameserver

```shell
cat << _EOF_ > /etc/resolv.conf
nameserver 1.1.1.1
nameserver 1.0.0.1
_EOF_
```

### Partition

```shell
cfdisk
parted /dev/sda set 1 esp on
mkfs.fat -F32 /dev/sda1
mkfs.ext4 -L root /dev/sda3
mount LABEL=root /mnt
mkswap /dev/sda2
swapon /dev/sda2
```

### Install

```shell
mkdir /mnt/etc
cp -p /etc/configuration/bare-bones.scm /mnt/etc/config.scm
vi /mnt/etc/config.scm
herd start cow-store /mnt
guix system init /mnt/etc/config.scm /mnt
```

```guile
  (initrd-modules (append (list "virtio_scsi")
                          %base-initrd-modules))
```
