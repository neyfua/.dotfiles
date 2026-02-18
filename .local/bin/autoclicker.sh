#!/usr/bin/env bash

CLICK_INTERVAL=30000
LEFT_BUTTON=272
CLICKER="$HOME/.cargo/bin/theclicker"

DEVICES=(
    "/dev/input/by-id/usb-Compx_VGN_Mouse_2.4G_Receiver-if02-event-mouse"
    "/dev/input/by-id/usb-compx_VGN_F1_MOBA-if02-event-mouse"
)

for d in "${DEVICES[@]}"
do
    if [ -e "$d" ]
    then
        DEVICE="$d"
        break
    fi
done

if [ -z "$DEVICE" ]
then
    echo "Mouse device not found"
    exit 1
fi

sudo "$CLICKER" run \
    -d "$DEVICE" \
    -l "$LEFT_BUTTON" \
    -c "$CLICK_INTERVAL"
