# NSCC

## Horovod

If you are using TensorFlow, you can use docker/singularity image directly as Horovod is pre-installed.

If you are using PyTorch, you need to install horovod manually. To install horovod on NSCC, you need to build NCCL first. (I didn't find the path to NCCL on NSCC, thus I decided to build on my own. Please tell me if you find the path to nccl).

```shell
cd <NEW_PATH_FOR_NCCL>
git clone https://github.com/NVIDIA/nccl.git
cd ./nccl
make src.build CUDA_HOME=/usr/local/cuda
```

Next, you need to install horovod with the following script.

```shell
#!/bin/bash

export HOROVOD_NCCL_HOME=/home/users/ntu/c170166/local/nccl/nccl/build
export HOROVOD_GPU_ALLREDUCE=NCCL
export HOROVOD_WITH_PYTORCH=1
pip install --no-cache-dir horovod
```

I built and installed horovod in the docker container `nvcr.io/nvidia/pytorch:latest` and it will install horovod to `/home/users/ntu/c170166/.local/lib/python3.6/site-packages` and horovodrun bin is in `/home/users/ntu/c170166/.local/bin`. By running `horovodrun --check build`, you should see the installation is successful.
