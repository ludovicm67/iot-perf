. ./config.zsh

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

local stopping=false

stop () {
  echo
  if [ $stopping = false ]; then
    echo "Stopping experiment…" >&2
    iotlab experiment stop -i $1 > /dev/null
    stopping=true
  else
    echo "Exiting." >&2
    exit
  fi
}
