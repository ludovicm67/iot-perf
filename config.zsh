local -i channel=12
local panid=0x0012
local prefix=2001:660:4701:f0b1::/64

local site=strasbourg
local -i gateway=19
local -a nodes=(
  17
  37
  47
  64
)

local firmware=${1:-./firmwares/contiki-mac}
local contiki=$firmware/contiki
. $firmware/firmwares.zsh

alias ssh_iotlab="ssh iot2019stras12@$site.iot-lab.info"
rsync_iotlab () {
  rsync -avr iot2019stras12@$site.iot-lab.info:$1 $2
}
