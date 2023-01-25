#!/bin/bash
namespace="test-web"
read_file="05-read-db.yaml"

read_apply()
{
  read_db=$(kubectl apply -f ./${read_file} --namespace=${namespace})
  sleep 4
  podname=$(kubectl get pod -n ${namespace} -o=name  |  sed "s/^.\{4\}//"  | grep -e "read-db-job")

  while true
  do
          logs=$(kubectl logs -n ${namespace} ${podname})
          if [[ $logs == *"success"* ]]; then
                break
          fi
          sleep 2
  done

}

write_apply()
{
        mkdir test-job
        cd test-job
        row=1
        for url in $logs
        do
                if [[ $url != *"success"* ]]; then
cat > ${row}-url-ping.yaml <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${row}-test-job
  namespace: ${namespace}
spec:
  ttlSecondsAfterFinished: 2
  template:
    metadata:
      name: ${row}-job
      labels:
        app: ${row}-job
    spec:
      containers:
        - name: ${row}-job
          image: homesrh/exploit-app:2.1
          env:
            - name: URL_TARGET
              value: ${url}
      restartPolicy: Never
EOF
                fi
                let row++
        done
        job=$(kubectl apply -f .)
        sleep 2
        podname=$(kubectl get pod -n ${namespace} -o=name  |  sed "s/^.\{4\}//"  | grep -e "job")
        cd ..

}

run_apply()
{
        cd test-job
        while true
        do
                POD_COUNT=$(kubectl get pods -n ${namespace} | wc -l)
                if [[ $POD_COUNT == *"4"* ]]; then
                        break
                fi
        done

        cd ..
        rm -rf test-job
        sleep 4
}

read_execution_time=()
write_execution_time=()
run_execution_time=()

for i in {1..30}
do
        start_time=$(date +%s.%N)
        start_cpu=$(grep 'cpu' /proc/stat)
        start_mem=$(free -m)
        read_apply
        end_time=$(date +%s.%N)
        end_cpu=$(grep 'cpu' /proc/stat)
        end_mem=$(free -m)
        read_time=$(echo "$end_time - $start_time" | bc)
        read_execution_time+=($read_time)
        printf "Run %d:\n" $i >> 01-aTest.txt
        printf "Execution time: %.9f seconds\n" $read_time >> 01-aTest.txt
        printf "Start CPU | User | Nice | System | Idle | Iowait | Irq | Softirq | Steal | Guest | Guest_nice\n%s\n" "$start_cpu" >> 01-aTest.txt
        printf "End CPU | User | Nice | System | Idle | Iowait | Irq | Softirq | Steal | Guest | Guest_nice\n%s\n" "$end_cpu" >> 01-aTest.txt
        printf "Start MEM \n%s\n" "$start_mem" >> 01-aTest.txt
        printf "End MEM \n%s\n" "$end_mem" >> 01-aTest.txt

        start_time=$(date +%s.%N)
        start_cpu=$(grep 'cpu' /proc/stat)
        start_mem=$(free -m)
        write_apply
        end_time=$(date +%s.%N)
        end_cpu=$(grep 'cpu' /proc/stat)
        end_mem=$(free -m)
        write_time=$(echo "$end_time - $start_time" | bc)
        write_execution_time+=($write_time)
        printf "Run %d:\n" $i >> 02-aTest.txt
        printf "Execution time: %.9f seconds\n" $write_time >> 02-aTest.txt
        printf "Start CPU | User | Nice | System | Idle | Iowait | Irq | Softirq | Steal | Guest | Guest_nice\n%s\n" "$start_cpu" >> 02-aTest.txt
        printf "End CPU | User | Nice | System | Idle | Iowait | Irq | Softirq | Steal | Guest | Guest_nice\n%s\n" "$end_cpu" >> 02-aTest.txt
        printf "Start MEM \n%s\n" "$start_mem" >> 02-aTest.txt
        printf "End MEM \n%s\n" "$end_mem" >> 02-aTest.txt
        

        start_time=$(date +%s.%N)
        start_cpu=$(grep 'cpu' /proc/stat)
        start_mem=$(free -m)
        run_apply
        end_time=$(date +%s.%N)
        end_cpu=$(grep 'cpu' /proc/stat)
        end_mem=$(free -m)
        run_time=$(echo "$end_time - $start_time" | bc)
        run_execution_time+=($run_time)
        printf "Run %d:\n" $i >> 03-aTest.txt
        printf "Execution time: %.9f seconds\n" $run_time >> 03-aTest.txt
        printf "Start CPU | User | Nice | System | Idle | Iowait | Irq | Softirq | Steal | Guest | Guest_nice\n%s\n" "$start_cpu" >> 03-aTest.txt
        printf "End CPU | User | Nice | System | Idle | Iowait | Irq | Softirq | Steal | Guest | Guest_nice\n%s\n" "$end_cpu" >> 03-aTest.txt
        printf "Start MEM \n%s\n" "$start_mem" >> 03-aTest.txt
        printf "End MEM \n%s\n" "$end_mem" >> 03-aTest.txt
        
done

average_time=$(echo "${read_execution_time[*]}" | tr ' ' '\n' | awk '{s+=$1} END {print s/NR}')
echo "Average read data time: $average_time seconds"

average_time=$(echo "${write_execution_time[*]}" | tr ' ' '\n' | awk '{s+=$1} END {print s/NR}')
echo "Average apply pods time: $average_time seconds"

average_time=$(echo "${run_execution_time[*]}" | tr ' ' '\n' | awk '{s+=$1} END {print s/NR}')
echo "Average pentest time: $average_time seconds"