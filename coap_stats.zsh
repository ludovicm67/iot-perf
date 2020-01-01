#!zsh

if [ "$#" -lt 1 ]; then
  echo "usage: url [interval]" >&2
  exit 1
fi

COAP_URL=$1
COAP_INTERVAL=${2:-5}

function print_headers() {
  echo "timestamp,request_url,interval,request_time,response_code"
}

function coap_req() {
  TS=$(date +%s)
  RES=$(coap -T "$COAP_URL" 2>&1)
  STATUS_CODE="$?"
  if [ "$STATUS_CODE" -ne 0 ]; then
    echo "$TS,$COAP_URL,$COAP_INTERVAL,0,-1"
    echo "request failed ; got non-zero status code: $STATUS_CODE" >&2
  else
    HEAD=$(echo $RES | head -n2)
    REQ_TIME=$(echo $HEAD | head -n1 | awk '{ print $3 }')
    RES_CODE=$(echo $HEAD | awk -F'[(|)]' 'FNR==2{print $2}')
    echo "$TS,$COAP_URL,$COAP_INTERVAL,$REQ_TIME,$RES_CODE"
  fi
}

print_headers
while true; do
  (coap_req &)
  sleep "$COAP_INTERVAL"
done
