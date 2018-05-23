#!/usr/bin/env bash

set -xe

VIRTUALENV=pyro-cron-27
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
alias activate=/home/npradhan/miniconda3/bin/activate

source activate "${VIRTUALENV}"

# On exit, go back to `dev` branch and remove `cron-jobs` branch
function _cleanup() {
  [[ ${#DIRSTACK[@]} -gt 1 ]] && popd
  if [[ -d pyro ]]; then
    rm -rf pyro
  fi
}

trap _cleanup EXIT

pushd "${DIR}"
git clone --depth=50 https://github.com/uber/pyro.git
pushd pyro
git checkout dev

CUDA_TEST=1 PYRO_TENSOR_TYPE=torch.cuda.DoubleTensor pytest -vx --stage unit
CUDA_TEST=1 pytest -vx tests/test_examples.py::test_cuda
