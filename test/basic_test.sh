#!/bin/bash

now=$(date +"%s")
TEST_EMAIL="roger-$now@example.com"
TEST_USER="rogersmith-$now"
TEST_PASS="passw0rd"

base_url="$1"


if [ "$2" = "insecure" ]; then
    ignore_cert="--insecure"
fi


function create_user_and_login () {
    test_endpoint $base_url/api/v1/users.register -H "Content-type:application/json" -d "{ \"username\": \"$TEST_USER\", \"email\": \"$TEST_EMAIL\", \"pass\": \"$TEST_PASS\", \"name\": \"Roger Smith\"}"
    test_endpoint $base_url/api/v1/login -d "user=$TEST_USER&password=$TEST_PASS"
    userId="X-User-Id: $(echo "$response" | jq -r .data.userId)"
    authToken="X-Auth-Token: $(echo "$response" | jq -r .data.authToken)"
}


function test_endpoint() {
    echo -n "Hitting $1... "
    curl_output=$(curl --write-out '\n%{http_code}' $ignore_cert --silent "$@")
    response="$(echo "$curl_output" | head -n -1)"
    return_code="$(echo "$curl_output" | tail -n 1)"
    if [ "${return_code}" != "200" ]; then
        echo ""
        echo "Error: endpoint $1 returned code $return_code"
        echo "$response"
        exit 1
    fi
    echo "ok"
}

test_endpoint "$base_url/api/info"
create_user_and_login
test_endpoint "$base_url/api/v1/chat.sendMessage" -H "Content-type:application/json" -H "$userId" -H "$authToken" -d "{\"message\": { \"rid\": \"GENERAL\", \"msg\": \"This is a test message from $TEST_USER\" }}"
test_endpoint "$base_url/api/v1/channels.messages?roomId=GENERAL" -H "$userId" -H "$authToken"
if [[ "$response" != *"This is a test message from $TEST_USER"* ]]; then
  echo "Couldn't find sent message. Somethings wrong!"
  exit 2
fi