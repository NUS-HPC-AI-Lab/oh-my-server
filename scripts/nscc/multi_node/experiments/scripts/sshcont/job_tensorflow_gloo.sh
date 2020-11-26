#!/bin/bash -li

# DATESTAMP=`date +'%y%m%d%H%M%S'`

# Edit this
RUN_SCRIPT=/home/users/ntu/c170166/scratch/projects/dl-auto-load-balance/auto-ml-load-balance/scripts/nscc/jupyter/mpi_testing/test_mpi.sh
# RUN_SCRIPT=/home/users/ntu/c170166/scratch/projects/dl-auto-load-balance/auto-ml-load-balance/scripts/nscc/jupyter/pretrain_bert_mpi.sh

# Clear environment and run
env -i - "/home/users/ntu/c170166/.local/bin/horovodrun" \
	-H "${NTUHPC_OPENMPI_HOSTSPEC}" -np "${NTUHPC_OPENMPI_SLOTCOUNT}" --gloo $RUN_SCRIPT


#env -i - "/home/users/ntu/c170166/.local/bin/horovodrun" \
#	-H "${NTUHPC_OPENMPI_HOSTSPEC}" -np "${NTUHPC_OPENMPI_SLOTCOUNT}" --gloo $GLUE_SCRIPT
