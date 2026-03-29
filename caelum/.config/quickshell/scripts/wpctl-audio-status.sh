#!/bin/sh

wpctl status | awk '
{
  line = $0
  gsub(/[│├└─]/, "", line)
  sub(/^[[:space:]]+/, "", line)
  if (line == "") next

  if (line == "Sinks:") {
    section = "sink"
    next
  }

  if (line == "Sources:") {
    section = "source"
    next
  }

  if (line == "Streams:") {
    section = "stream"
    next
  }

  if (line == "Devices:" || line == "Filters:" || line == "Clients:" ||
      line == "Settings" || line == "Default Configured Devices:" ||
      line == "Audio" || line == "Video") {
    section = ""
    next
  }

  if (section == "sink" || section == "source") {
    if (match(line, /^(\*)?[[:space:]]*([0-9]+)\.[[:space:]]+(.+)$/, m)) {
      id = m[2]
      name = m[3]
      sub(/[[:space:]]+\[vol:.*/, "", name)
      cmd = "wpctl get-volume " id " 2>/dev/null"
      volLine = ""
      cmd | getline volLine
      close(cmd)
      vol = 0
      if (match(volLine, /Volume:[[:space:]]*([0-9.]+)/, v)) {
        vol = int((v[1] + 0) * 100 + 0.5)
      }
      printf "%s|%s|%s|%s|%d\n", section, (m[1] == "*" ? 1 : 0), id, name, vol
    }
    next
  }

  if (section == "stream") {
    if (line ~ />/) next
    if (match(line, /^([0-9]+)\.[[:space:]]+(.+)$/, m)) {
      id = m[1]
      name = m[2]
      cmd = "wpctl get-volume " id " 2>/dev/null"
      volLine = ""
      cmd | getline volLine
      close(cmd)
      vol = 0
      if (match(volLine, /Volume:[[:space:]]*([0-9.]+)/, v)) {
        vol = int((v[1] + 0) * 100 + 0.5)
      }
      printf "stream|0|%s|%s|%d\n", id, name, vol
    }
  }
}
'
