LOW_BATTERY_THRESHOLD=10

while true; do
    battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')
    charging_status=$(acpi -b | grep -oP 'Charging|Discharging')

    if [ "$battery_level" -lt "$LOW_BATTERY_THRESHOLD" ] && [ "$charging_status" == "Discharging" ]; then
        notify-send "󰂃 Low Battery Warning" "Your battery is at $battery_level%. Please plug in your charger."
    fi

    sleep 120
done
