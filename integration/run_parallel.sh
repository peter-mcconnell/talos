#!/usr/bin/env bash

# file that contains the exit code for all the parallel tests
# if one of the tests fails, it will contain the value 1
# if all passed, it will contain the value 0
export EXIT_CODE=/tmp/run-parallel-exit-code

# reset the result to 0
echo 0 >${EXIT_CODE}

nose2 -c /setup.cfg -v tests.dummy || echo 1 >${EXIT_CODE} &
nose2 -c /setup.cfg -v tests.dummys || echo 1 >${EXIT_CODE} &

wait
exit $(cat ${EXIT_CODE})
