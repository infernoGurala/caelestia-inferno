#!/usr/bin/env fish

if test (count $argv) -lt 2
    echo 'Wrong number of arguments. Usage: ./wsaction.fish <dispatcher> <workspace|delta>'
    exit 1
end

set -l action $argv[1]
set -l param $argv[2]

set -l active_ws (hyprctl activeworkspace -j | jq -r '.id')
if not string match -r '^[1-5]$' -- "$active_ws"
    set active_ws 1
end

switch $action
    case "workspace"
        if test $param -ge 1; and test $param -le 5
            hyprctl dispatch workspace $param
        end

    case "movetoworkspace"
        if test $param -ge 1; and test $param -le 5
            hyprctl dispatch movetoworkspace $param
        end

    case "workspace_relative"
        set -l target (math "$active_ws + $param")
        if test $target -lt 1
            set target 1
        else if test $target -gt 5
            set target 5
        end
        hyprctl dispatch workspace $target

    case "movetoworkspace_relative"
        set -l target (math "$active_ws + $param")
        if test $target -lt 1
            set target 1
        else if test $target -gt 5
            set target 5
        end
        hyprctl dispatch movetoworkspace $target
end
