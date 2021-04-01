# TACC-Frontera

- [Build Conda Environment ](#build-conda-environment )
- [Common Commands](#common-commands)
- [Job Script Example](#job-script-example)
- [Dataset](#dataset)
- [Large Scale Experiment](#large-scale-experiment)
- [Potential Error](#potential-error)
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

After testing, I **strongly not recommended to use Horovod on TACC-Frontera** because there is a serious incompatibility with the environment.

Please **use torch.distributed for distribution**.

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

## Dataset

```shell
cp /scratch1/00946/zzhang/imagenet/imagenet-1k.tar /your/path
tar xf imagenet-1k.tar

--train-dir=/your/path/ILSVRC2012_img_train/
--val-dir=/your/path/ILSVRC2012_img_val/
```

You can get a prepared ImageNet-1K (ILSVRC2012) use above command.

Maybe you can find other prepared dataset around this path.

## Large Scale Experiment

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









