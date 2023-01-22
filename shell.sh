#!/bin/bash

current_dir=$(pwd)
list_file=$(ls)
namespace="test-web"

current_dir=$(pwd)
parentdir="$(dirname "$current_dir")"

check=0

for filename in $list_file
do

    if [[ $filename == *"mysql-pv"* ]]; then
            check=$((check+1))
            pv_file=$filename
    fi

    if [[ $filename == *"mysql-app"* ]]; then
            check=$((check+1))
            mysql_file=$filename
    fi

    if [[ $filename == *"phpmyadmin"* ]]; then
            check=$((check+1))
            phpadmin_file=$filename
    fi

    if [[ $filename == *"web-app"* ]]; then
            check=$((check+1))
            web_file=$filename
    fi

    if [[ $filename == *"read-db"* ]]; then
            check=$((check+1))
            read_file=$filename
    fi

done

if [[ $check == 5 ]]; then
        echo "starting .."
else
        echo "file not found !!"
        exit 0
fi

name=$(kubectl create namespace ${namespace})
db_v=$(kubectl apply -f ./${pv_file} --namespace=${namespace})
db_a=$(kubectl apply -f ./${mysql_file} --namespace=${namespace})
db_s=$(kubectl apply -f ./${phpadmin_file} --namespace=${namespace})
web=$(kubectl apply -f ./${web_file} --namespace=${namespace})

sleep 2
kubectl get all -n ${namespace}

podname=$(kubectl get pod -n ${namespace} -o=name  |  sed "s/^.\{4\}//"  | grep -e "web-deployment")
echo "apply finish"

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
        start_time=$(date +%s.%N)
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
        end_time=$(date +%s.%N)
        write_time=$(echo "$end_time - $start_time" | bc)

        podname=$(kubectl get pod -n ${namespace} -o=name  |  sed "s/^.\{4\}//"  | grep -e "job")

        start_time=$(date +%s.%N)
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
        end_time=$(date +%s.%N)
        run_time=$(echo "$end_time - $start_time" | bc)
        echo "success"

}

start_time=$(date +%s.%N)
read_apply
end_time=$(date +%s.%N)
read_time=$(echo "$end_time - $start_time" | bc)
write_apply

echo $read_time
echo $write_time
echo $run_time