#!/bin/bash

#SBATCH --job-name="spark"
#SBATCH --time=00:30:00
#SBATCH --nodes=4
#SBATCH --constraint=gpu
#SBATCH --output=sparkjob.%j.log
#SBATCH --account=<project>

# set some variables for Spark
export SPARK_WORKER_CORES=12
export SPARK_LOCAL_DIRS="/tmp"

# load modules
module load slurm
module load daint-gpu
module load Spark

# deploy of spark
start-all.sh

# some extra Spark configuration
SPARK_CONF="
--conf spark.default.parallelism=10
--conf spark.executor.cores=8
--conf spark.executor.memory=15g
"

# submit a Spark job
spark-submit ${SPARK_CONF} --master $SPARKURL \
    --class org.apache.spark.examples.SparkPi \
    $EBROOTSPARK/examples/jars/spark-examples_2.11-2.4.7.jar 10000;

# clean out Spark deployment
stop-all.sh