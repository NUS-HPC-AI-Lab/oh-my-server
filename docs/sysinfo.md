# Understanding Your System

## Table Of Contents

- [Common Linux Commands](#common-linux-commands)
- [More info in /proc](#more-info-in-/proc)
- [More info in /sys](#more-info-in-/sys)
- [Scripts](#scripts)

## Common Linux Commands

```shell
# get operating system info (any of the commands below)
cat /etc/os-release
lsb_release -a
hostnamectl

# get linux kernel version
uname -r

# get free RAM
free -m

# Disk
df -h /home

# CPU
lscpu

# GPU
nvidia-smi
nvcc --version

# environment variable
env

# check modules
module avai

# check infiniband (any of the commands below)
ibv_devinfo
ibstat
ibstatus

# check if hyperthreading is enabled
dmidecode -t processor | grep HTT

```

## More info in /proc

## More info in /sys

## Scripts

Author-Kit provides an easy-to-use script to gather system information on the machine.

```shell
git clone https://github.com/SC-Tech-Program/Author-Kit
bash ./Author-Kit/collect_environment.sh > ./sysinfo.txt
```
