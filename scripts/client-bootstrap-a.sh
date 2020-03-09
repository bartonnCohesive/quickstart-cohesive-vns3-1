#!/bin/bash -ex

wait_for_api () {
    set +e
    while true; do
        curl -k -X GET -u api:$VNS3PW https://$VNS3IP:8000/api/config --fail > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 2
    done
    set -e
}

wait_for_api

sleep 5m

PACK=$VNS3OVERLAYIP

request_body=$(< <(cat <<EOF
{
  "name": "$PACK",
  "fileformat": "conf"
}
EOF
))

sudo curl -s -k -X GET -u api:$VNS3PW -H 'Content-Type: application/json' -d "$request_body" https://$VNS3IP:8000/api/clientpack -o /etc/openvpn/vns3clientpack.conf

exit 0
