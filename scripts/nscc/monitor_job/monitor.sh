#!/usr/bin/env bash

job=${1:-""}
email=${2:-"c170166@e.ntu.edu.sg"}
interval=${3:-"600"}


source ~/anaconda3/bin/activate base
python /home/users/ntu/c170166/pbs_scripts/job_monitor/nscc_monitor.py --job $job --email $email --interval $interval