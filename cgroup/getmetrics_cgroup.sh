#!/bin/sh
DATADIR='data/'
cd $DATADIR

dockers=$(docker ps --no-trunc | awk '{if(NR!=1)print $1}')
for container in $dockers; do
    CONTAINER_PID=`docker inspect -f '{{ .State.Pid }}' $container`
    date +%s%3N | awk '{print "timestamp="$1}' > timestamp.txt & PID1=$!
    cat /cgroup/memory/docker/$container/memory.usage_in_bytes | awk '{print "MemUsed="$1}' > memmetrics_$container.txt & PID2=$!
    cat /cgroup/memory/docker/$container/memory.limit_in_bytes | awk 'BEGIN{mem_total=0} {if($1<=999999999){mem_total+=$1}} END{print "MemTotal="mem_total}' >> memmetrics_$container.txt & PID3=$!
    cat /cgroup/blkio/docker/$container/blkio.throttle.io_service_bytes | grep Read | awk 'BEGIN{readbytes=0} {if(NR!=1){readbytes+=$3}} END{print "DiskRead="readbytes}' > diskmetricsread_$container.txt & PID4=$!
    cat /cgroup/blkio/docker/$container/blkio.throttle.io_service_bytes | grep Write | awk 'BEGIN{writebytes=0} {if(NR!=1){writebytes+=$3;}} END{print "DiskWrite="writebytes}' > diskmetricswrite_$container.txt & PID5=$!
    cat /proc/$CONTAINER_PID/net/dev | awk 'BEGIN{rxbytes=0;txbytes=0} {if(NR!=1 && NR!=2){if($1!="lo:"){rxbytes+=$2;txbytes+=$10;}}} END{print "NetworkIn="rxbytes; print "NetworkOut="txbytes}' > networkmetrics_$container.txt & PID6=$!
    cat /cgroup/cpuacct/docker/$container/cpuacct.stat | awk 'BEGIN{cpu=0} {cpu+=$2} END{print "CPU="cpu}' > cpumetrics_$container.txt & PID7=$!
    
    # Get Filesystem metrics
    docker exec $container df -k | awk 'BEGIN{diskusedspace=0}{if(NR!=1)print "DiskUsed"$6"="$3; diskusedspace += $3}END{print "DiskUsed="diskusedspace}' > diskusedmetrics_$container.txt & PID8=$!
    
    # Get Shared Memory metrics
    docker exec $container cat /proc/meminfo | grep Shmem | awk '{gsub( "[:':']","=" );print}' | awk 'BEGIN{i=0} {mem[i]=$2;i=i+1} END{print "SharedMem="(mem[0])}' >> memmetrics_$container.txt & PID9=$!

    # Get Swap metrics
    docker exec $container cat /proc/meminfo | grep Swap | awk '{gsub( "[:':']","=" );print}' | awk 'BEGIN{i=0} {swap[i]=$2;i=i+1} END{print "SwapUsed="(swap[1]-swap[2])"\nSwapTotal="(swap[1])}' >> memmetrics_$container.txt & PID10=$!
    
    # Get Per-Interface Network metrics
    rm networkinterfacemetrics_$container.txt
    OLD_IFS=$IFS
    IFS=$'\n'
    for nic in `grep : /proc/$CONTAINER_PID/net/dev`
    do 
        echo $nic | tr -d : >>/tmp/nicstats_docker.txt
        echo $nic | tr -d : | \
        awk '{print "InOctets-"$1"="$2"\nOutOctets-"$1"="$10"\nInErrors-"$1"="$4"\nOutErrors-"$1"="$12"\nInDiscards-"$1"="$5"\nOutDiscards-"$1"="$13}' \
        >> networkinterfacemetrics_$container.txt
    done
    IFS=$OLD_IFS
    wait $PID1
    wait $PID2
    wait $PID3
    wait $PID4
    wait $PID5
    wait $PID6
    wait $PID7
    wait $PID8
    wait $PID9
    wait $PID10
done

