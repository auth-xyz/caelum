#!/bin/sh

mic_apps=$(
    pactl list source-outputs 2>/dev/null | awk '
        /application\.name = "/ {
            if (match($0, /"([^"]+)"/, m) && !(m[1] in seen)) {
                seen[m[1]] = 1
                names[++count] = m[1]
            }
        }
        END {
            for (i = 1; i <= count; i++) {
                printf "%s%s", names[i], (i < count ? ", " : "")
            }
        }
    '
)

screen_apps=""

if command -v jq >/dev/null 2>&1; then
    screen_apps=$(
        pw-dump 2>/dev/null | jq -r '
            . as $all
            | ($all
                | map(select(.type == "PipeWire:Interface:Client"))
                | map({key: (.id | tostring), value: (.info.props // {})})
                | from_entries) as $clients
            | ($all
                | map(select(.type == "PipeWire:Interface:Node"))
                | map({key: (.id | tostring), value: (.info.props // {})})
                | from_entries) as $nodes
            | ($nodes
                | to_entries
                | map(select(
                    ((.value["media.class"] // "") | test("^Video/"))
                    and (
                        ((.value["application.name"] // "") | test("^xdg-desktop-portal"))
                        or ((.value["application.process.binary"] // "") | test("^xdg-desktop-portal"))
                        or ((.value["node.name"] // "") | test("xdpw|screencast|screen|portal"; "i"))
                        or ((.value["node.description"] // "") | test("screen|capture|portal"; "i"))
                    )
                ))
                | map(.key)) as $portalNodes
            | if ($portalNodes | length) == 0 then
                empty
              else
                $all
                | map(select(.type == "PipeWire:Interface:Link"))
                | map(.info.props // {})
                | map(select(
                    ($portalNodes | index((.["link.output.node"] | tostring))) != null
                    or ($portalNodes | index((.["link.input.node"] | tostring))) != null
                ))
                | map(
                    if ($portalNodes | index((.["link.output.node"] | tostring))) != null
                    then (.["link.input.node"] | tostring)
                    else (.["link.output.node"] | tostring)
                    end
                )
                | unique
                | map($nodes[.] // {})
                | map(
                    ($clients[((.["client.id"] // "") | tostring)]["application.name"])
                    // (.["application.name"])
                    // ($clients[((.["client.id"] // "") | tostring)]["application.process.binary"])
                    // (.["application.process.binary"])
                    // empty
                )
                | map(select(
                    . != ""
                    and (. | test("^(WirePlumber|WirePlumber \\[export\\]|pipewire|quickshell|xdg-desktop-portal|xdg-desktop-portal-hyprland)$") | not)
                ))
                | unique
                | .[]
              end
        ' | awk '
            NF {
                if (count++) printf ", "
                printf "%s", $0
            }
            END {
                if (count) print ""
            }
        '
    )
fi

if [ -z "$screen_apps" ]; then
    session_count=$(busctl --user tree org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop/session 2>/dev/null | awk 'NR > 1 { count++ } END { print count + 0 }')
    if [ "${session_count:-0}" -gt 0 ]; then
        screen_apps="Portal session"
    fi
fi

if [ -n "$mic_apps" ]; then
    mic_active=1
else
    mic_active=0
    mic_apps="Idle"
fi

if [ -n "$screen_apps" ]; then
    share_active=1
else
    share_active=0
    screen_apps="Idle"
fi

printf 'mic|%s|%s\n' "$mic_active" "$mic_apps"
printf 'share|%s|%s\n' "$share_active" "$screen_apps"
