#!/usr/bin/env fish

# Get connected tablets/styluses
set -l tablets (hyprctl devices -j | jq -r '.tablets[].name')

if test -z "$tablets"
    notify-send "Stylus Configuration" "No drawing tablets or stylus devices detected." -u critical -i input-tablet
    exit 1
end

# If there is more than one tablet, let the user choose which one.
# Otherwise, auto-select the only one.
set -l target_tablet ""
if test (count $tablets) -eq 1
    set target_tablet $tablets[1]
else
    set -l tablet_choice (printf "%s\n" $tablets | fuzzel --dmenu --prompt="Select stylus/tablet device: ")
    if test -z "$tablet_choice"
        exit 1
    end
    set target_tablet $tablet_choice
end

# Get connected monitors
set -l monitors (hyprctl monitors -j | jq -r '.[] | "\(.name) (\(.model))"')

if test -z "$monitors"
    notify-send "Stylus Configuration" "No monitors detected." -u critical -i input-tablet
    exit 1
end

# We also add an option "None (Span all monitors)" to clear the mapping
set -l options "Span all monitors"
for m in $monitors
    set options $options $m
end

# Prompt the user using fuzzel to select the monitor
set -l monitor_choice (printf "%s\n" $options | fuzzel --dmenu --prompt="Map stylus to monitor: ")

if test -z "$monitor_choice"
    exit 1
end

set -l target_output ""
if test "$monitor_choice" = "Span all monitors"
    set target_output ""
else
    # Extract the monitor name (first word before the parenthesis)
    set target_output (string split " " -- $monitor_choice)[1]
end

# Update the user's config file
set -l tablet_conf "$HOME/.config/caelestia/hypr-tablet.conf"

# Create / overwrite the config file
if test -n "$target_output"
    echo "# Dynamic Stylus / Tablet Configuration
device {
    name = $target_tablet
    output = $target_output
}" > $tablet_conf
    # Apply immediately using hyprctl
    hyprctl keyword "device:$target_tablet:output" "$target_output"
    notify-send "Stylus Configuration" "Mapped '$target_tablet' to '$target_output'" -i input-tablet
else
    echo "# Dynamic Stylus / Tablet Configuration
# Stylus spans all monitors" > $tablet_conf
    # Clear mapping immediately by mapping to nothing or reloading
    hyprctl keyword "device:$target_tablet:output" ""
    hyprctl reload
    notify-send "Stylus Configuration" "Stylus '$target_tablet' reset to span all monitors" -i input-tablet
end
