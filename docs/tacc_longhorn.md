# TACC-Longhorn

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