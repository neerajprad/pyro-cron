#!/usr/bin/env bash

set -xe

WORKDIR=/home/npradhan/workspace/pyro-cron
VIRTUALENV=pyro-cron-36

# On exit, go back to `dev` branch and remove `cron-jobs` branch
function _cleanup() {
  RETCODE=$?
  [[ ${#DIRSTACK[@]} -gt 1 ]] && popd
  if [[ -d pyro ]]; then
    rm -rf pyro
  fi
  [[ ${#DIRSTACK[@]} -gt 1 ]] && popd
  exit ${RETCODE}
}

trap _cleanup EXIT

# Activate virtualenv
source /home/npradhan/miniconda3/bin/activate "${VIRTUALENV}"

pushd "${WORKDIR}"
git clone --depth=50 https://github.com/uber/pyro.git
pushd pyro
git checkout dev
pip uninstall -y pyro-ppl
pip install -e .

CUDA_TEST=1 PYRO_TENSOR_TYPE=torch.cuda.DoubleTensor pytest -vx --stage unit
CUDA_TEST=1 pytest -vx tests/test_examples.py::test_cuda
