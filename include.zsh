. ./config.zsh

setup_tunnel () {
  while (iotlab experiment wait -i $1) {
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
