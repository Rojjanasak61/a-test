#!/bin/bash
namespace="test-web"
read_file="05-read-db.yaml"

echo "starting .."
read_apply()
{
  read_db=$(kubectl apply -f ./${read_file} --namespace=${namespace})
  sleep 2
  podname=$(kubectl get pod -n ${namespace} -o=name  |  sed "s/^.\{4\}//"  | grep -e "read-db-job")
  echo "reading db"

  while true
  do
          logs=$(kubectl logs -n ${namespace} ${podname})
          if [[ $logs == *"success"* ]]; then
                echo "read db finish"
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
        echo "start test"
        while true
        do
                POD_COUNT=$(kubectl get pods -n ${namespace} | wc -l)
                if [[ $POD_COUNT == *"4"* ]]; then
                        echo "test success"
                        break
                fi
        done

        cd ..
        rm -rf test-job
        sleep 10
        echo "success"
}

start_time=$(date +%s.%N)
read_apply
end_time=$(date +%s.%N)
read_time=$(echo "$end_time - $start_time" | bc)
read_execution_time+=($read_time)

start_time=$(date +%s.%N)
write_apply
end_time=$(date +%s.%N)
write_time=$(echo "$end_time - $start_time" | bc)
write_execution_time+=($read_time)

start_time=$(date +%s.%N)
run_apply
end_time=$(date +%s.%N)
run_time=$(echo "$end_time - $start_time" | bc)
run_execution_time+=($run_time)

echo "read time  : " $read_time
echo "write time : " $write_time
echo "run time   : " $run_time