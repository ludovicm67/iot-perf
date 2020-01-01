typeset -i channel=12
typeset panid=0x0012
typeset prefix=2001:660:4701:f0b1::/64

typeset site=strasbourg
typeset -i gateway=2
typeset -a nodes=(
  17
  37
  48
  64
)
typeset contiki=./contiki
typeset firmware_gw=$contiki/examples/ipv6/rpl-border-router/border-router.iotlab-m3
typeset firmware_nd=$contiki/examples/iotlab/04-er-rest-example/er-example-server.iotlab-m3

alias ssh_iotlab="ssh iot2019stras12@$site.iot-lab.info"
