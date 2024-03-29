# A lot of utility functions in this file
. ./config.zsh
. ./coap_stats.zsh

# Setup the tunslip tunnel while the experiment is running
setup_tunnel () {
  while (iotlab experiment wait -i $1 2>&1 > /dev/null) {
    ssh_iotlab -- sudo tunslip6.py -v3 -L -a m3-$gateway -p 20000 $prefix
  }
}

# Generate an experiment string
#
# local -a nodes=(1 2 3)
# experiment_string nodes foo bar
#
# gives "strasbourg,m3,1+2+3,foo,bar"
experiment_string () {
  local -a nodes=(${(P)1})
  local site=$site
  shift
  local -a args=(
    "$site"
    m3
    "${(j:+:)nodes}"
    $@
  )

  echo "${(j:,:)args}"
}

# Get the node IP from its ID
node_ip () {
  local uid=$uid_map[$1]
  echo "${prefix%/*}$uid"
}

# Prefix logs with timestamps
# ex: yes | add_timestamp
add_timestamp () {
  while IFS= read -r line; do
    printf "%s\t%s\n" "$(date '+%s')" "$line"
  done
}

local stopping=.stopping
echo 0 > $stopping

# Utility function to check if a SIGINT was sent
is_stopping () {
  if [ $(cat .stopping || true) = 1 ]; then
    return 0
  else
    return 255
  fi
}

# Trap SIGINTs
stop () {
  echo
  if (! is_stopping) {
    echo "Stopping experiment…" >&2
    iotlab experiment stop -i $1 > /dev/null
    echo "1" > $stopping
  } else {
    echo "Exiting." >&2
    exit
  }
}

# Run coap observes
coap_observe_loop () {
  while true; do
    coap get -o $1 1>&2
  done
}

# Run the coap benchmark
coap_bench_all () {
  coap_print_headers
  local -a nodes=(${(P)1})
  echo "coap_get_timestamp	$(date '+%s')" >> $result_dir/config
  for i ({1..60}) {
    for node ($nodes) {
      coap_req "coap://[$(node_ip m3-$node)]/sensors/light" &
    }
    sleep 5
  }

  sleep 30

  echo "coap_observe_timestamp	$(date '+%s')" >> $result_dir/config
  local -a pids=()
  for node ($nodes) {
    coap get -o "coap://[$(node_ip m3-$node)]/test/push" 1>&2 &
    echo $! >> $result_dir/pids
  }
}

# Ping all nodes
ping_all () {
  local -a nodes=(${(P)1})
  for node ($nodes) {
    ping6 $(node_ip m3-$node) &
    echo $! >> $result_dir/pids
  }
}

# Fetch the routing table after some delay
get_routing_table () {
  while (true) {
    sleep 60
    local buf="$(ssh_iotlab -- lynx -dump "http://[$(node_ip m3-$gateway)]")"
    echo "$buf"
  }
}

# Fetch the consumption results from iot-lab
fetch_results () {
  rsync_iotlab .iot-lab/$1/ $result_dir
}
