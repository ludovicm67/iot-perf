# Some config values
local -i channel=12
local panid=0x0012
local prefix=2001:660:4701:f0b1::/64

local site=strasbourg

# Border-router ID
local -i gateway=19
# Servers IDs
local -a nodes=(
  17
  37
  47
  64
)

local firmware=${1:-./firmwares/contiki-mac}
local contiki=$firmware/contiki
. $firmware/firmwares.zsh

# Used to run remote commands
alias ssh_iotlab="ssh iot2019stras12@$site.iot-lab.info"
# Used to fetch consomption results
rsync_iotlab () {
  rsync -avr iot2019stras12@$site.iot-lab.info:$1 $2
}
