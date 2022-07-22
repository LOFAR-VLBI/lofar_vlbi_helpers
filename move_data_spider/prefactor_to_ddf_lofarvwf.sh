#!/bin/bash

L=$1

cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/${L}/target/Pre-Facet-Target/results/${L}* /project/lofarvwf/Public/jdejong/ELAIS/${L}
chmod -R a+rwx /project/lofarvwf/Public/jdejong/ELAIS/${L}/*