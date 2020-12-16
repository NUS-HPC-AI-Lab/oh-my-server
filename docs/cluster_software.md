# Software for Cluster

## Table Of Contents

- [Ansible](#ansible)
- [BeeGFS](#beegfs)

## Ansible

Ansible is an IT automation tool. It can configure systems, deploy software, and orchestrate more advanced IT tasks such as continuous deployments or zero downtime rolling updates. Ansible does not require you to deploy on every node and it can access other nodes from master node via ssh and execute operations on other nodes automatically. For example, if you wish to install CUDA on your execute nodes, you can just write a simple Ansible playbook script and specify your execute nodes IPs. Then Ansible will access these execute nodes via ssh and install CUDA on each node as instructed in your script. This avoids the trouble of installing on each node manually.

> [Ansible Documentation](https://docs.ansible.com/ansible/latest/index.html)

## BeeGFS

BeeGFS is a distributed optimized parallel file system.

> [BeeGFS documentation](https://www.beegfs.io/c/)
