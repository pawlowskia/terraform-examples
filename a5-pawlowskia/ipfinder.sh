API_URL="http://169.254.169.254/latest/api"
TOKEN=`curl -X PUT "$API_URL/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600"` 
TOKEN_HEADER="X-aws-ec2-metadata-token: $TOKEN"
METADATA_URL="http://169.254.169.254/latest/meta-data"
AZONE=`curl -H "$TOKEN_HEADER" -s $METADATA_URL/placement/availability-zone`
IP_V4=`curl -H "$TOKEN_HEADER" -s $METADATA_URL/public-ipv4`
INTERFACE=`curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/ | head -n1`
SUBNET_ID=`curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/${INTERFACE}/subnet-id`
VPC_ID=`curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/${INTERFACE}/vpc-id`
echo "Your EC2 instance works in :AvailabilityZone: ${AZONE} / VPC: ${VPC_ID} / VPC subnet: ${SUBNET_ID} / IP address: ${IP_V4}"
echo 'const socket = io("ws://'${IP_V4}':3000");' | cat - ./frontend/js/socket.js > temp && mv temp ./frontend/js/socket.js
