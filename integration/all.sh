#!/usr/bin/env bash

pushd $(dirname $0) > /dev/null

source ./run

export LOGS_PATH=../build


title "Initialising testing infrastructure"
init || teardown 1

title "Running parallel suites"
#tests-parallel || teardown 1

title "Running sequential tests"
tests-ceph || teardown 1

teardown 0
