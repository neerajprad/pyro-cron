#!/usr/bin/env bash

set -xe

function _cleanup() {
    [[ ${#DIRSTACK[@]} -gt 1 ]] && popd
    [[ -d ${REF_TMP_DIR} ]] && rm -rf ${REF_TMP_DIR}
}

trap _cleanup EXIT

# Reference is with respect to the `dev` branch, by default.
REF_HEAD="$1"
BENCHMARK_FILE=tests/perf/test_benchmark.py
REF_TMP_DIR=/home/npradhan/workspace/pyro-cron/.tmp_test_dir
BENCHMARK_DIR=/home/npradhan/workspace/pyro-cron/.benchmarks
VIRTUALENV=pyro-cron-27
alias activate=/home/npradhan/miniconda3/bin/activate

# Activate virtualenv
source activate "${VIRTUALENV}"
# Use process time whenever possible to make timing more robust
# inside of VMs or when running other processes.
PY_VERSION=$(python -c 'import sys; print(sys.version_info[0])')
if [[ ${PY_VERSION} = 2 ]]; then
    TIMER=time.clock
else
    TIMER=time.process_time
fi

PERCENT_REGRESSION_FAILURE=10

# clone the repo into the temporary directory and run benchmark tests
# REF_HEAD could be a branch or a commit hash
git clone https://github.com/uber/pyro.git ${REF_TMP_DIR}
pushd ${REF_TMP_DIR}
git checkout ${REF_HEAD}

# Skip if benchmark utils are not on `dev` branch.
if [ -e ${BENCHMARK_FILE} ]; then
    pytest -vs tests/perf/test_benchmark.py --benchmark-save=${REF_HEAD} --benchmark-name=short \
        --benchmark-columns=min,median,max --benchmark-sort=name \
        --benchmark-storage=file://${BENCHMARK_DIR} \
        --benchmark-timer ${TIMER}
fi

# go back to the dev branch
source activate "${VIRTUALENV}"
git checkout dev

# Run benchmark comparison - fails if the min run time is 10% less than on the ref branch.
pytest -vx tests/perf/test_benchmark.py --benchmark-compare \
       --benchmark-storage=file://${BENCHMARK_DIR} \
       --benchmark-compare-fail=min:${PERCENT_REGRESSION_FAILURE}% \
       --benchmark-name=short --benchmark-columns=min,median,max --benchmark-sort=name \
       --benchmark-timer ${TIMER}
