#!/bin/bash

NUM_GPUS=${1:-"16"}

PARTITION_NAME=${2:-"dgx2"}

#PARTITION_NAME="batch"
NODE_NAME="dgx2-000"

APP_SCRIPT="./hive-vn-test.sh"
NUM_SEEDS[0]=10
NUM_SEEDS[1]=100
NUM_SEEDS[2]=1000

OUTPUT_DIR="vn_eval_mgpu/$PARTITION_NAME"
mkdir -p $OUTPUT_DIR

for n_seeds in {0..2}
do
   for (( i=1; i<=$NUM_GPUS; i++))
   do
       # prepare and run SLURM command
       #SLURM_CMD="srun --cpus-per-gpu 1 -G $i -p $PARTITION_NAME -w $NODE_NAME"
       #SLURM_CMD="srun --cpus-per-gpu 1 -G $i -p $PARTITION_NAME "
   
       SLURM_CMD="srun --cpus-per-gpu 1 -G $i -p $PARTITION_NAME -N 1 "
       $SLURM_CMD $APP_SCRIPT $OUTPUT_DIR $i ${NUM_SEEDS[$n_seeds]} &
   
       #echo "$SLURM_CMD $APP_SCRIPT $OUTPUT_DIR $i ${NUM_SEEDS[$n_seeds]}"
       #sleep 1
   done
done
