# TACC-Longhorn

- [Build Conda Environment ](#build-conda-environment )
- [Common Commands](#common-commands)
- [Job Script Example](#job-script-example)
- [Dataset and Transfer files](#dataset-and-transfer-files)
- [Large Scale Experiment](#large-scale-experiment)
- [DALI](#dali)
- [Question Ticket](#question-ticket)

## Build Conda Environment 

You can follow the file "TACC distributed pytorch.pdf", which show an example about how to build your conda environment and run the code with interactive usage. But the example use PyTorch 1.1, and the newest version in the used [link](https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/) seems only PyTorch 1.3. In addition, unlike other TACC machines, Longhorn nodes are a PowerPC architecture (Power PC 64 LE). Thus, when pulling images from (e.g.) Docker Hub, make sure the image is Power PC 64 LE compatible.  Here, you can use the method in this [link](https://stackoverflow.com/questions/52750622/how-to-install-pytorch-on-power-8-or-ppc64-machine/64528124#64528124?newreg=1b10fc8fcbed4beca9cdc3d4238359a5), to bulid a Python 3.6 and PyTorch 1.5 conda environment.

## Common Commands

```shell
# To directory $SCRATCH. The default directory is $HOME when you login in.
# Longhorn users must run all jobs in Longhorn's $SCRATCH file system.
cd $SCRATCH

# interactive usage
idev -t 02:00:00 -N 1 -n 4 -p development

# submit a job script
sbatch /PATH/TO/job.slurm

# check your job status
squeue -u your_account

# delete your job
scancel job_ID

# display estimated start time for job
squeue --start -j job_ID

# view loaded module
# module related commands need at computing node
module list

# view avail module
module available

# active your conda environment
# you need run it after you login in computing nodes everytime
module load conda
conda activate your_env_name

# generate hostfile according to your current avaliable computing resources
# Note, you maybe need run it after you login in computing nodes everytime, 
# because you may get different computing resources.
scontrol show hostname > hostfile

# run your code with interactive usage
# -N means GPU numbers per node, -np means total GPU numbers
mpiexec -hostfile hostfile -N 4 -np 8 python your_file.py
```

For more detailed information, please refer to [TACC Longhorn User Guide](https://portal.tacc.utexas.edu/user-guides/longhorn).

## Job Script Example

```
#!/bin/sh

#SBATCH -J myjob           # Job name
#SBATCH -o myjob.o%j       # Name of stdout output file
#SBATCH -e myjob.e%j       # Name of stderr error file
#SBATCH -p v100            # Queue (partition) name
#SBATCH -N 2               # Total # of nodes (must be 1 for serial)
#SBATCH -n 8               # Total # of mpi tasks (should be 1 for serial)
#SBATCH -t 00:30:00        # Run time (hh:mm:ss)
#SBATCH --mail-user=your email address
#SBATCH --mail-type=all    # Send email at begin and end of job

pwd
date

cd your_code_path
module load conda
conda activate your_env_name

ibrun -np 8 \
python your_code.py
```

You should use ibrun instead of mpirun or mpiexec here, and -np means total GPU numbers.

Note: Although in Longhorn tutorial, they use "#SBATCH -A myproject       # Allocation name", you can actually delete it. If you incorrect set it, you will meet permission error when submit job.

## Dataset and Transfer files

**Dataset**

```shell
cp /scratch/00946/zzhang/data/imagenet-1k.tar /your/path
tar xf imagenet-1k.tar
# TFRecord format file
/scratch/07801/nusbin20/imagenet-tar/ILSVRC2012_1k_TFRecord.tar 
```

You can get a prepared ImageNet-1K (ILSVRC2012) use above command.

Maybe you can find other prepared dataset around this path.

**Transfer files**

You can use scp or git clone command,  or WinSCP, a visible tool can input TACC token, to transfer files.

```shell
# scp command
# tested in Git Bash on Windows10
scp G:/your_path/xxx.tar your_account@longhorn.tacc.utexas.edu:/your_path/imagenet-tar
```

## Large Scale Experiment

(You can also consider DALI rather than this part)

If a job uses many nodes (eg. 32 nodes with 128 GPUs) and reads large dataset(eg. ImageNet) directly from the hard disk, it will cause huge IO pressure on the file system, which may cause the job to be killed by the system : (

So, for large scale experiment, we need first move the data to the /tmp file system of nodes for temporary storage and then run the program, to reduce the IO pressure of the main file system.

large scale experiment job script example

```shell
#!/bin/sh

#SBATCH -J myjob           # Job name
#SBATCH -o myjob.o%j       # Name of stdout output file
#SBATCH -e myjob.e%j       # Name of stderr error file
#SBATCH -p v100            # Queue (partition) name
#SBATCH -N 2               # Total # of nodes (must be 1 for serial)
#SBATCH -n 8               # Total # of mpi tasks (should be 1 for serial)
#SBATCH -t 00:30:00        # Run time (hh:mm:ss)
#SBATCH --mail-user=your email
#SBATCH --mail-type=all    # Send email at begin and end of job

pwd
date

cd your_code_path
module load conda
conda activate py36pt

scontrol show hostnames $SLURM_NODELIST > /tmp/hostfile

cat /tmp/hostfile

mpiexec -hostfile /tmp/hostfile -N 1 ./cp_imagenet_to_temp_bin.sh

ibrun -np 8 \
python your_code.py
```

cp_imagenet_to_temp_bin.sh copy and extract imagenet data to following path, which may take 50 minutes :( 

The data in /tmp will be automatically deleted when job finished, which is located in the following path

```shell
--train-dir=/tmp/imagenet/ILSVRC2012_img_train/
--val-dir=/tmp/imagenet/ILSVRC2012_img_val/
```

## DALI

NVIDIA DALI can accelerate data loading and pre-processing using GPU rather than CPU, although with GPU memory tradeoff. 

It can also avoid some potential conflicts between MPI libraries and Horovod on some GPU clusters.  

**Install**

```shell
conda install dali
# because longhorn is Power architecture, we cannot use following command as other cluster.
# pip install --extra-index-url https://developer.download.nvidia.com/compute/redist --upgrade nvidia-dali-cuda110
```

**Usage**

You need replace default PyTorch dataloader with dali_dataloader, I provide a PyTorch DALI example using ImageNet-1k at [here](https://github.com/NUS-HPC-AI-Lab/LARS-ImageNet-PyTorch). This example has been tested with nvidia-dali-cuda110, maybe it needs some changes if you use it with Longhorn CUDA10 and Power architecture.

DALI requires data in *TFRecord format* in the following structure:

```
train-recs 'path/train/*' 
val-recs 'path/validation/*' 
train-idx 'path/idx_files/train/*' 
val-idx 'path/idx_files/validation/*' 
```

On longhorn, if you want use ImageNet-1k TFRecord data, you can directly use

data-dir=/scratch/07801/nusbin20/ILSVRC2012_1k_TFRecord/

```shell
# TFRecord format tar file
/scratch/07801/nusbin20/imagenet-tar/ILSVRC2012_1k_TFRecord.tar 
```

About the parameters on DALI:

- *prefetch_queue_depth* and *num_threads*  might also be something to explore, as it can speed up your loading a lot, with some memory tradeoff.
- *last_batch_policy*  you probably want PARTIAL on validation, and DROP during training: https://docs.nvidia.com/deeplearning/dali/user-guide/docs/plugins/pytorch_plugin_api.html?highlight=last_batch_policy, just as I set in above example link.
- *device*  Above example link use device="mixed/gpu", for ImageNet-1k and GPU with 16GB, default PyTorch dataloader allows batchsize 128, while DALI can only use batchsize 64. If you set device="mixed/gpu" to "cpu", it won't need extra GPU memory, however copying directly to gpu makes the loading much faster.

## Question Ticket

If you have some specific questions, you can sent them to [TACC Frontera Help Desk](https://frontera-portal.tacc.utexas.edu/user-guide/help/).