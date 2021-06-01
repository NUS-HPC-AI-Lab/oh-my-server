#!/bin/bash -l

#SBATCH --job-name=my_cscs_job
#SBATCH --time=00:10:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=12
#SBATCH --constraint=gpu
#SBATCH --account=<project>

module load daint-gpu
module load PyTorch

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# Environment variables needed by the NCCL backend
export NCCL_DEBUG=INFO
export NCCL_IB_HCA=ipogif0
export NCCL_IB_CUDA_SUPPORT=1

. /users/your_account/miniconda3/bin/activate pt38

cd your_code_path

srun \
python -u your_code.py  \
--epochs 90 \
--model resnet50 \
> ${SLURM_JOBID}.out 2> ${SLURM_JOBID}.err
