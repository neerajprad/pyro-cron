#!/usr/bin/env bash

set -xe
#export BASH_XTRACEFD=1
DATE=$(date "+%y-%m-%d_%H%M%S")
WORKDIR=/home/npradhan/workspace/pyro-cron
REF_HEAD_FILE=".cron/ref_head.txt"
ref=$(<"${WORKDIR}/${REF_HEAD_FILE}")

bash ${WORKDIR}/perf_test.sh ${ref} 2>&1 > "${WORKDIR}/log/perf_${DATE}.out" > "${WORKDIR}/log/perf_${DATE}.err"
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  cat "${WORKDIR}/log/perf_${DATE}.err" | /usr/bin/mail -s "Perf Test - Failure" npradhan@uber.com
else
  echo Success | /usr/bin/mail -s "Perf Test - Success" npradhan@uber.com
fi
