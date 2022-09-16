#!/bin/bash

RUNDIR=$PWD

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"

if [[ $RUNDIR =~ $re ]]; then LNUM=${BASH_REMATCH[1]}; fi

echo $LNUM