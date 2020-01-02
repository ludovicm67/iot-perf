#!zsh

set -euo pipefail
. ./include.zsh

iotlab experiment submit -d 5 \
  -l $(experiment_string nodes $firmware_nd) \
  -l $(experiment_string gateway $firmware_gw) \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" \
  | read experiment_id

iotlab experiment wait -i $experiment_id

local -A uid_map=($(iotlab experiment get -r -i $experiment_id | python3 uid_map.py))

setup_tunnel $experiment_id > tunnel-stdout 2> tunnel-stderr &
for node ($nodes) {
  node_ip m3-$node
}
ssh_iotlab -- serial_aggregator -l $(experiment_string nodes) | tee aggregator-out
