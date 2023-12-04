#!/bin/bash

# Copyright © 2023 Minionguyjpro <minionguyjpro@gmail.com>
# SPDX-License-Identifier: GPL-3.0

echo "🚀 NDSS: Starting NGROK to deSEC Forwarding Script..."

# Checking dependencies
echo "🔍 NDSS: Checking dependencies..."

apt_dependencies=()
snap_dependencies=()

# Check if snap is installed. If not, install it.
echo "🔍 DEPENDENCIES: Checking if snap is installed..."

if ! command -v snap &> /dev/null; then
    echo "❌ DEPENDENCIES: snap could not be found"
    echo "⬇️ DEPENDENCIES: Installing snap..."

    apt_dependencies+=("snapd")
fi

# Check if ngrok is installed. If not, install it.
echo "🔍 DEPENDENCIES: Checking if ngrok is installed..."

if ! command -v ngrok &> /dev/null; then
    echo "❌ DEPENDENCIES: ngrok could not be found"
    echo "⬇️ DEPENDENCIES: Installing ngrok..."

    snap_dependencies+=("ngrok")
fi

# Check if curl is installed. If not, install it.
echo "🔍 DEPENDENCIES: Checking if curl is installed..."

if ! command -v curl &> /dev/null; then
    echo "❌ DEPENDENCIES: curl could not be found"
    echo "⬇️ DEPENDENCIES: Installing curl..."

    apt_dependencies+=("curl")
fi

# Check if jq is installed. If not, install it.
echo "🔍 DEPENDENCIES: Checking if jq is installed..."

if ! command -v jq &> /dev/null; then
    echo "❌ DEPENDENCIES: jq could not be found"
    echo "⬇️ DEPENDENCIES: Installing jq..."

    apt_dependencies+=("jq")
fi

join() {
    local IFS="$1"
    shift
    echo "$*"
}

snap_command=""
apt_command=""

if [ ${#snap_dependencies[@]} -gt 0 ]; then
    snap_command="snap install $(join   "${snap_dependencies[@]}")"
fi

if [ ${#apt_dependencies[@]} -gt 0 ]; then
    apt_command="sudo apt install -y $(join   "${apt_dependencies[@]}")"
fi

install_dependencies() {
    sudo apt update
    sudo snap refresh 

    if [ ! -z "$snap_command" ]; then
        echo "⬇️ DEPENDENCIES: Installing snap dependencies..."

        eval "$snap_command"
    fi

    if [ ! -z "$apt_command" ]; then
        echo "⬇️ DEPENDENCIES: Installing apt dependencies..."

        eval "$apt_command"
    fi

    echo "✅ DEPENDENCIES: Dependencies installed successfully"
}

# if snap command or apt command is not empty, ask user if they want to install dependencies
if [ ! -z "$snap_command" ] || [ ! -z "$apt_command" ]; then
    read -p "🚀 DEPENDENCIES: Would you like to install missing dependencies? [y/N] " install

    case $install in
        [Yy]* ) install_dependencies; break;;
        * ) echo "❌ DEPENDENCIES: Operation cancelled, exiting..."; exit 1;;
    esac
fi

NGROK_TCP_PORT=`jq -r .NGROK_TCP_PORT config.json`
NGROK_AUTH_TOKEN=`jq -r .NGROK_AUTH_TOKEN config.json`
DESEC_AUTH_EMAIL=`jq -r .DESEC_AUTH_EMAIL config.json`
DESEC_AUTH_PASSWORD=`jq -r .DESEC_AUTH_PASSWORD config.json`
DESEC_API_TOKEN=`jq -r .DESEC_API_TOKEN config.json`
DESEC_DOMAIN=`jq -r .DESEC_DOMAIN config.json`
DESEC_CNAME_RECORD_NAME=`jq -r .DESEC_CNAME_RECORD_NAME config.json`
DESEC_SRV_RECORD_NAME=`jq -r .DESEC_SRV_RECORD_NAME config.json`

# Checking deSEC config
echo "🔍 NDSS: Checking deSEC config..."

# Get CNAME record from deSEC
echo "🔍 DS Checker: Getting CNAME record from deSEC..."

cname_record=$(curl -s -X GET "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/?type=CNAME&subname=$DESEC_CNAME_RECORD_NAME" \
                    -H "Authorization: Token $DESEC_API_TOKEN" \
                    -H "Content-Type: application/json")

# Check if record exists
if [[ $cname_record == *"Not found"* ]] || [[ $cname_record == *"[]"* ]]; then
    echo "❌ DS Checker: CNAME record does not exist in deSEC. You have to create it manually. Create a CNAME record in your deSEC dashboard and set the name to $DESEC_CNAME_RECORD_NAME (you can put example.com to target for now)"
    exit 1
fi

# Get CNAME record id
cname_record_id=$(echo "$cname_record" | sed -E 's/.*"id":"(\w+)".*/\1/')

# Get SRV record from deSEC
echo "🔍 DS Checker: Getting SRV record from deSEC..."

srv_record=$(curl -s -X GET "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/?type=SRV&subname=_minecraft._tcp" \
                    -H "Authorization: Token $DESEC_API_TOKEN" \
                    -H "Content-Type: application/json")

# Check if record exists
if [[ $srv_record == *"Not found"* ]] || [[ $srv_record == *"[]"* ]]; then
    echo "❌ DS Checker: SRV record does not exist in deSEC. You have to create it manually. Create an SRV record in your deSEC dashboard and set the subname to _minecraft._tcp (you can put example.com to target for now)"
    exit 1
fi

# Get SRV record id
srv_record_id=$(echo "$srv_record" | sed -E 's/.*"id":"(\w+)".*/\1/')

# Starting ngrok
echo "🚀 NDSS: Starting NGROK..."

# Set NGROK auth token
echo "🔑 NGROK: Setting NGROK auth token..."

ngrok config add-authtoken $NGROK_AUTH_TOKEN

# Run NGROK on background
echo "🚀 NGROK: Starting NGROK on background..."

ngrok tcp 127.0.0.1:$NGROK_TCP_PORT > /dev/null &

# Wait for NGROK to start
echo "🕑 NGROK: Waiting for NGROK to start..."

while ! curl -s localhost:4040/api/tunnels | grep -q "tcp://"; do
    sleep 1
done

echo "✅ NGROK: NGROK started successfully"

# Get NGROK URL
echo "🔗 NGROK: Getting NGROK URL..."

ngrok_url=$(curl -s localhost:4040/api/tunnels | grep -o "tcp://[0-9a-z.-]*:[0-9]*")
parsed_ngrok_url=${ngrok_url/tcp:\/\//}

IFS=':' read -ra ADDR <<< "$parsed_ngrok_url"
ngrok_host=${ADDR[0]}
ngrok_port=${ADDR[1]}

# Log NGROK URL
echo "🔗 NGROK: URL: $ngrok_url"
echo "🔗 NGROK: Parsed URL: $parsed_ngrok_url"
echo "🔗 NGROK: Host and Port: $ngrok_host - $ngrok_port"

# Update Cloudflare records
echo "📝 NDSS: Updating deSEC records..."

# Update CNAME record
echo "📝 DS Updater: Updating CNAME record..."

update=$(curl -s -X PATCH "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$DESEC_CNAME_RECORD_NAME/CNAME/" \
                     -H "Authorization: Token $DESEC_API_TOKEN" \
                     -H "Content-Type: application/json" --data @- <<< \
		     '{"records": ["'"$ngrok_host."'"]}')

# Check if update is successful
case "$update" in
    *"\"success\":false"*)
        echo "❌ DS Updater: CNAME record could not be updated in deSEC. $update"
        exit 1
    ;;
    *)
        echo "✅ DS Updater: CNAME record updated in deSEC. $ngrok_host - $DESEC_CNAME_RECORD_NAME"
    ;;
esac

# Update SRV record
echo "📝 DS Updater: Updating SRV record..."

update=$(curl -s -X PATCH "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/_minecraft._tcp/SRV/" \
                     -H "Authorization: Token $DESEC_API_TOKEN" \
                     -H "Content-Type: application/json" --data @- <<< \
                     '{"records": ["'"0 5 $ngrok_port $DESEC_SRV_RECORD_NAME.$DESEC_DOMAIN."'"]}')

# Check if update is successful
case "$update" in
    *"\"success\":false"*)
        echo "❌ DS Updater: SRV record could not be updated in deSEC. $update"
        exit 1
    ;;
    *)
        echo "✅ DS Updater: SRV record updated in deSEC. $ngrok_host - _minecraft._tcp.$DESEC_SRV_RECORD_NAME"
    ;;
esac

# Done! Exit gracefully
echo "✅ NDSS: Done! Exiting gracefully..."

exit 0
