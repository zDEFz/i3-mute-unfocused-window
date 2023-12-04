#!/bin/bash

# shellcheck disable=SC1090
source ~/.config/i3/mutelist.conf

declare -A entry_map
declare entries

for entry in "${entries[@]}"; do
  IFS=',' read -ra parts <<< "$entry"
  entry_map[${parts[0]}]=${parts[1]}
done

prev_class=""

while true; do
  cur=$(xdotool getwindowfocus getwindowclassname)
  if [[ "$cur" != "$prev_class" ]]; then
    # matched=false
    search_term=""

    for entry in "${!entry_map[@]}"; do
      regex="${entry_map[$entry]}"
      if [[ "$cur" =~ $regex ]]; then
        search_term="$entry"
        break
      fi
    done

    if [ -n "$search_term" ]; then
      input_number=$(pactl list sink-inputs | awk -v term="$search_term" '/Sink Input/ {sink_input = $3} $0 ~ "application.name = \"" term "\"" {gsub("#", "", sink_input); print sink_input;}')
      pactl set-sink-input-mute "$input_number" 0
      # matched=true
    else
      for entry in "${!entry_map[@]}"; do
        input_number=$(pactl list sink-inputs | awk -v term="$entry" '/Sink Input/ {sink_input = $3} $0 ~ "application.name = \"" term "\"" {gsub("#", "", sink_input); print sink_input;}')
        echo "    Disabling audio for unmatched condition: $input_number"
        pactl set-sink-input-mute "$input_number" 1
      done
    fi

    prev_class="$cur"
  fi
  sleep 3
done
