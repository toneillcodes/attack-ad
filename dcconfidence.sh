#!/bin/bash
dcconfidence=0
echo "dcconfidence: $dcconfidence"
dcportlist=(53 88 123 135 137 138 139 389 445 464 636 3268 3269)
portlist=(22 53 88 123 135 137 138 139 389 445 464 636 3268 3269)
for port in "${portlist[@]}";
do
        if [[ " ${dcportlist[@]} " =~ " $port " ]]; then
                echo "Value found in array"
                ((dcconfidence++))
        else
                echo "Value not found in array"
        fi
done
echo "dcconfidence result: $dcconfidence"
