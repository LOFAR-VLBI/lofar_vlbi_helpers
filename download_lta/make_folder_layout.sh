#!/bin/bash

TARGET=$1
CALIBRATOR=$2

mkdir -p ${TARGET}
cd ${TARGET}
mkdir -p calibrator_${CALIBRATOR}
mkdir -p calibrator_${CALIBRATOR}/Data
mkdir -p target
mkdir -p target/Data