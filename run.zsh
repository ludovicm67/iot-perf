#!zsh

set -euxo pipefail
. ./include.zsh

iotlab experiment submit -d 5 \
  -l $(experiment_string nodes $firmware_nd) \
  -l $(experiment_string gateway $firmware_gw) \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" \
  | read experiment_id

iotlab experiment wait -i $experiment_id

(while true; do setup_tunnel; done) &
ssh_iotlab -- serial_aggregator -i $experiment_id
