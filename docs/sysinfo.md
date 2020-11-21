# Understanding Your System

## Common Linux Commands

```shell
# RAM
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

```

## Scripts

Author-Kit provides an easy-to-use script to gather system information on the machine.

```shell
git clone https://github.com/SC-Tech-Program/Author-Kit
bash ./Author-Kit/collect_environment.sh > ./sysinfo.txt
```
