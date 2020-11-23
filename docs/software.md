# Frequently-Used Software

## Tmux

Install tmux

```shell
sudo yum install tmux
```

tmux cheatsheet: https://tmuxcheatsheet.com/

## Lmod

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
