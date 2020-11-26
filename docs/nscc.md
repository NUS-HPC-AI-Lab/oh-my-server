# NSCC

## Table Of Contents

- [Common Commands](#common-commands)
- [Jupyter Lab](#jupyter-lab)
- [Horovod](#horovod)
- [Container](#container)
- [Python Package Management](#python-package-management)
- [Job Status Email Alert](#job-status-email-alert)
- [Multinode Experiments](#multinode-experiments)

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

## Jupyter Lab

If you want to debug your code or run many short experiments with exclusive GPU resources, you can launch a jupyter lab on the NSCC server. The procedure is as follows:

1. Setup NSCC VPN (For Mac user: https://help.nscc.sg/vpnmac/). NSCC VPN allows you to access NSCC server from `aspire.nscc.sg`. You can send data to outside machine with this IP but not with `ntu.nscc.sg` or `nus.nscc.sg`. This ensures that you can access jupyter lab from your local machine.
2. Log in to your nscc account by `ssh <username>@aspire.nscc.sg`
3. Submit a jupyter job. `qsub ~/jupyter.pbs`. You can refer to https://help.nscc.sg/wp-content/uploads/AI_System_QuickStart.pdf for how to write jupyter job script.
4. Once your job is running, you need to check the output file and get the host and port on which your jupyter is running. Then, you can connect to your jupyter lab via port forwarding. The command is like `ssh -L 8888:dgx4106:8888 aspire.nscc.sg`. You just need to chagne `dgx4106:8888` to the `<hostname>:<port>` as shown in your pbs output file.
5. Finally, open your browser and enter `localhost:8888` to access your jupyter lab.

## Horovod

If you are using TensorFlow, you can use docker/singularity image directly as Horovod is pre-installed.

If you are using PyTorch, you need to install horovod manually. To install Horovod on NSCC, just run the following script in the container. I used Singularity as it is more sutiable for multinode training.

```shell
#!/bin/bash

export HOROVOD_NCCL_INCLUDE_=/usr/include
export HOROVOD_NCCL_LIB=/usr/lib/x86_64-linux-gnu
export HOROVOD_NCCL_LINK=SHARED

export HOROVOD_GPU_ALLREDUCE=NCCL
export HOROVOD_WITH_PYTORCH=1
pip install --no-cache-dir --user  horovod==0.18.2
```

> **Deprecated**
>
> > To install horovod on NSCC, you need to build NCCL first. (I didn't find the path to NCCL on NSCC, thus I decided to build on my own. Please tell me if you find the path to nccl). **I conducted all the steps below within the container `nscc-docker run -t nvcr.io/nvidia/pytorch:latest` as the python outside is of verison 2.7. You might be able to install outside container with conda but I never tested this method.**
> >
> > ```shell
> > cd <NEW_PATH_FOR_NCCL>
> > git clone https://github.com/NVIDIA/nccl.git
> > cd ./nccl
> > make src.build CUDA_HOME=/usr/local/cuda
> > ```
> >
> > Next, you need to install pytorch to your local directory. I did not test other versions of pytorch, but as long as you install with `--user` and the version is higher than the pre-installed pytorch version, it should be fine. (This is because horovod cannot be built with the pre-installed pytorch of the image for some unknown reason (perhaps permission error), so we need to have our own pytorch.)
> >
> > ```shell
> > pip install --user torch==1.7 torchvision==0.8
> > ```
> >
> > Next, you need to install horovod with the following script.
> >
> > ```shell
> > #!/bin/bash
> >
> > export HOROVOD_NCCL_HOME=/home/users/ntu/c170166/local/nccl/nccl/build
> > export HOROVOD_GPU_ALLREDUCE=NCCL
> > export HOROVOD_WITH_PYTORCH=1
> > pip install --no-cache-dir --user horovod
> > ```
> >
> > I built and installed horovod in the docker container `nvcr.io/nvidia/pytorch:latest` and it will install horovod to `/home/users/ntu/c170166/.local/lib/python3.6/site-packages` and horovodrun bin is in `/home/users/ntu/c170166/.local/bin`. By running `horovodrun --check build`, you should see the installation is successful.
> >
> > #### IMPORTANT
> >
> > The horovod and pytorch will remain even if you exit from the container as they are installed in the user's directory instead of container's site-package directory. Thus, you do not need to re-install when you start a new container. However, this might cause an issue if you use an image of different version. For example, you build horovod with a CUDA-10.2 but run horovod-based code on another CUDA-9 image and this might give you an error which I cannot foresee.

## Container

NSCC provides both Singularity and Docker containers. The containers used mostly are NGC contianers. The Singularity ones are obtained by converting Docker image to Singularity image. Some points that I have observed are that:

1. You do not have root access in both Docker and Singularity container.
2. `singularity shell xxx.sif` behaves interestingly different from `singularity run xxx.sif`. Even though both will start bash as the default shell, `singularity shell` does not source your bashrc file while `singularity run` actually does. So your init script in bashrc will be omitted when you execute `singularity shell`. It is desgined to be so and look at https://github.com/hpcng/singularity/issues/643 for more info.

## Python Package Management

The container environment will use its own Python by default. However, you may need some extra libraries which are not provided in the container. For exmaple, you may need Horovod when you run with PyTorch container. You cannot install these libraries in the /opt/conda folder as it is read-only due to the lack of root access. You may have your libraries installed in the user default site-packages directory or your own Anaconda directory. You can go through the following steps to check if you have access to your own installed library in the container.

1. Run `python -m site`. You can see the directories where Python searches for libraries during `import` in the `sys.path`.
2. If you find that the directory where your libraries are installed are not in the `sys.path`, you can `export PYTHONPATH=<YOUR_PATH>:$PYTHONPATH`. For example, Horovod is installed in the `/home/users/ntu/c170166/.local/lib/python3.6/site-packages`, but for reason, Python cannot find Horovod during import. I can run `export PYTHONPATH=/home/users/ntu/c170166/.local/lib/python3.6/site-packages:$PYTHONPATH`. Now, you should be able to import Horovod as normal.

> You can also add `sys.path.insert(0, '/home/users/ntu/c170166/.local/lib/python3.6/site-packages')` in your python file instead of exporting the environment variable for step 2.

## Job Status Email Alert

It is tedious to constantly check whether your job has started running. I wrote a simple email alert script which will send an email to you once your sepcified job has started running. This is more suitable if you are running Jupyter. Follow the following steps to set up this simple alert system on your NSCC account.

1. Log in by `ssh <username>@nus.nscc.sg`
2. Change to NSCC nodes by `ssh nscc04-ib0`. This is becauase NTU and NUS nodes cannot send data to outside internet.
3. Clone `monitor.sh` and `nscc_monitor.py` from [monitor_job](https://github.com/FrankLeeeee/oh-my-server/blob/main/scripts/nscc/monitor_job) to your home directory
4. Edit the `FROM_ADDR` and `PASSWORD` in `nscc_monitor.py` with your email account and STMP authorization key.
5. Change the path to Anaconda and `nscc_monitor.py` in `monitor.sh`
6. Run `nohup bash ./monitor.sh <JOB_ID> <RECEIVER_EMAIL> <INTERVAL> > ./nohup.log 2>&1 &`

The `nohup` command will run in the background even if you exit from your terminal. This will produce two output files, one is `nohup.log` and `monitor_<job_id>.log`. `monitor_<job_id>.log` will show you the status of the script. `<INTERVAL>` is set to be 600 by default which means it will check the status of the job every 10 min.

This script will run with Python 3.8. If you have lower Python3 version, you might have issue with the server setup in the `nscc_monitor.py`, but it is simply syntax error which be solved by google easily (`smtplib` updates some API from Python 3.7 onwards)

## Multinode Experiments

I would suggest to run Jupyter Lab instead of direct execution of your script as it takes a long time to queue for multinode resources and it is difficult to debug. To run experiments on multinode on NSCC, you need to follow these steps.

```
# Use OMPI integrated with PBS
PATH="/home/app/dgx/openmpi-3.1.3-gnu/bin:$PATH" ; export PATH

# run the script in container
mpirun --mca btl_openib_warn_default_gid_prefix 0 \
--host dgx4106:1,dgx4105:1 -N 1 --np 2 \
/opt/singularity/bin/singularity exec --nv  \
/home/project/ai/singularity/nvcr.io/nvidia/pytorch\:latest.sif \
python /home/users/ntu/c170166/scratch/projects/dl-auto-load-balance/auto-ml-load-balance/scripts/nscc/jupyter/mpi_testing/comm_with_hvd.py
```

**This only works with `hvd.init()`, `torch.distributed.init_process_group` will cause timeout for unknown reason. Thus, you need to replace all collective communication operations with horovod if you are using `torch.distributed package`**

> **Depreated**
>
> > **Even though the scripts contain `tensorflow` in the file name, but it is set to be for PyTorch experiments indeed.**
> >
> > 1.  Set up your Jupyter Lab which can access the execute nodes via ssh. A sample PBS script is given in [Jupyter Multinode on NSCC](https://github.com/FrankLeeeee/oh-my-server/tree/main/scripts/nscc/multi_node/pbs_script)
> >
> > 2.  After obtaining the resources, refer to [Jupyter Lab](#jupyter-lab) on how to set up the Jupyter Lab on your localhost.
> >
> > 3.  Clone the scripts in [Multinode Experiments](https://github.com/FrankLeeeee/oh-my-server/tree/main/scripts/nscc/multi_node/experiments). Put `scripts` and `apps` in the `$HOME` directory and make a temporary ssh directory.
> >
> > ```
> > cp -r  scripts $HOME/
> > cp -r  apps $HOME/
> > mkdir $HOME/sshcont
> > ```
> >
> > 4.  Edit the `RUN_SCRIPT` in the file `$HOME/scripts/sshcont/job_tensorflow_gloo.sh`. For demo purpose, you can just let it point to the `test_mpi.sh` given in the `test` folder and just make sure the path is correct.
> >
> > ```shell
> > # change the script directory to yours
> > # Edit this
> > RUN_SCRIPT=/home/users/ntu/c170166/scratch/projects/dl-auto-load-balance/>> auto-ml-load-balance/scripts/nscc/jupyter/mpi_testing/test_mpi.sh
> > ```
> >
> > 5.  Run `bash $HOME/scripts/sshcont/invocation` to start multinode experiments. If you run the `test_mpi.sh` file given, you should expect to see something like
> >
> > ```shell
> > rank: 0, world size: 2, hostname: dgx4106
> > rank: 1, world size: 2, hostname: dgx4105
> > trying to initliaze dist
> > init successful on hostname: dgx4106
> > init successful on hostname: dgx4105
> > ```
> >
> > #### IMPORTANT
> >
> > It seems that it only works with scripts which use horovod so do add `hvd.init()` in your python script. This is a work-around method as I couldn't run the example given by NSCC successfully.
