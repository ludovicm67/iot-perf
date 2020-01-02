#!zsh

set -euo pipefail
. ./include.zsh

echo "Submitting experiment" >&2

iotlab experiment submit -d 5 \
  -l $(experiment_string nodes $firmware_nd) \
  -l $(experiment_string gateway $firmware_gw) \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" \
  | read experiment_id

trap "stop $experiment_id" INT HUP TERM

iotlab experiment wait -i $experiment_id > /dev/null

local -A uid_map=($(iotlab experiment get -r -i $experiment_id | python3 uid_map.py))

setup_tunnel $experiment_id | add_timestamp > m3-$gateway &
echo "border-router m3-$gateway" $(node_ip m3-$gateway)

for node ($nodes) {
  echo "server m3-$node" $(node_ip m3-$node)
  ssh_iotlab -- nc m3-$node 20000 | add_timestamp > m3-$node &
}

coap_bench_all nodes > coap_stats.csv &

wait

echo
echo "End."
