#!/bin/bash
namespace="test-web"
read_file="05-read-db.yaml"

read_apply()
{
  read_db=$(kubectl apply -f ./${read_file} --namespace=${namespace})
  sleep 2
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
          image: homesrh/exploit-app:2.0
          env:
            - name: URL_TARGET
              value: ${url}
      restartPolicy: Never
EOF
                fi
                let row++
        done
        job=$(kubectl apply -f .)
        podname=$(kubectl get pod -n ${namespace} -o=name  |  sed "s/^.\{4\}//"  | grep -e "job")

}

run_apply()
{
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
        read_apply
        end_time=$(date +%s.%N)
        read_time=$(echo "$end_time - $start_time" | bc)
        read_execution_time+=($read_time)

        start_time=$(date +%s.%N)
        write_apply
        end_time=$(date +%s.%N)
        write_time=$(echo "$end_time - $start_time" | bc)
        write_execution_time+=($write_time)

        start_time=$(date +%s.%N)
        run_apply
        end_time=$(date +%s.%N)
        run_time=$(echo "$end_time - $start_time" | bc)
        run_execution_time+=($run_time)
        echo 1+$i-1
done

average_time=$(echo "${read_execution_time[*]}" | tr ' ' '\n' | awk '{s+=$1} END {print s/NR}')
echo "Average read data time: $average_time seconds"

average_time=$(echo "${write_execution_time[*]}" | tr ' ' '\n' | awk '{s+=$1} END {print s/NR}')
echo "Average apply pods time: $average_time seconds"

average_time=$(echo "${run_execution_time[*]}" | tr ' ' '\n' | awk '{s+=$1} END {print s/NR}')
echo "Average pentest time: $average_time seconds"