#!/bin/sh

#SBATCH -J myjob           # Job name
#SBATCH -o myjob.o%j       # Name of stdout output file
#SBATCH -e myjob.e%j       # Name of stderr error file
#SBATCH -p rtx            # Queue (partition) name
#SBATCH -N 2               # Total # of nodes (must be 1 for serial)
#SBATCH -n 8               # Total # of mpi tasks (should be 1 for serial)
#SBATCH -t 00:10:00        # Run time (hh:mm:ss)
#SBATCH --mail-user=yongbinli@u.nus.edu
#SBATCH --mail-type=all    # Send email at begin and end of job


pwd
date

source ~/python-env/cuda10-home/bin/activate

cd /scratch1/07801/nusbin20/tacc-our
module load intel/18.0.5 impi/18.0.5
module load cuda/10.1 cudnn nccl

ibrun -np 8 \
	python pytorch_imagenet_resnet.py  \
	--epochs 90 \
	--model resnet50

