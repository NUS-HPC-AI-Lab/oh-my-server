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

