#!/bin/sh
# Usage: curl_test.sh <server name/ip> <server port> <uri path> '<success phrase>'

SERVER_NAME="$1"
SERVER_PORT="$2"
SERVER_URI="$3"
SUCCESS_PHRASE="$4"

# wait until server is available (inspired by https://github.com/Eficode/wait-for)
TIMEOUT=5
for i in $(seq ${TIMEOUT}); do
    if $(nc -z "${SERVER_NAME}" "${SERVER_PORT}" &>/dev/null); then
        break
    fi
    sleep 1
done
# check if timed out
if ! $(nc -z "${SERVER_NAME}" "${SERVER_PORT}" &>/dev/null); then
    echo "TEST FAILED"
fi

while true; do
    RETURNED_STRING=$(curl -s -S "${SERVER_NAME}":"${SERVER_PORT}"/"${SERVER_URI}")
    if $(echo "${RETURNED_STRING}" | grep -q "${SUCCESS_PHRASE}"); then
        echo "TEST PASSED"
    else
        echo "TEST FAILED: Expected=${SUCCESS_PHRASE}, Actual=${RETURNED_STRING}"
    fi
    sleep 1
done
