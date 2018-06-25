#!/usr/bin/env bash

set -xe

REF_HEAD_FILE=/home/npradhan/workspace/pyro-cron/.cron/ref_head.txt

function _cleanup() {
  RETCODE=$?
  if [[ ${#DIRSTACK[@]} -gt 1 ]]; then
    CURRENT_HEAD=$(git rev-parse HEAD)
    popd    
  fi
  [[ ${RETCODE} = 0 ]] && echo ${CURRENT_HEAD} >| ${REF_HEAD_FILE}
  [[ -d ${REF_TMP_DIR} ]] && rm -rf ${REF_TMP_DIR}

  # reset cpuset
  cset shield --reset
  exit ${RETCODE}
}

trap _cleanup EXIT

# Define csets to isolate the job

cset shield --cpu 15,43

# Reference is with respect to the `dev` branch, by default.
REF_HEAD="$1"
BENCHMARK_FILE=tests/perf/test_benchmark.py
REF_TMP_DIR=/home/npradhan/workspace/pyro-cron/.tmp_test_dir
BENCHMARK_DIR=/home/npradhan/workspace/pyro-cron/.benchmarks
VIRTUALENV=/home/npradhan/miniconda3/envs/pyro-cron-36

PERCENT_REGRESSION_FAILURE=10

# clone the repo into the temporary directory and run benchmark tests
# REF_HEAD could be a branch or a commit hash
git clone https://github.com/uber/pyro.git ${REF_TMP_DIR}
${VIRTUALENV}/bin/pip uninstall -y pyro-ppl
pushd ${REF_TMP_DIR}
${VIRTUALENV}/bin/pip install -e .
git checkout ${REF_HEAD}

# Skip if benchmark utils are not on `dev` branch.
if [ -e ${BENCHMARK_FILE} ]; then
  cset shield -e ${VIRTUALENV}/bin/pytest -- \
        -vs tests/perf/test_benchmark.py \
        --benchmark-save=${REF_HEAD} \
        --benchmark-name=short \
        --benchmark-disable-gc \
        --benchmark-warmup=on \
	--benchmark-warmup-iterations=4 \
	--benchmark-timer=time.process_time \
        --benchmark-columns=min,median,max --benchmark-sort=name \
        --benchmark-storage=file://${BENCHMARK_DIR}
fi

# go back to the dev branch
git checkout dev

# Run benchmark comparison - fails if the min run time is 10% less than on the ref branch.
cset shield -e ${VIRTUALENV}/bin/pytest -- \
       -vx tests/perf/test_benchmark.py --benchmark-compare \
       --benchmark-disable-gc \
       --benchmark-warmup=on \
       --benchmark-warmup-iterations=4 \
       --benchmark-timer=time.process_time \
       --benchmark-storage=file://${BENCHMARK_DIR} \
       --benchmark-compare-fail=median:${PERCENT_REGRESSION_FAILURE}% \
       --benchmark-name=short --benchmark-columns=min,median,max --benchmark-sort=name
