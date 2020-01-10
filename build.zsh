#!zsh

# Build border-router and node firmwares

. ./config.zsh

echo "Build gateway firmware…"
pushd $(dirname $firmware_gw)
make TARGET=iotlab-m3
popd

echo "\nBuild node firmware…"
pushd $(dirname $firmware_nd)
make TARGET=iotlab-m3
popd

exit 0
