#! /bin/bash
set -eu

DIR=$(dirname "$0")
cd $DIR

pids=()
lookup=()
failed_count=0
failed_lookup=()
counter=0

function run_setup {
    ./node_modules/.bin/ava setup.test.ts
}

function run_tests {
    for test_case in $(find scalers -name "*.test.ts")
    do
        ./node_modules/.bin/ava $test_case > "${test_case}.log" 2>&1 &
        pid=$!
        echo "Running $test_case with pid: $pid"
        pids+=($pid)
        lookup[$pid]=$test_case
    done
}

function mark_failed {
    failed_lookup[$1]=${lookup[$1]}
    let "failed_count+=1"
}

function wait_for_jobs {
    for job in "${pids[@]}"; do
        wait $job || mark_failed $job
        echo "Job $job finished"
    done

    printf "\n$failed_count jobs failes\n"
}

function print_logs {
    for test_log in $(find scalers -name "*.log")
    do
        echo ">>> $test_log <<<"
        cat $test_log
        printf "\n\n##############################################\n"
        printf "##############################################\n\n"
    done
}

function run_cleanup {
    ./node_modules/.bin/ava cleanup.test.ts
}

function print_failed {
    echo "$failed_count tests failed"
    for failed_test in "${failed_lookup[@]}"; do
        echo $failed_test
    done
}

run_setup
run_tests
wait_for_jobs
print_logs
run_cleanup

if [ "$failed_count" == "0" ];
then
    exit 0
else
    print_failed
    exit 1
fi