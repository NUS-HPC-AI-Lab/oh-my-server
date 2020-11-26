#!/bin/bash -l
# replace with your favourite container image
# IMAGE_NAME="/home/projects/ai/singularity/nvcr.io/nvidia/tensorflow:20.02-tf1-py3.sif"
IMAGE_NAME="/home/project/ai/singularity/nvcr.io/nvidia/pytorch:latest-py3.sif"
pbs-attach "${PBS_JOBID}"
singularity run --nv ${NTUHPC_CONT_EXTRA_ARGS} -e "${IMAGE_NAME}" "${HOME}/scripts/dropbear/start-dropbear.sh"
