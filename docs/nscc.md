# NSCC

## Jupyter Lab

If you want to debug your code or run many short experiments with exclusive GPU resources, you can launch a jupyter lab on the NSCC server. The procedure is as follows:

1. Setup NSCC VPN (For Mac user: https://help.nscc.sg/vpnmac/). NSCC VPN allows you to access NSCC server from `aspire.nscc.sg`. You can send data to outside machine with this IP but not with `ntu.nscc.sg` or `nus.nscc.sg`. This ensures that you can access jupyter lab from your local machine.
2. Log in to your nscc account by `ssh <username>@aspire.nscc.sg`
3. Submit a jupyter job. `qsub ~/jupyter.pbs`. You can refer to https://help.nscc.sg/wp-content/uploads/AI_System_QuickStart.pdf for how to write jupyter job script.
4. Once your job is running, you need to check the output file and get the host and port on which your jupyter is running. Then, you can connect to your jupyter lab via port forwarding. The command is like `ssh -L 8888:dgx4106:8888 aspire.nscc.sg`. You just need to chagne `dgx4106:8888` to the `<hostname>:<port>` as shown in your pbs output file.
5. Finally, open your browser and enter `localhost:8888` to access your jupyter lab.

**Jupyter Lab does not support multinode**

## Horovod

If you are using TensorFlow, you can use docker/singularity image directly as Horovod is pre-installed.

If you are using PyTorch, you need to install horovod manually. To install horovod on NSCC, you need to build NCCL first. (I didn't find the path to NCCL on NSCC, thus I decided to build on my own. Please tell me if you find the path to nccl). **I conducted all the steps below within the container `nscc-docker run -t nvcr.io/nvidia/pytorch:latest` as the python outside is of verison 2.7. You might be able to install outside container with conda but I never tested this method.**

```shell
cd <NEW_PATH_FOR_NCCL>
git clone https://github.com/NVIDIA/nccl.git
cd ./nccl
make src.build CUDA_HOME=/usr/local/cuda
```

Next, you need to install pytorch to your local directory. I did not test other versions of pytorch, but as long as you install with `--user` and the version is higher than the pre-installed pytorch version, it should be fine. (This is because horovod cannot be built with the pre-installed pytorch of the image for some unknown reason (perhaps permission error), so we need to have our own pytorch.)

```shell
pip install --user torch==1.7 torchvision==0.8
```

Next, you need to install horovod with the following script.

```shell
#!/bin/bash

export HOROVOD_NCCL_HOME=/home/users/ntu/c170166/local/nccl/nccl/build
export HOROVOD_GPU_ALLREDUCE=NCCL
export HOROVOD_WITH_PYTORCH=1
pip install --no-cache-dir --user horovod
```

I built and installed horovod in the docker container `nvcr.io/nvidia/pytorch:latest` and it will install horovod to `/home/users/ntu/c170166/.local/lib/python3.6/site-packages` and horovodrun bin is in `/home/users/ntu/c170166/.local/bin`. By running `horovodrun --check build`, you should see the installation is successful.

### IMPORTANT

The horovod and pytorch will remain even if you exit from the container as they are installed in the user's directory instead of container's site-package directory. Thus, you do not need to re-install when you start a new container. However, this might cause an issue if you use an image of different version. For example, you build horovod with a CUDA-10.2 but run horovod-based code on another CUDA-9 image and this might give you an error which I cannot foresee.
