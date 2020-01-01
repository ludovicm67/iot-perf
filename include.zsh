. ./config.zsh

setup_tunnel () {
  ssh_iotlab -- sudo tunslip6.py -v2 -L -a m3-$gateway -p 20000 $prefix
}

experiment_string () {
  local -a nodes=(${(P)1})
  local firmware=$2
  local site=$site

  echo -n "$site,m3,${(j:+:)nodes},$firmware"

  if (( ${+3} )) {
    echo ",$3"
  } else {
    echo
  }
}
