# Understanding Your System

## Table Of Contents

- [Common Linux Commands](#common-linux-commands)
- [More info in /proc](#more-info-in-proc)
- [More info in /sys](#more-info-in-sys)
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

## More info in proc

`/proc` is a virtual file system on Linux which stores the information about the current status of the linux kernel. Users can view and modify the running status of the kernel with these files. As '/proc' is virtual, the files in `/proc` are 0KB even though they can display lots of information. Many of them are stored in RAM and constantly updated.

If you change your directory to `/proc`, you can actually see a lot of folders named with numbers. These are folders of the running processes. The following commands will give you some basic information about the process and you can definitely get more if you view other files.

```shell
# see the command which launches the process
cat cmdline

# check the environment variables of the process
cat environ

# check the memory usage
cat mem

# view the current status of the process
# cat status has better readability
cat stat
cat status

# check the info about threads run by the current process
cat task

```

Besides the process folders, there are many files directly located under `/proc`, they provide the status information of the whole operating system. For example:

```shell
# check power management and battery info
cat /proc/apm

# get memory usage
cat /proc/meminfo

# get virtual memory info
cat /proc/vmstat

# get mounted devices info
cat /proc/devices

# get cpu info
/proc/cpuinfo

# get system running time since last up
cat /proc/uptime

# get kernel version
cat /proc/version

```

## More info in sys

`/sys` is another directory which allows to view information about your devices and system. You can view and modify some settings such power, module, hypervisor, etc.

> You can view/chagne simultaneous multi-threading in `/sys/devices/system/cpu/smt`

## Scripts

Author-Kit provides an easy-to-use script to gather system information on the machine.

```shell
git clone https://github.com/SC-Tech-Program/Author-Kit
bash ./Author-Kit/collect_environment.sh > ./sysinfo.txt
```
