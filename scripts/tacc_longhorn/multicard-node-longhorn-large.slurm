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

cd /scratch/07801/nusbin20/tacc-our
module load conda
conda activate py36pt

scontrol show hostnames $SLURM_NODELIST > /tmp/hostfile

cat /tmp/hostfile

mpiexec -hostfile /tmp/hostfile -N 1 ./cp_imagenet_to_temp_bin.sh

ibrun -np 8 \
python examples/pytorch_imagenet_resnet.py \
--epochs 90 \
--model resnet50
