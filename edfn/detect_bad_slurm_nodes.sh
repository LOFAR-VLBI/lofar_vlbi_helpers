#!/bin/bash

TODAY=$(date +"%Y-%m-%d")
MAX_RUNTIME=5 # seconds until Failure
JOB_PATTERN="toil_job"

BAD_NODES=$(sacct -X -S "$TODAY" --format=JobID,JobName%50,State,NodeList,ElapsedRaw --noheader |
grep "$JOB_PATTERN" |
grep -E "FAILED|NODE_FAIL" |
awk -v max="$MAX_RUNTIME" '$5 < max { print $4 }' |
tr ',' '\n' |
sort -u |
paste -sd, -)

echo "$BAD_NODES"
