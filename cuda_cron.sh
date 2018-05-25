#!/usr/bin/env bash

set -e

DATE=$(date "+%y-%m-%d_%H%M%S")
WORKDIR=/home/npradhan/workspace/pyro-cron

bash ${WORKDIR}/cuda_test.sh 2>&1 > "${WORKDIR}/log/cuda_${DATE}.out" | tee "${WORKDIR}/log/cuda_${DATE}.err"

if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
  cat "${WORKDIR}/log/cuda_${DATE}.err" | /usr/bin/mail -s "Cuda Test - Failure" npradhan@uber.com
else
  cat "${WORKDIR}/log/cuda_${DATE}.out" | /usr/bin/mail -s "Cuda Test - Success" npradhan@uber.com
fi
