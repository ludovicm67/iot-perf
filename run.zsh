#!zsh

set -euo pipefail
. ./include.zsh

echo "Submitting experiment" >&2

iotlab experiment submit -d 15 \
  -l $(experiment_string nodes $firmware_nd) \
  -l $(experiment_string gateway $firmware_gw) \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" \
  | read experiment_id

trap "stop $experiment_id" INT HUP TERM

iotlab experiment wait -i $experiment_id > /dev/null

local -A uid_map=($(iotlab experiment get -r -i $experiment_id | python3 uid_map.py))

local result_dir=./results/$experiment_id
mkdir -p $result_dir
cat > $result_dir/config <<EOF
nodes	$nodes
gateway	$gateway
firmware_gw	$firmware_gw
firmware_nd	$firmware_nd
uid_map	${(kv)uid_map}
EOF

local -a jobs_pids=()

setup_tunnel $experiment_id | add_timestamp > $result_dir/m3-$gateway &
jobs_pids+=($!)
echo "border-router m3-$gateway" $(node_ip m3-$gateway)

for node ($nodes) {
  echo "server m3-$node" $(node_ip m3-$node)
  ssh_iotlab -- nc m3-$node 20000 | add_timestamp > $result_dir/m3-$node &
  jobs_pids+=($!)
}

coap_bench_all nodes > $result_dir/coap_stats.csv &
local -i coap_bench_pid=$!

echo "serial jobs pids: $jobs_pids"
wait $jobs_pids

builtin kill $coap_bench_pid || true
builtin kill $(cat $result_dir/coap_observe_pids) || true

fetch_results $experiment_id

echo
echo "End."
