# NUS Apollo

## Table of Contents

- [Connecting](#connecting)
- [Software Stack](software-stack)
- [Hardware Overview](#hardware-overview)

## Connecting

Connect to SoC VPN then you can use ssh to connect to the lab machine directly.

```shell
ssh USERNAME@hpc-ai-01.d2.comp.nus.edu.sg
```

## :heavy_exclamation_mark: Download Rules

:heavy_exclamation_mark:
:heavy_exclamation_mark:
:heavy_exclamation_mark:
**Please read this section before use**


If you want to download a large dataset, please limit your download rate so that it will not perform DDOS to the network. 
You can use trickle to specify how fast you download your dataset. In general, you should limit your download rate to 10 MB/s to play safe. 
We use **`trickle`** to control the download rate.

Some options of trickle are: 
- `-s`: run in standalone mode 
- `-u`: upload rate in KB/s 
- `-d`: download rate in KB/s 


```bash
# this will download CIFAR10 dataset at around 4 MB/s
trickle -s  -u 1024 -d 4096 wget https://www.cs.toronto.edu/~kriz/cifar-10-python.tar.gz

# this will download CIFAR10 dataset at around 2 MB/s
trickle -s  -u 1024 -d 2048 wget https://www.cs.toronto.edu/~kriz/cifar-10-python.tar.gz
```

## Software Stack

### Environment Module

We use **Environment Module** to manage the software stack.
You can use `module av` to list the available software package and use `module load` to load the software you want to use.

```shell
module load miniconda3 cuda/11.3.1
```

### Singularity Image

You can use singularity to run container. 

1. Run Image: `singularity shell --nv`
2. Clone Environment: `conda create --clone`
3. Install Other Python Dependency with `pip` or `conda`

New environment will create under `$HOME/.conda/envs`. Then activate the environment again without reconfiguring the environment, use it directly after source. 

```shell
$ module load singularity
$ singularity shell --nv /opt/nussif/pytorch_21.12-py3.sif
Singularity> conda create --clone base --name ngc-torch-21.11 # only need when first time 
Singularity> source activate ngc-torch-21.11
Singularity> python -c "import torch;print(torch.cuda.is_available())"
```

## Hardware Overview

| Node Name | GPU                    | CPU                        | Memory              | Storage                            |
|-----------|------------------------|----------------------------|---------------------|------------------------------------|
| hpc-ai-01 | NVIDIA  HGX A100 8-GPU | 2 x  AMD EPYC 7742 64-Core | 1TB  3200 MT/s DDR4 | 1.8 TB System NVME 11 TB Dada NVME |
