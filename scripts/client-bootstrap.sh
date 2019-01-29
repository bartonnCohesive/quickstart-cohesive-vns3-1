#!/bin/bash -e

rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum update -y
yum install -y openvpn

PACK=100_127_255_193

wait_for_api () {
  while :
    do
    apistatus=`curl -k -X GET -u api:$VNS3PW https://$VNS3IP:8000/api/config 2>&1`
       echo $apistatus | grep "refused"
         if [ $? != 0 ] ; then
           break
         fi
        sleep 2
    done
}

set +e
wait_for_api
set -e

request_body=$(< <(cat <<EOF
{
  "name": "$PACK",
  "format": "conf"
}
EOF
))

curl -s -k -X GET -u api:$VNS3PW -H 'Content-Type: application/json' -d "$request_body" https://$VNS3IP:8000/api/clientpack -o /etc/openvpn/$PACK.conf
echo "redirect-gateway def1" >> /etc/openvpn/$PACK.conf
echo "route 10.0.0.0 255.255.255.0 net_gateway" >> /etc/openvpn/$PACK.conf
systemctl -f enable openvpn@$PACK.service
systemctl start openvpn@$PACK
curl -k -X POST -u api:$VNS3PW -d '{"rule":"MACRO_CUST -o eth0 -s 100.127.255.193/29 -j MASQUERADE"}' -H 'Content-Type: application/json' https://$VNS3IP:8000/api/firewall/rules
curl -k -X POST -u api:$VNS3PW -d '{"rule":"PREROUTING_CUST -i eth0 -p tcp -s 0.0.0.0/0 --dport 22 -j DNAT --to 100.127.255.193:22"}' -H 'Content-Type: application/json' https://$VNS3IP:8000/api/firewall/rules
curl -k -X POST -u api:$VNS3PW -d '{"rule":"FORWARD_CUST -j ACCEPT"}' -H 'Content-Type: application/json' https://$VNS3IP:8000/api/firewall/rules
