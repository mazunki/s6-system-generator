#!/bin/sh
set -xeu
longrunning() {
	name=$1; shift
	./s6-new-service.sh "${group}:${name}" "$@"
}
oneshot() {
	name=$1; shift
	./s6-new-service.sh --oneshot "${group}:${name}" "$@"
}
bundle() {
	name=$1; shift
	./s6-new-service.sh --bundle "${group}:${name}" "$@"
}

export DESTINATION="${PWD}/services"
test ! -e "${DESTINATION}" || { printf '%s\n' "${DESTINATION} already exists. Consider deleting it:" ": rm -r ${DESTINATION}"; exit 1; }

group="runtime"
oneshot mount-proc 'mount -o nusuid,noexec,nodev -t proc proc /proc'
oneshot mount-dev 'mount -t tmpfs devtmpfs /dev' \
	mount-procfs
oneshot mount-sys 'mount -t sysfs sys /sys; mount -n -t efivarfs -o ro efivarfs /sys/firmware/efi/efivars' \
	mount-procfs
oneshot mount-tmpfs 'mount -t tmpfs tmpfs /tmp' \
	mount-procfs
oneshot mount-cgroups 'mount -t cgroup cgroup /sys/fs/cgroup' \
	mount-procfs
oneshot early-filesystems 'mount -a -O no_netdev' \
	mount-procfs


group="core"
oneshot udev 'udevd --debug'
oneshot udevadm 'udevadm trigger --action=add --type=subsystems; udevadm trigger --action=add --type=devices; udevadm settle'
bundle devices udev udevadm

oneshot hostname 'echo ${HOSTNAME} > /proc/sys/kernel/hostname' \
	mount-procfs
oneshot localhost 'ip link set up dev lo' \
	mount-devfs mount-sysfs
oneshot corenet 'ip link set up dev "${interface:-eth0}"' \
	mount-devfs mount-sysfs localhost

longrunning tty1 'agetty -L --noclear --login-program /bin/login tty1 115200 linux' \
	hostname mount-devfs
longrunning tty2 'agetty -L --noclear --login-program /usr/bin/ly tty2 115200 linux' \
	hostname mount-devfs
longrunning tty3 'agetty -L --noclear --login-program /bin/login tty3 115200 linux' \
	hostname mount-devfs

longrunning dhcpcd 'dhcpcd --nobackground' \
	corenet hostname
longrunning cronie 'crond -n' \
	early-filesystems

oneshot files 'mount -a' \
	mount-devfs early-filesystems

group="exposed"
oneshot wireguard 'wg-quick up wg0' \
	corenet files
longrunning tor 'tor' \
	corenet files
longrunning sshd 'sshd -D' \
	corenet files
longrunning dns-server 'named' \
	corenet files
longrunning nginx 'nginx -g "daemon off;"' \
	corenet files

group="desktop"
longrunning dbus 'dbus-uuidgen --ensure=/etc/machine-id; install -m755 -o messagebus -g messagebus -d /run/dbus; dbus-daemon --system --nofork --nopidfile --print-pid=3' \
	hostname localhost files
longrunning polkit '/usr/lib/polkit-1/polkitd' \
	hostname localhost files dbus

# why do i have both running lmao
longrunning seatd 'seatd -g video'
longrunning logind '/lib64/elogind/elogind'

# create_service pipewire 'pipewire'

group="users"
# longrunning mazunki 's6-usertree'
# longrunning "games" "/path/to/games-command"

printf '%s\n' "All services have been created successfully." "Hopefully." "This fills you with determination."

