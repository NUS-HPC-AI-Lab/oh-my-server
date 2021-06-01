# NSCC AI System

## Table Of Contents

- [Common Commands](#common-commands)
- [Scheduler](#scheduler)
- [Job Status Email Alert](#job-status-email-alert)
- [Jupyter Lab](#jupyter-lab)
- [Horovod](#horovod)
- [Container](#container)
- [Python Package Management](#python-package-management)
- [Multinode Experiments](#multinode-experiments)
- [Dataset](#dataset)

## Common Commands

```shell
# submit interactive job
qsub -I -q dgx-dev -l walltime=3:00:00 -P <PROJECT_ID>

# submit a job script
qsub /PATH/TO/job.pbs

# check your job status
qstat

# view job info
qstat -f 2603175.wlm01

# delete your job
qdel 2603175.wlm01

# view job queue
gstat -dgx

# run interactive containers
nscc-docker run -t nvcr.io/nvidia/pytorch
singularity run pytorch\:latest.sif

# run container with executable
nscc-docker run nvcr.io/nvidia/pytorch <PATH_TO_EXECUTABLE>
singularity run pytorch\:latest.sif <PATH_TO_EXECUTABLE>

```

> Some default options are added automatically for nscc-docker run
>
> > -u UID:GID --group-add GROUP –v /home:/home –v /raid:/raid -v /scratch:/scratch --rm –i --ulimit memlock=-1 --ulimit stack=67108864
> >
> > If --ipc=host is not specified then the following option is also added: --shm-size=1g

## Scheduler

NSCC uses PBS Pro as the job scheduler, you can refer to the
[NSCC official guide](https://help.nscc.sg/pbspro-quickstartguide/) for detailed instructions.

## Job Status Email Alert

To receive notification when your job status changes, you can add the following to your PBS job script.

```shell
#PBS -M username@x.y.z
```

## Jupyter Lab

If you want to debug your code or run many short experiments with exclusive GPU resources, you can launch a jupyter lab
on the NSCC server. The procedure is as follows:


<p align="center">
  <img src="https://github.com/FrankLeeeee/oh-my-server/blob/main/figures/NSCC/NSCC_jupyter.png?raw=true" width="60%" alt="jupyter workflow">
</p>

1. Setup NSCC VPN for your [Mac](https://help.nscc.sg/vpnmac/) or [Windows](https://help.nscc.sg/vpnmicrosoft/). You
   should not login via the school VPN as they do not provide outgoing internet access. The NSCC VPN allows you to
   access NSCC server from `aspire.nscc.sg`. You can send data to outside machine with this IP but not
   with `ntu.nscc.sg` or
   `nus.nscc.sg`. This ensures that you can access jupyter lab from your local machine later.

2. Log in to your nscc account by
   ```shell
   ssh <USERNAME>@aspire.nscc.sg
   ```

3. Submit a jupyter job. There are two ways to start the Jupyter Lab. There are two ways to start the jupyter lab.
    - The first way is to start Jupyter Lab in a container
      (You can refer to the [official guide](https://help.nscc.sg/wp-content/uploads/AI_System_QuickStart.pdf)
      for how to write this kind of script).
    - The second way is to start Jupyter Lab only and run containers in Jupyter Lab. You can refer
      to [my script](https://github.com/FrankLeeeee/oh-my-server/tree/main/scripts/nscc/multi_node/pbs_script).

   The second way is highly recommended because you can access both your base environment in the compute node and the
   environment in containers and you can run containers with different images. For example, if you choose a wrong
   container via the first method, you have to quit the job and re-submit but this is not necessary for the second
   method.

4. Once your job is running, you need to check which host on which jupyter is running by:
   ```shell
   qstat -f <JOB_ID>
   ```

   You can also check the job output file and get the port on which your jupyter is running.

5. Then, you can connect to your jupyter lab via port forwarding. The command is like
   ```shell
   ssh -L <LOCAL_PORT>:<NSCC_HOST>:<NSCC_PORT> <USERNAME>@aspire.nscc.sg
   
   # example
   ssh -L 8888:dgx4106:8888 u12345@aspire.nscc.sg
   ```
   The `NSCC_HOST`  and `NSCC_PORT` are found in step 4. `LOCAL_PORT` can be any port.

6. Finally, open your browser and enter `localhost:<LOCAL_PORT>` to access the remote jupyter lab.

## Horovod

---

**UPDATE: You can try this new Singularity
image `/home/projects/ai/singularity/nscc/horovod_0.20.0-tf2.3.0-torch1.6.0-mxnet1.6.0.post0-py3.7-cuda10.1.sif` which
has Horovod pre-installed now**

---

If you are using TensorFlow, you can use docker/singularity image directly as Horovod is pre-installed.

If you are using PyTorch, you need to install horovod manually. To install Horovod on NSCC, just run the following
script in the container. I used Singularity as it is more sutiable for multinode training.

```shell
#!/bin/bash

export HOROVOD_NCCL_INCLUDE_=/usr/include
export HOROVOD_NCCL_LIB=/usr/lib/x86_64-linux-gnu
export HOROVOD_NCCL_LINK=SHARED

export HOROVOD_GPU_ALLREDUCE=NCCL
export HOROVOD_WITH_PYTORCH=1
pip install --no-cache-dir --user  horovod==0.18.2
```

## Container

NSCC provides both Singularity and Docker containers. The containers used mostly are NGC contianers. The Singularity
ones are obtained by converting Docker image to Singularity image. Some points that I have observed are that:

1. You do not have root access in both Docker and Singularity container.
2. `singularity shell xxx.sif` behaves interestingly different from `singularity run xxx.sif`. Even though both will
   start bash as the default shell, `singularity shell` does not source your bashrc file while `singularity run`
   actually does. So your init script in bashrc will be omitted when you execute `singularity shell`. It is desgined to
   be so and look at https://github.com/hpcng/singularity/issues/643 for more info.

## Python Package Management

It is sometimes possible that the container does not provide the Python libraries you need. In this case, you need to be
careful in managing these libraries.

You can install your library to your user directory by:

```shell
pip install --user <LIBRARY>
```

This should install Python library to `~/.local/lib` of your home directory.

You can also check the directories where Python searches for libraries during `import` by running

```shell
python -m site
```

If you container Python does not source your Python package, you can perform one of the following methods to add these
libraries to PYTHONPATH.

- export PYTHONPATH=<LIBRARY_ROOT_PATH>:$PYTHONPATH
- add `sys.path.insert(0, <LIBRARY_ROOT_PATH>)` in your python file For example, the `LIBRARY_ROOT_PATH` can
  be `/home/users/ntu/c170166/.local/lib/python3.6/site-packages`.

If you are not sure where a specific library is imported from when you run your script, you can check like below:

```python
# take pytorch as an example
import torch

print(torch.__file__)
```

## Multinode Experiments

First of all, it takes a long time to queue for resources on NSCC. It is normal to wait for a few days if you request
for 2 nodes with 4 GPUs each. At the initial debugging stage, it is definitely crazy if you submit a job script again
and again. Thus, I would highly recommend you to debug using the Jupyter Lab as mentioned above.

To run experiments on multinode on NSCC, you need to follow these steps.

```
# Use OMPI integrated with PBS
export PATH=/home/app/dgx/openmpi-3.1.3-gnu/bin:$PATH

# run the script in container
mpirun --mca btl_openib_warn_default_gid_prefix 0 \
--host dgx4106:1,dgx4105:1 -N 1 --np 2 \
/opt/singularity/bin/singularity exec --nv  \
/home/project/ai/singularity/nvcr.io/nvidia/pytorch\:latest.sif \
python <YOUR_SCRIPT>
```

For PyTorch users, you can use `horovod` for cross-node communication. However, if you are using `torch.distributed`,
you need to specify the communication interface by `export NCCL_SOCKET_IFNAME=enp1s0f1` or
add `os.environ['NCCL_SOCKET_IFNAME'] = 'enp1s0f1'` in your Python file. If you are using `gloo` backend, the
environment variable will be `GLOO_SOCKET_IFNAME`. This is to force PyTorch use InfiniBand for communication. Otherwise,
the program will be stuck at initialization based on my test.

## Dataset and Transfer files

The ImageNet dataset is placed at `/scratch/users/nus/e0575577/ImageNet` if you are using the shared account.

Maybe you can find other prepared dataset around this path.

**Transfer files**

You can use scp or git clone command, FileZilla or WinSCP, a visible tool, to transfer files.

```shell
# scp command
# tested in Git Bash on Windows10
scp G:/globus_share/xxx.tar your_account@aspire.nscc.sg:/your_path/imagenet-tar
```

