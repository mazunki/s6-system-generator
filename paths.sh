#!/bin/sh
set -ue

# here's where it's all declared
S6_SERVICE_DECLARATIONS="${HERE}"/services.sh

# services correspond to individual processes/execline scripts, while tree
# bundles corresponded to the named supervise trees
# (check repo.md to visualize the general idea)
# 
# both of these directories are written during the generation of our services,
# and are read by ./s6-recompile-init later
#
S6_SERVICE_HOME="${HERE}/services"  # services
S6_BUNDLE_HOME="${HERE}/bundles"  # supervision trees

S6_COMPILE_HOME="/var/lib/s6/compiled"  # destination directory of ./s6-recompile-init, comprising a runnable service set
S6_ACTIVE_COMPILED="/var/lib/s6/active"  # a symlink pointing to the desired service set to be run by scripts/rc.init

S6_INIT_BASEDIR="/var/lib/s6/s6-linux-init/current"  # destination of s6-linux-init-maker, which is loaded at boot time
S6_LOG_USER="s6log"  # who will own the log files, and thus which groups will be able to read the logs

S6_LINUX_INIT="/var/lib/s6/s6-linux-init"  # where we place scripts for the init


