#!/bin/bash

function fetch_rmat {
  SCALE=$1
  wget https://graphchallenge.s3.amazonaws.com/synthetic/graph500-scale${SCALE}-ef16/graph500-scale${SCALE}-ef16_adj.mmio.gz
  gunzip graph500-scale${SCALE}-ef16_adj.mmio.gz
  mv graph500-scale${SCALE}-ef16_adj.mmio data/rmat${SCALE}.mtx
}

SCALE=${1:-"18"}
fetch_rmat $SCALE
python prob2bin.py --inpath data/rmat${SCALE}.mtx
#./main data/rmat18.bin
