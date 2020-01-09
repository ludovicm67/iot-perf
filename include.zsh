. ./config.zsh
. ./coap_stats.zsh

setup_tunnel () {
  while (iotlab experiment wait -i $1 2>&1 > /dev/null) {
    ssh_iotlab -- sudo tunslip6.py -v3 -L -a m3-$gateway -p 20000 $prefix
  }
}

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

node_ip () {
  local uid=$uid_map[$1]
  echo "${prefix%/*}$uid"
}

add_timestamp () {
  while IFS= read -r line; do
    printf "%s\t%s\n" "$(date '+%s')" "$line"
  done
}

local stopping=.stopping
echo 0 > $stopping

is_stopping () {
  if [ $(cat .stopping || true) = 1 ]; then
    return 0
  else
    return 255
  fi
}

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

coap_bench_all () {
  touch $result_dir/coap_observe_pids
  coap_print_headers
  local -a nodes=(${(P)1})
  echo "coap_get_timestamp	$(date '+%s')" >> $result_dir/config
  for i ({1..60}) {
    is_stopping && return
    for node ($nodes) {
      coap_req "coap://[$(node_ip m3-$node)]/sensors/light" &
    }
    sleep 5
  }

  echo "coap_observe_timestamp	$(date '+%s')" >> $result_dir/config
  local -a pids=()
  for node ($nodes) {
    coap get "coap://[$(node_ip m3-$node)]/test/push" 1>&2 &
    echo $! >> $result_dir/coap_observe_pids
  }
}

fetch_results () {
  rsync_iotlab .iot-lab/$1/ $result_dir
}
