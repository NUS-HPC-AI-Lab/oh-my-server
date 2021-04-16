#!/bin/sh

#SBATCH -J myjob           # Job name
#SBATCH -o lars-t.o%j       # Name of stdout output file
#SBATCH -e lars-t.e%j       # Name of stderr error file
#SBATCH -p rtx            # Queue (partition) name
#SBATCH -N 2               # Total # of nodes (must be 1 for serial)
#SBATCH -n 8               # Total # of mpi tasks (should be 1 for serial)
#SBATCH -t 00:20:00        # Run time (hh:mm:ss)
#SBATCH --mail-user=your email
#SBATCH --mail-type=all    # Send email at begin and end of job


pwd
date

source ~/python-env/cuda10-home/bin/activate
export FS_ROOT=/tmp/fs_`id -u`
ibrun -np 2 /work/00410/huang/share/read_remote_file 16 /scratch1/07801/nusbin20/imagenet-16parts & sleep 500

module load intel/18.0.5 impi/18.0.5
module load cuda/10.1 cudnn nccl

cd /scratch1/07801/nusbin20/tacc-our

ibrun -np 8 LD_PRELOAD=/work/00410/huang/share/wrapper.so python pytorch_imagenet_resnet.py  --epochs 90 --model resnet50 --train-dir=/tmp/fs_871009/ILSVRC2012_img_train --val-dir=/tmp/fs_871009/ILSVRC2012_img_val 