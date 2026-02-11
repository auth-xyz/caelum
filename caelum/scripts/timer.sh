#! /bin/bash 

counter=1
minutes=27
mininsec=$(( $minutes * 60 )); 

while [ $counter -lt $mininsec ]; do 
    echo "[c] counting the seconds: { $counter / $mininsec }"
    sleep 1
    counter=$(( $counter + 1 ))
done

systemctl suspend

