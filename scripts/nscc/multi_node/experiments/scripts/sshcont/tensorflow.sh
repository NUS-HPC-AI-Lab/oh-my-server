#!/bin/bash 
trap 'kill $(jobs -pr)' SIGINT SIGTERM EXIT

IMAGE_NAME="/home/project/ai/singularity/nvcr.io/nvidia/pytorch:latest-py3.sif"
export NTUHPC_CONT_EXTRA_ARGS="--bind ${NTUHPC_SSH_DIR}:$HOME/.ssh"
echo "Binding ${NTUHPC_CONT_EXTRA_ARGS}"

pbsdsh hostname
`which mpirun` --bind-to none --tag-output -x NTUHPC_CONT_EXTRA_ARGS \
    -H "${NTUHPC_OPENMPI_HOSTSPEC}" -N 1 -np "${NTUHPC_OPENMPI_HOSTCOUNT}" \
    "${HOME}/scripts/sshcont/container_slaves_tensorflow.sh" &

echo "Waiting 180s for SSH servers to be up"
sleep 180s
echo "Logging in"

echo $@
singularity run --nv ${NTUHPC_CONT_EXTRA_ARGS} "${IMAGE_NAME}" $@
