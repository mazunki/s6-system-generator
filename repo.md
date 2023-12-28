s6-svscan
├── s6-supervise (runtime-tree)
│   ├── mount-dev
│   ├── mount-proc
│   ├── mount-sys
│   ├── mount-tmpfs
│   └── mount-cgroups
├── s6-supervise (core-tree)
│   ├── devices
│   ├── corenet
│   ├── tty
│   ├── dhcpcd
│   ├── cronie
│   └── essential-system-services
├── s6-supervise (outside-tree)
│   ├── wireguard
│   ├── tor
│   ├── sshd
│   ├── dns-server
│   └── nginx
├── s6-supervise (desktop-tree)
│   ├── dbus
│   ├── polkit
│   ├── pipewire (planned)
│   └── ly
├── s6-supervise (users-tree)
│   ├── mazunki
│   └── games
└── s6-supervise (logger-tree)
    ├── runtime-logger
    ├── core-logger
    ├── service-logger
    ├── desktop-logger
    └── users-logger
