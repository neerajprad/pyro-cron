#!/usr/bin/env bash

set -xe

function _cleanup() {
  RETCODE=$?
  [[ ${#DIRSTACK[@]} -gt 1 ]] && popd
  exit $RETCODE
}

trap _cleanup EXIT

REF_HEAD_FILE=".cron/ref_head.txt"
WORKDIR="/home/npradhan/workspace/pyro-cron"
ref=$(<"${WORKDIR}/${REF_HEAD_FILE}")

pushd ${WORKDIR}
bash ${WORKDIR}/perf_test.sh "${ref}"
