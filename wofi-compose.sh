#!/bin/zsh

# @brief Ultra Flow-search: Root scope, case-insensitive, enhanced App/Bin detection
# @return void
flow_pretty_search() {
    # Define app and binary directories
    local desktop_dirs=("/usr/share/applications" "$HOME/.local/share/applications")
    
    # Fetch names from desktop files and bins
    local names=$(grep -rih "^Name=" "${desktop_dirs[@]}" 2>/dev/null | cut -d'=' -f2- | sort -f -u)
    local bins=$(ls /usr/bin | grep -Ei "^(code|vlc|chrome|firefox|steam|discord|obs|snapshot|cheese)")

    # Combine list and add UI prefix
    local apps_list=$(echo -e "$names\n$bins" | sort -f -u | sed 's/^/> /')

    # Launch main UI window with wofi case-insensitive flag (-i)
    local selected=$(echo "$apps_list" | wofi -i --dmenu --normal-window \
        --style "$HOME/.config/wofi/style.css" \
        --prompt "Search Everything (Case-Insensitive)..." \
        --width 600 --height 400)

    # Exit if no selection is made
    if [ -z "$selected" ]; then {
        return
    }
    fi

    # Handle App launch or file fallback
    if [[ "$selected" == "> "* ]]; then {
        local query="${selected#"> "}"

        # Exact match for desktop file case-insensitively
        local desktop_path=$(grep -ril "^Name=$query$" "${desktop_dirs[@]}" 2>/dev/null | head -n 1)

        # Launch desktop app
        if [ -n "$desktop_path" ]; then {
            gtk-launch "$(basename "$desktop_path")"
        }
        else {
            # Check if it is a binary command
            local binary_cmd=$(ls /usr/bin | grep -ix "$query" | head -n 1)
            
            # Launch binary or fallback to xdg-open
            if [ -n "$binary_cmd" ]; then {
                nohup "$binary_cmd" >/dev/null 2>&1 &
            }
            else {
                xdg-open "$query"
            }
            fi
        }
        fi
    }
    else {
        # Deep search in root scope with case-insensitive plocate (-i), grep (-viE), and wofi (-i)
        local file_choice=$(plocate -i "$selected" | \
            grep -viE "/(\.git|\.cache|\.local|proc|sys|dev|run|snap|var/lib/docker)/" | \
            head -n 1000 | \
            wofi -i --dmenu --normal-window \
            --style "$HOME/.config/wofi/style.css" \
            --prompt "Root Files: $selected" \
            --width 900 --height 600)

        # Open selected file
        if [ -n "$file_choice" ]; then {
            xdg-open "$file_choice"
        }
        fi
    }
    fi
}

# @brief Entry point of the script
# @return void
main() {
    # Initiate flow search
    flow_pretty_search
}

main