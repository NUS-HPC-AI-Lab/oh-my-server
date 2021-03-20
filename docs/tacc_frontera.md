# TACC-Frontera

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
mkvirtualenv cuda10-home

# active environment
source ~/python-env/cuda10-home/bin/activate

# you can use pip to install packages
```

Build **Horovod with Pytorch**.

```shell
# login in computing nodes and virtualenv 
idev -p rtx-dev -N 1 -n 4 -t 02:00:00
source ~/python-env/cuda10-home/bin/activate
# load modules (cannot use default intel/19 impi/19)
module load intel/18.0.5 impi/18.0.5
module load cuda/10.1 cudnn nccl

# install Pytorch, example 1.5.1
pip install torch==1.5.1+cu101 torchvision==0.6.1+cu101 -f https://download.pytorch.org/whl/torch_stable.html

# bulid Horovod 
HOROVOD_CUDA_HOME=$TACC_CUDA_DIR HOROVOD_NCCL_HOME=$TACC_NCCL_DIR  CC=gcc HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_GPU_BROADCAST=NCCL HOROVOD_WITHOUT_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 HOROVOD_WITHOUT_MXNET=1 pip install horovod --no-cache-dir --force-reinstall
```

If your Pytorch program with Horovod works well in one node but get stuck just after it started running in two nodes. Please check your 'num_workers': N in torch.utils.data.DataLoader, maybe you need set 0 here to force synchronous IO, because there are some potential conflicts between Horovod and asynchronous IO on TACC-Frontera.



## Common Commands

```shell
# To directory $SCRATCH. The default directory is $HOME when you login in.
# Longhorn users must run all jobs in Longhorn's $SCRATCH file system.
cd $SCRATCH

# interactive usage
idev -p rtx-dev -N 1 -n 4 -t 02:00:00

# submit a job script
sbatch /PATH/TO/job.slurm

# check your job status
squeue -u your_account

# delete your job
scancel job_ID

# display estimated start time for job
squeue --start -j job_ID

# active your environment and load cuda components
# you need run it after you login in computing nodes everytime
source ~/python-env/cuda10-home/bin/activate
module load cuda/10.1 cudnn nccl

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

## Dataset

```shell
cp /scratch1/00946/zzhang/imagenet/imagenet-1k.tar /your/path
tar xf imagenet-1k.tar
```

You can get a prepared ImageNet-1K (ILSVRC2012) use above command.

Maybe you can find other prepared dataset around this path.

If a job uses many nodes (eg. 32 nodes with 128 GPUs) and reads large dataset(eg. ImageNet) directly from the hard disk, it will cause huge IO pressure on the file system, which may cause the job to be killed by the system : (

I am communicating and verifying with the system administrator, and the solution will come soon.