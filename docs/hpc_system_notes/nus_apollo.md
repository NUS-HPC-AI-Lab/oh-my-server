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
