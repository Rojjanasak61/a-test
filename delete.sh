#!/bin/bash

list_file=$(ls)
check=0

namespace="test-web"

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

echo "deleting"


web=$(kubectl delete -f ./${web_file} --namespace=${namespace})
db_s=$(kubectl delete -f ./${phpadmin_file} --namespace=${namespace})
db_a=$(kubectl delete -f ./${mysql_file} --namespace=${namespace})
db_v=$(kubectl delete -f ./${pv_file} --namespace=${namespace})
name=$(kubectl delete namespace ${namespace})


sleep 2
echo "success"
