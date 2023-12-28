#!/bin/sh
#
# declare ${group} before creating the services.
#
# longrunning <service_name> <cmd...> [-- [dependencies...] [-- [down_cmd...]]]
#
#	cmd: each argument is a newline. runs with #!/bin/sh
#	dependencies: other service_names
#
# oneshot <service_name> <cmd...> [-- [dependencies...] [-- [down_cmd...]]]
#	cmd: each argument is a newline. runs with execline
#	dependencies: each dependency is a service_name
#
# bundle <service_name> [--] [items...]
#	items: each item is a service_name
#
group="runtime"
oneshot mount-proc 'mount -o nusuid,noexec,nodev -t proc proc /proc'
oneshot mount-dev 'mount -t tmpfs devtmpfs /dev' -- \
	mount-proc
oneshot mount-sys 'mount -t sysfs sys /sys' -- \
	mount-proc
oneshot mount-efivars 'mount -n -t efivarfs -o ro efivarfs /sys/firmware/efi/efivars' -- \
	mount-proc mount-sys
oneshot mount-tmpfs 'mount -t tmpfs tmpfs /tmp' -- \
	mount-proc
oneshot mount-cgroups 'mount -t cgroup cgroup /sys/fs/cgroup' -- \
	mount-proc mount-sys
oneshot early-filesystems 'mount -a -O no_netdev' -- \
	mount-proc mount-sys mount-cgroups


group="core"
oneshot udev 'udevd --debug'
oneshot udevadm 'foreground { udevadm trigger --action=add --type=subsystems }' 'foreground { udevadm trigger --action=add --type=devices }' 'udevadm settle'
bundle devices udev udevadm

oneshot hostname 'redirfd -w 1 /proc/sys/kernel/hostname echo ${HOSTNAME}'  -- \
	mount-proc
oneshot localhost 'ip link set up dev lo' -- \
	mount-dev mount-sys
oneshot corenet 'ip link set up dev ${interface}' -- \
	mount-dev mount-sys localhost

longrunning tty1 'agetty -L --noclear --login-program /usr/bin/tmux tty1 115200 linux' -- \
	hostname mount-dev
longrunning tty2 'agetty -L --noclear --login-program /usr/bin/ly tty2 115200 linux' -- \
	hostname mount-dev
longrunning tty3 'agetty -L --noclear --login-program /usr/bin/tmux tty3 115200 linux' -- \
	hostname mount-dev

longrunning dhcpcd 'dhcpcd --nobackground' -- \
	corenet hostname
longrunning cronie 'crond -n' -- \
	early-filesystems

oneshot files 'mount -a' -- \
	mount-dev early-filesystems mount-efivars


group="exposed"
oneshot wireguard 'wg-quick up wg0' -- \
	corenet files
longrunning tor 'tor' -- \
	corenet files
longrunning sshd 'sshd -D' -- \
	corenet files
longrunning dns-server 'named' -- \
	corenet files
longrunning nginx 'nginx -g "daemon off;"' -- \
	corenet files

group="desktop"
oneshot machine-uuid 'dbus-uuidgen --ensure=/etc/machine-id' -- \
	hostname localhost files
longrunning dbus 'foreground { install -m755 -o messagebus -g messagebus -d /run/dbus }' 'dbus-daemon --system --nofork --nopidfile --print-pid=3' -- \
	machine-uuid hostname localhost files
longrunning polkit '/usr/lib/polkit-1/polkitd' -- \
	hostname localhost files dbus

# why do i have both running lmao
longrunning seatd 'seatd -g video'
longrunning logind '/lib64/elogind/elogind'

# create_service pipewire 'pipewire'

group="users"
# longrunning mazunki 's6-usertree'
# longrunning "games" "/path/to/games-command"
#
