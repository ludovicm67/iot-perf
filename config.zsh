local -i channel=12
local panid=0x0012
local prefix=2001:660:4701:f0b1::/64

local site=strasbourg
local -i gateway=20
local -a nodes=(
  17
  37
  48
  64
)
local contiki=./contiki
local firmware_gw=$contiki/examples/ipv6/rpl-border-router/border-router.iotlab-m3
local firmware_nd=$contiki/examples/iotlab/04-er-rest-example/er-example-server.iotlab-m3

alias ssh_iotlab="ssh iot2019stras12@$site.iot-lab.info"
