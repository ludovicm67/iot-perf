#!zsh

# Handles CSV generation for CoAP requests

function coap_print_headers() {
  echo "timestamp,request_url,request_time,response_code,status_code"
}

function coap_req() {
  TS=$(date +%s)
  set +e
  RES=$(coap -T "$1" 2>&1)
  STATUS_CODE="$?"
  set -e
  if [ "$STATUS_CODE" -ne 0 ]; then
    echo "$TS,$1,0,-1,$STATUS_CODE"
    echo "request failed ; got non-zero status code: $STATUS_CODE" >&2
  else
    HEAD=$(echo $RES | head -n2)
    REQ_TIME=$(echo $HEAD | head -n1 | awk '{ print $3 }')
    RES_CODE=$(echo $HEAD | awk -F'[(|)]' 'FNR==2{print $2}')
    echo "$TS,$1,$REQ_TIME,$RES_CODE,$STATUS_CODE"
  fi
}

if ! [[ $ZSH_EVAL_CONTEXT =~ :file$ ]]; then
  if [ "$#" -lt 1 ]; then
    echo "usage: url [interval]" >&2
    exit 1
  fi

  COAP_URL=$1
  COAP_INTERVAL=${2:-5}

  coap_print_headers
  while true; do
    (coap_req $COAP_URL &)
    sleep "$COAP_INTERVAL"
  done
fi
