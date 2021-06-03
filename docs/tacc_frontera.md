# TACC-Frontera

- [Build Virtualenv Environment ](#build-virtualenv-environment )
- [Common Commands](#common-commands)
- [Job Script Example](#job-script-example)
- [Horovod Gloo](#horovod_gloo)
- [Dataset and Transfer files](#dataset-and-transfer-files)
- [Large Scale Experiment](#large-scale-experiment)
- [DALI](#dali)
- [Potential Error](#potential-error)
- [Question Ticket](#question-ticket)
## Build Virtualenv Environment 

According to the TACC staff's personal instruction, we should **use Python virtualenv instead of Conda** to build the environment on TACC-Frontera. 

```shell
# interactive usage
idev -p rtx-dev -N 1 -n 4 -t 02:00:00

# bulid Python virtualenv
cd ~
mkdir python-env
cd python-env
# you can use other names
virtualenv cuda10-home

# active environment
source ~/python-env/cuda10-home/bin/activate

# deactivate environment
deactivate　

# you can use pip to install packages
```

Build Horovod with Pytorch. 

```shell
# login in computing nodes and virtualenv 
idev -p rtx-dev -N 1 -n 4 -t 02:00:00

# load modules (cannot use default intel/19 impi/19)
module load intel/18.0.5 impi/18.0.5
module load cuda/10.1 cudnn nccl

source ~/python-env/cuda10-home/bin/activate

# install Pytorch, example 1.5.1
pip install torch==1.5.1+cu101 torchvision==0.6.1+cu101 -f https://download.pytorch.org/whl/torch_stable.html --force-reinstall

# bulid Horovod, maybe spend ten minutes 
HOROVOD_CUDA_HOME=$TACC_CUDA_DIR HOROVOD_NCCL_HOME=$TACC_NCCL_DIR  CC=gcc HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_GPU_BROADCAST=NCCL HOROVOD_WITHOUT_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 HOROVOD_WITHOUT_MXNET=1 pip install horovod --no-cache-dir --force-reinstall
```

**Default PyTorch dataloader does not work if you use Horovod for distribution directly** (maybe because the specific MPI), please **use torch.distributed, Horovod Gloo, or Horovod + DALI** (please refer to DALI or Horovod Gloo section).

## Common Commands

```shell
# To directory $SCRATCH. The default directory is $HOME when you login in.
cd $SCRATCH

# interactive usage
idev -p rtx-dev -N 1 -n 4 -t 02:00:00

# submit a job script
sbatch /PATH/TO/job.slurm

# check your job status
squeue -u your_account

# view requested nodes ID 
squeue | grep your_account

# view nodes local file space 
ssh c196-032 df

# delete your job
scancel job_ID

# display estimated start time for job
squeue --start -j job_ID

# view loaded module
# module related commands need at computing node
module list

# view avail module
module avail

# active your environment and load cuda components
# you need run it after you login in computing nodes everytime
source ~/python-env/cuda10-home/bin/activate
module load cuda/10.1 cudnn nccl
# module load cuda/10.0 cudnn nccl
# module load cuda/11.0 cudnn/8.0.5 nccl/2.8.3

# run your code, n is the number of total GPUs
ibrun -np 4 python pytorch_imagenet_resnet.py
```

For more detailed information, please refer to [TACC Frontera User Guide](https://frontera-portal.tacc.utexas.edu/user-guide/quickstart/).

## Job Script Example

```
#!/bin/sh

#SBATCH -J myjob           # Job name
#SBATCH -o myjob.o%j       # Name of stdout output file
#SBATCH -e myjob.e%j       # Name of stderr error file
#SBATCH -p rtx            # Queue (partition) name
#SBATCH -N 2               # Total # of nodes (must be 1 for serial)
#SBATCH -n 8               # Total # of mpi tasks (should be 1 for serial)
#SBATCH -t 00:30:00        # Run time (hh:mm:ss)
#SBATCH --mail-user=your email address
#SBATCH --mail-type=all    # Send email at begin and end of job

pwd
date

cd your_code_path

source ~/python-env/cuda10-home/bin/activate
module load intel/18.0.5 impi/18.0.5
module load cuda/10.1 cudnn nccl

ibrun -np 8 \
python your_code.py
```

You should use ibrun instead of mpirun or mpiexec here, and -np means total GPU numbers.

Note: Although in Frontera tutorial, they use "#SBATCH -A myproject       # Allocation name", you can actually delete it. If you incorrect set it, you will meet permission error when submit job.

From 6 April 2021, for Frontera jobs, a new queue named *small* has been created specifically for one and two node jobs. Jobs of one or two nodes that will run for up to 48 hours should be submitted to the *small* queue. The *normal* queue now has a lower limit of 3 nodes for all jobs. This should improve the turnaround time for jobs in the *normal* queue and small jobs in the *small* queue.

## Horovod Gloo

```
#!/bin/sh

#SBATCH -J myjob           # Job name
#SBATCH -o myjob-t.o%j       # Name of stdout output file
#SBATCH -e myjob-t.e%j       # Name of stderr error file
#SBATCH -p rtx            # Queue (partition) name
#SBATCH -N 2               # Total # of nodes (must be 1 for serial)
#SBATCH -n 8               # Total # of mpi tasks (should be 1 for serial)
#SBATCH -t 00:30:00        # Run time (hh:mm:ss)

pwd
date

source ~/python-env/cuda10-home/bin/activate

module load intel/18.0.5 impi/18.0.5
module load cuda/10.1 cudnn nccl

cd /file_path/

export PMI_NO_PREINITIALIZE=1  # avoid warnings on fork
# unset CSCS_CUSTOM_ENV PELOCAL_PRGENV PROFILEREAD RCLOCAL_PRGENV RCLOCAL_BASEOPTS

# 4 means $SLURM_NTASKS_PER_NODE
for node in $(scontrol show hostnames); do
   HOSTS="$HOSTS$node:4,"
done
HOSTS=${HOSTS%?}  # trim trailing comma
echo HOSTS $HOSTS

horovodrun -np $SLURM_NTASKS -H $HOSTS --gloo --network-interface ib0 \
   --start-timeout 120 --gloo-timeout-seconds 120 \
python you_file.py  \
--epochs 90 \
--model resnet50
```

Horovod Gloo works without using MPI, so you can use default PyTorch dataloader as on other clusters.

## Dataset and Transfer files

**Dataset**

```shell
cp /scratch1/00946/zzhang/imagenet/imagenet-1k.tar /your/path
tar xf imagenet-1k.tar

--train-dir=/your/path/ILSVRC2012_img_train/
--val-dir=/your/path/ILSVRC2012_img_val/
```

You can get a prepared ImageNet-1K (ILSVRC2012) use above command.

Maybe you can find other prepared dataset around this path.

**Transfer files**

You can use scp or git clone command, or WinSCP, a visible tool can input TACC token, to transfer files.

```shell
# scp command
# tested in Git Bash on Windows10
scp G:/globus_share/xxx.tar your_account@frontera.tacc.utexas.edu:/your_path/imagenet-tar
```

## Large Scale Experiment

(You can also consider DALI rather than this part)

If a job uses many nodes (eg. 32 nodes with 128 GPUs) and reads large dataset(eg. ImageNet) directly from the hard disk, it will cause huge IO pressure on the file system, which may cause the job to be killed by the system : (

Different with TACC-Longhorn, which can directly use /tmp for ImageNet. The /tmp file system on TACC-Frontera is only around 100G and cannot copy and extract the whole ImageNet.

Since we can only use max 16 nodes with 64 GPUs, so maybe it is still OK to read data from $SCRATCH, which is the simplest way. The following method is pretty tricky and only works for ImageNet. 

According to the TACC staff's personal instruction, there is a method called fanstore, which can load the preprocessed ImageNet directly to /tmp file system. 

Preprocessed ImageNet

```shell
# copy preprocessed ImageNet-1K (ILSVRC2012), which is a binary file folder.
cp /scratch1/00946/zzhang/imagenet/imagenet-16parts /your/path

# imagenet-tiny, same structure of ImageNet-1K (ILSVRC2012), but size is much smaller
cp /scratch1/00946/zzhang/imagenet/imagenet-tiny-16parts /your/path
```

Job Script Example

```shell
source ~/python-env/cuda10-home/bin/activate
# load data
# In interactive usage, do not need & sleep 500, when you see Ready in command, press ctrl+z, input bg 1
# Sometimes, it maybe get stuck:(
export FS_ROOT=/tmp/fs_`id -u`
ibrun -np 2 /work/00410/huang/share/read_remote_file 16 /scratch1/07801/nusbin20/imagenet-16parts & sleep 500

# load module 
module load cuda/10.1 cudnn nccl

cd /scratch1/07801/nusbin20/tacc-our

# read_remote_file and wrapper.so are provided by the TACC staff, they are binary files, so I also don't know the detail :(
ibrun -np 8 LD_PRELOAD=/work/00410/huang/share/wrapper.so python pytorch_imagenet_resnet.py  --epochs 90 --model resnet50 --batch-size 128 --train-dir=/tmp/fs_871009/ILSVRC2012_img_train --val-dir=/tmp/fs_871009/ILSVRC2012_img_val 

```

You need use id -u, to find your user ID, and change above 871009 to it. 

## DALI

NVIDIA DALI can accelerate data loading and pre-processing using GPU rather than CPU, although with GPU memory tradeoff. 

It can also avoid some potential conflicts between MPI libraries and Horovod on some GPU clusters.  

On TACC-Frontera, DALI only works for one node with 4GPUs, if use Pytorch + Horovod, I guess because its specific MPI : ( . When use mutil nodes, it still doesn't work.

**Install**

Build DALI with Pytorch, Horovod and CUDA 11.0. 

```shell
# login in computing nodes and virtualenv 
idev -p rtx-dev -N 1 -n 4 -t 02:00:00

source ~/python-env/cuda110-home/bin/activate

# load modules (cannot use default intel/19 impi/19)
module load intel/18.0.5 impi/18.0.5
module load cuda/11.0 cudnn nccl


# install Pytorch, example 1.7.1
pip install torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio==0.7.2 -f https://download.pytorch.org/whl/torch_stable.html --force-reinstall

# bulid Horovod, maybe spend ten minutes 
HOROVOD_CUDA_HOME=$TACC_CUDA_DIR HOROVOD_NCCL_HOME=$TACC_NCCL_DIR  CC=gcc HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_GPU_BROADCAST=NCCL HOROVOD_WITHOUT_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 HOROVOD_WITHOUT_MXNET=1 pip install horovod --no-cache-dir --force-reinstall

# install dali
pip install --extra-index-url https://developer.download.nvidia.com/compute/redist --upgrade nvidia-dali-cuda110
# pip install --extra-index-url https://developer.download.nvidia.com/compute/redist --upgrade nvidia-dali-cuda100

# --user leads to different packages location 
# export PYTHONPATH=~/.local/lib/python3.7/site-packages
```

**Usage**

You need replace default PyTorch dataloader with dali_dataloader, I provide a PyTorch DALI example using ImageNet-1k at [here](https://github.com/NUS-HPC-AI-Lab/LARS-ImageNet-PyTorch).This example has been tested with nvidia-dali-cuda110, maybe it needs some changes if you use it with CUDA10.

DALI requires data in *TFRecord format* in the following structure:

```
train-recs 'path/train/*' 
val-recs 'path/validation/*' 
train-idx 'path/idx_files/train/*' 
val-idx 'path/idx_files/validation/*' 
```

On longhorn, if you want use ImageNet-1k TFRecord data, you can directly use

data-dir=/scratch1/07801/nusbin20/ILSVRC2012_1k_TFRecord/

```shell
# TFRecord format tar file
/scratch1/07801/nusbin20/imagenet-tar/ILSVRC2012_1k_TFRecord.tar 
```

About the parameters on DALI:

- *prefetch_queue_depth* and *num_threads*  might also be something to explore, as it can speed up your loading a lot, with some memory tradeoff.
- *last_batch_policy*  you probably want PARTIAL on validation, and DROP during training: https://docs.nvidia.com/deeplearning/dali/user-guide/docs/plugins/pytorch_plugin_api.html?highlight=last_batch_policy, just as I set in above example link.
- *device*  Above example link use device="mixed/gpu", for ImageNet-1k and GPU with 16GB, default PyTorch dataloader allows batchsize 128, while DALI can only use batchsize 64. If you set device="mixed/gpu" to "cpu", it won't need extra GPU memory, however copying directly to gpu makes the loading much faster.

## Potential Error

- **Program works well in one node but get stuck just after it started running in two nodes.**

For Pytorch program with Horovod, please check your 'num_workers': N in torch.utils.data.DataLoader, maybe you need set 0 here to force synchronous IO, because there are some potential conflicts between Horovod and asynchronous IO on TACC-Frontera. In addition, maybe you cannot use torch.multiprocessing.set_start_method('spawn'). This can help progeam works but will seriously slow down the efficiency of the program. So, you would better use torch.distributed rather than Horovod on TACC-Frontera.

For Pytorch program with torch.distributed, please check your init_method. For shared file-system initialization, you need to select a **no-exist** file, eg. init_method='file:///mnt/nfs/sharedfile', maybe you need delete the file manually. For TCP initialization, 

```shell
# MASTER_ADDR is host address
# MASTER_PORT is unused host port
init_method=’tcp://$MASTER_ADDR:$MASTER_PORT’

# example in SLURM
master_addr = os.getenv('SLURM_LAUNCH_NODE_IPADDR')
master_port = ‘6006’
init_method = 'tcp://' + master_addr + ':' + master_port
```

- **torch.distributed.new_group(ranks=ranks) must be functions to be run by all processes**

Wrong example

```shell
if rank == 0:
	torch.distributed.new_group(ranks=ranks_1)
else:
	torch.distributed.new_group(ranks=ranks_2)
```

Correct example

```shell
global _DATA_PARALLEL_GROUP
assert _DATA_PARALLEL_GROUP is None, \
    'data parallel group is already initialized'
for i in range(model_parallel_size):
    ranks = range(i, world_size, model_parallel_size)
    group = torch.distributed.new_group(ranks)
    if i == (rank % model_parallel_size):
        _DATA_PARALLEL_GROUP = group
```

## Question Ticket

If you have some specific questions, you can sent them to [TACC Longhorn Help Desk](https://portal.tacc.utexas.edu/user-guides/longhorn#help-desk).