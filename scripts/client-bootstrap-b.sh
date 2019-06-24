#!/bin/bash -x

#Waits for openvpn service to become active and installs Cohesive Networks VNS3 Routing Agent

 wait_for_openvpn () {
   while :
    do
    servicestatus=`/sbin/ifconfig | grep "$IP" 2>&1`
          if [ $? = 0 ] ; then
           sudo rpm -ivh /tmp/cohesive-ra-1.1.1_x86_64.rpm;
           exit 0
          fi
        sleep 2
    done
}

wait_for_openvpn