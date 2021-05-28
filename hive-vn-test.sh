#!/bin/bash

APP_NAME="main"

BIN_PREFIX="./"
DATA_PREFIX[0]="./data"
DATA_PREFIX[1]="/home/u00u7u37rw7AjJoA4e357/data/gunrock/gunrock_dataset/mario-2TB/large"



OUTPUT_DIR=${1:-"eval_mgpu"}
NUM_GPUS=${2:-"1"}
JSON_FILE=""

NUM_SEEDS=${3:-"10"}
APP_OPTIONS=${NUM_SEEDS}

TAG="num-gpus:$NUM_GPUS"

NAME[0]="chesapeake"
NAME[1]="rmat18"
NAME[2]="rmat20"
NAME[3]="rmat22"
NAME[4]="rmat24"
NAME[5]="enron"
NAME[6]="hollywood-2009"
NAME[7]="indochina-2004"

DATA_PATH=${DATA_PREFIX[0]}
GRAPH[0]="$DATA_PATH/${NAME[0]}.bin"
GRAPH[1]="$DATA_PATH/${NAME[1]}.bin"
GRAPH[2]="$DATA_PATH/${NAME[2]}.bin"
GRAPH[3]="$DATA_PATH/${NAME[3]}.bin"
GRAPH[4]="$DATA_PATH/${NAME[4]}.bin"

DATA_PATH=${DATA_PREFIX[1]}
GRAPH[5]="$DATA_PATH/${NAME[5]}/${NAME[5]}.bin"
GRAPH[6]="$DATA_PATH/${NAME[6]}/${NAME[6]}.bin"
GRAPH[7]="$DATA_PATH/${NAME[7]}/${NAME[7]}.bin"

SUB_DIR=${NUM_SEEDS}
mkdir -p "$OUTPUT_DIR/$SUB_DIR"

for i in {1..7}
do
   # prepare output json file name with number of gpus for this run
   JSON_FILE="vn__${NAME[$i]}__GPU${NUM_GPUS}"	

   #echo \
   $BIN_PREFIX$APP_NAME \
   ${GRAPH[$i]} \
   $APP_OPTIONS \
   "$OUTPUT_DIR/$SUB_DIR/$JSON_FILE.json" \
   > "$OUTPUT_DIR/$SUB_DIR/$JSON_FILE.output.txt"
   #--tag=$TAG \
   #--jsonfile="$OUTPUT_DIR/$JSON_FILE.json" \
done
