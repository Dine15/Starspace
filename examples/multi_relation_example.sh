#!/usr/bin/env bash
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

MODELDIR=/tmp/starspace/models
DATADIR=/tmp/starspace/data
DATASET=FB15k

convert_data() {
    while read -r line 
    do
        read HEAD_ENTITY RELATION_TYPE TAIL_ENTITY <<< $line
        REVERSE_RELATION='reverse'$RELATION_TYPE
        echo -e ''$HEAD_ENTITY'\t'$RELATION_TYPE'\t'$TAIL_ENTITY''
        echo -e ''$TAIL_ENTITY'\t'$REVERSE_RELATION'\t'$HEAD_ENTITY''
    done < "$1"  
}

mkdir -p "${MODELDIR}"
mkdir -p "${DATADIR}"

echo "Downloading dataset freebase 15k"
if [ ! -f "${DATADIR}/${DATASET}/fb15k.train" ]
then
    wget -c "https://everest.hds.utc.fr/lib/exe/fetch.php?media=en:fb15k.tgz" -O "${DATADIR}/${DATASET}_csv.tar.gz"
    tar -xzvf "${DATADIR}/${DATASET}_csv.tar.gz" -C "${DATADIR}"
    
    echo "Converting data to StarSpace format ..."
    
    convert_data "${DATADIR}/${DATASET}/freebase_mtr100_mte100-train.txt" > "${DATADIR}/${DATASET}/fb15k.train"
    convert_data "${DATADIR}/${DATASET}/freebase_mtr100_mte100-test.txt" > "${DATADIR}/${DATASET}/fb15k.test"
fi

echo "Compiling StarSpace"

make

./starspace train \
  -trainFile ${DATADIR}/${DATASET}/fb15k.train \
  -model ${MODELDIR}/fb15k \
  -adagrad false \
  -margin 0.05 \
  -lr 0.05 \
  -epoch 20 \
  -thread 40 \
  -dim 50 \
  -negSearchLimit 100 \
  -trainMode 4 \
  -label "/m/" \
  -similarity "dot" \
  -verbose true

./starspace test \
  -testFile ${DATADIR}/${DATASET}/fb15k.test \
  -model ${MODELDIR}/fb15k \
  -thread 40 \
  -dim 50 \
  -trainMode 4 \
  -label "/m/" \
  -similarity "dot" \
  -verbose true
