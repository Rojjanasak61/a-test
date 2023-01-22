#!/bin/bash
execution_time=()
for i in {1..10}
do
    start_time=$(date +%s.%N)

    python3 app.py $1

    end_time=$(date +%s.%N)
    run_time=$(echo "$end_time - $start_time" | bc)
    execution_time+=($run_time)
done

average_time=$(echo "${execution_time[*]}" | tr ' ' '\n' | awk '{s+=$1} END {print s/NR}')
echo "Average execution time: $average_time seconds"
