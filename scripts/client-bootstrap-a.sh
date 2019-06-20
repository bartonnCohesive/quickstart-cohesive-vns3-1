#!/bin/bash -e

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

wait_for_api

PACK=$(echo $VNS3OVERLAYIP | sed 's/\./_/g')
NETWORK=$(echo $VPC_CIDR | sed 's/\/.*//')
MASK=$(echo $VPC_CIDR | sed 's/.*\///')

if [ $MASK = 8 ]; then
	NETMASK=255.0.0.0
elif [ $MASK = 9 ]; then
	NETMASK=255.128.0.0
elif [ $MASK = 10 ]; then
	NETMASK=255.192.0.0
elif [ $MASK = 11 ]; then
	NETMASK=255.224.0.0
elif [ $MASK = 12 ]; then
	NETMASK=255.240.0.0
elif [ $MASK = 13 ]; then
	NETMASK=255.248.0.0
elif [ $MASK = 14 ]; then
	NETMASK=255.252.0.0
elif [ $MASK = 15 ]; then
	NETMASK=255.254.0.0
elif [ $MASK = 16 ]; then
	NETMASK=255.255.0.0
elif [ $MASK = 17 ]; then
	NETMASK=255.255.128.0
elif [ $MASK = 18 ]; then
	NETMASK=255.255.192.0
elif [ $MASK = 19 ]; then
	NETMASK=255.255.224.0
elif [ $MASK = 20 ]; then
	NETMASK=255.255.240.0
elif [ $MASK = 21 ]; then
	NETMASK=255.255.248.0
elif [ $MASK = 22 ]; then
	NETMASK=255.255.252.0
elif [ $MASK = 23 ]; then
	NETMASK=255.255.254.0
elif [ $MASK = 24 ]; then
	NETMASK=255.255.255.0
elif [ $MASK = 25 ]; then
	NETMASK=255.255.255.128
elif [ $MASK = 26 ]; then
	NETMASK=255.255.255.192
elif [ $MASK = 27 ]; then
	NETMASK=255.255.255.224
elif [ $MASK = 28 ]; then
	NETMASK=255.255.255.240
elif [ $MASK = 29 ]; then
	NETMASK=255.255.255.248
elif [ $MASK = 30 ]; then
	NETMASK=255.255.255.252
fi

request_body=$(< <(cat <<EOF
{
  "name": "$PACK",
  "format": "conf"
}
EOF
))

curl -s -k -X GET -u api:$VNS3PW -H 'Content-Type: application/json' -d "$request_body" https://$VNS3IP:8000/api/clientpack -o /tmp/$PACK.conf

echo "redirect-gateway def1" >> /tmp/$PACK.conf
echo "route "$NETWORK" "$NETMASK" net_gateway" >> /tmp/$PACK.conf

echo "up \"/bin/bash -c '[ -e /usr/local/cohesive/ra/routing-agent ] && sudo /usr/local/cohesive/ra/routing-agent restart || exit 0'\"" >> /tmp/$PACK.conf
echo "up-restart" >> /tmp/$PACK.conf
echo "down \"/bin/bash -c '[ -e /usr/local/cohesive/ra/routing-agent ] && sudo /usr/local/cohesive/ra/routing-agent stop || exit 0'\"" >> /tmp/$PACK.conf

sed 's/^remote '$VNS3IP' 1194/remote '$VNS3PDNS' 1194/g' /tmp/$PACK.conf > /etc/openvpn/$PACK.conf

rm -f /tmp/$PACK.conf

exit 0
