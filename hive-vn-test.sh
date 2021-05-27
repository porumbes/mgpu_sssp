#!/bin/bash

APP_NAME="main"

BIN_PREFIX="./"
DATA_PREFIX="./data"


APP_OPTIONS="10"

OUTPUT_DIR=${1:-"eval_mgpu"}
NUM_GPUS=${2:-"1"}
JSON_FILE=""

TAG="num-gpus:$NUM_GPUS"

NAME[0]="chesapeake"
NAME[1]="rmat18"
NAME[2]="rmat20"
NAME[3]="rmat22"
NAME[4]="rmat24"

GRAPH[0]="$DATA_PREFIX/${NAME[0]}.bin"
GRAPH[1]="$DATA_PREFIX/${NAME[1]}.bin"
GRAPH[2]="$DATA_PREFIX/${NAME[2]}.bin"
GRAPH[3]="$DATA_PREFIX/${NAME[3]}.bin"
GRAPH[4]="$DATA_PREFIX/${NAME[4]}.bin"

for i in {4..4}
do
   # prepare output json file name with number of gpus for this run
   JSON_FILE="${APP_NAME}__${NAME[$i]}__GPU${NUM_GPUS}"	

   #echo \
   $BIN_PREFIX$APP_NAME \
   ${GRAPH[$i]} \
   $APP_OPTIONS \
   > "$OUTPUT_DIR/$JSON_FILE.output.txt"
   #--tag=$TAG \
   #--jsonfile="$OUTPUT_DIR/$JSON_FILE.json" \
done
