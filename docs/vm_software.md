# Software for Single VM

I use CentOS for my personal cloud server, thus the commands will be a bit difference if you using other operating system. For software you wish to make available for all users, I would recommend you to put them under `/opt/apps`. As I will be using `Lmod` to manage all the modules, I build all the software from source. If you wish to install directly, you can just use `yum install`.

## Table Of Contents

- [GCC](#gcc)
- [Tmux](#common-linux-commands)
- [Lmod](#lmod)
- [Docker](#docker)
- [Singularity](#singularity)
- [OpenMPI](#openmpi)
- [Useful Plug-ins](#useful-plug-ins)

## GCC

GCC compiler is required for compilation for many programs. To build GCC from source, you can follow the steps below.

```shell
# setup workspace
cd /opt/apps
mkdir -p gcc/source
cd ./gcc/source

# setup source code
git clone git://gcc.gnu.org/git/gcc.git
git branch -a # view all branch
git tag -l  # view all tags
git checkout <BRANCH_OR_TAG>
./contrib/download_prerequisites

# make and install
cd /opt/apps/gcc
mkdir <VERSION> # e.g. mkdir 8.3.0
/opt/apps/gcc/source/configure --prefix=/opt/apps/gcc/<VERSION> --enable-languages=c,c++,fortran,go
make
make install
```

**Compilation can take quite long**

## Tmux

Install tmux

```shell
sudo yum install tmux
```

However, this is version 1.8 and is a bit too old. To install Tmux 2.8 from source:

```shell
# install deps
yum install gcc kernel-devel make ncurses-devel

# DOWNLOAD SOURCES FOR LIBEVENT AND MAKE AND INSTALL
curl -LOk https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz
tar -xf libevent-2.1.8-stable.tar.gz
cd libevent-2.1.8-stable
./configure --prefix=/usr/local
make
make install

# DOWNLOAD SOURCES FOR TMUX AND MAKE AND INSTALL

curl -LOk https://github.com/tmux/tmux/releases/download/2.8/tmux-2.8.tar.gz
tar -xf tmux-2.8.tar.gz
cd tmux-2.8
LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local
make
make install

# pkill tmux
# close your terminal window (flushes cached tmux executable)
# open new shell and check tmux version
tmux -V
```

tmux cheatsheet: https://tmuxcheatsheet.com/

## Lmod

You may refer to [Lmod Installation](https://lmod.readthedocs.io/en/latest/030_installing.html) for detailed instructions. For a quick summary on the installation process, you can refer to my procedure.

1. Try `lua -v` to check if you have lua installed. If not, install lua.

```shell
curl -R -O http://www.lua.org/ftp/lua-5.4.1.tar.gz
tar xf lua-5.4.1.tar.gz
cd lua-5.4.1
# if you want to set where you want to install
# e.g. change INSTALL_TOP to /opt/apps/lua/5.4.1
# and lua will be installed there
vim Makefile
make
make install
```

2. Download Lmod from [here](https://sourceforge.net/projects/lmod/files/) and install (e.g. Lmod-8.4).

```shell
tar -xf Lmod-8.4.tar.bz2
cd Lmod-8.4
./configure --prefix=/opt/apps
make install
```

3. Then Configure the shell setup.

```
ln -s /opt/apps/lmod/lmod/init/profile        /etc/profile.d/z00_lmod.sh
ln -s /opt/apps/lmod/lmod/init/cshrc          /etc/profile.d/z00_lmod.csh
ln -s /opt/apps/lmod/lmod/init/profile.fish   /etc/fish/conf.d/z00_lmod.fish
```

4. When you start you shell again, you can type `module` and see the option list and see some environment variables such as `LMOD_CMD`.

```
$ echo $LMOD_CMD
/opt/apps/lmod/lmod/libexec/lmod
```

You can refer to [Write your own modulefiles](https://lmod.readthedocs.io/en/latest/020_advanced.html) for more information. You can add `module use <MODULEFILES_PATH>` in `/etc/profile` so all users can initialize to the same bunch of paths upon start.

## Docker

Install Docker

```shell
sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo systemctl start docker
```

Docker will create a group called docker, other users can be granted access to docker by

```shell
sudo usermod -aG docker $USER
```

docker cheatsheet: https://www.docker.com/sites/default/files/d8/2019-09/docker-cheat-sheet.pdf

## Singularity

Singularity is a containerization tool similar to Docker. It is more for HPC community. Its image can be obtained by conversion from Docker Image. Follow the steps below to install Singularity.

```shell
sudo yum update && \
    sudo yum groupinstall 'Development Tools' && \
    sudo yum install libarchive-devel

git clone https://github.com/singularityware/singularity.git
cd singularity
./autogen.sh
./configure --prefix=/opt/apps/singularity --sysconfdir=/etc
make
sudo make install

```

## OpenMPI

OpenMPI lets you spawn mutltiple processes simultaneously for distributed job. As my VM has too few cores to make OpenMPI effective. I didn't not install it.

## Useful Plug-ins

[oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)  
[oh-my-tmux](https://github.com/gpakosz/.tmux)
[vimrc-configuration](https://github.com/amix/vimrc)
