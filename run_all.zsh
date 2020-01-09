#!/usr/bin/env zsh

local -a firmwares=(
  contiki-mac
  nullrdc
  tsch
)

for firmware ($firmwares) {
  echo "Building $firmware"
  zsh ./build.zsh ./firmwares/$firmware
}

local -i runs=100

for run ({1..$runs}) {
  for firmware ($firmwares) {
    echo "Run $run with firmware $firmware" >&2
    zsh ./run.zsh ./firmwares/$firmware > runs/$firmware-$run 2>&1
    sleep 120
  }
}
