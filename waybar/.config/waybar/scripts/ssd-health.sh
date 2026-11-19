#!/bin/bash
# Pango section for the CPU tooltip: SSD lifetime + health via UDisks2 SMART.
# No root needed. SMART changes slowly, so results are cached for 5 minutes.
set -uo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/ssd-smart.cache"
TTL=300
if [[ "${1:-}" != "--refresh" && -f "$CACHE" ]] &&
    (( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) < TTL )); then
    cat "$CACHE"
    exit 0
fi

drive_path() {
    udisksctl info -b "$1" 2>/dev/null |
        sed -n "s/^ *Drive: *'\(.*\)'/\1/p" | head -1
}

is_nvme() {
    busctl introspect org.freedesktop.UDisks2 "$1" 2>/dev/null |
        grep -q 'org.freedesktop.UDisks2.NVMe.Controller'
}

prop() {  # $1=object $2=interface $3=property
    busctl --json=short get-property org.freedesktop.UDisks2 "$1" "$2" "$3" 2>/dev/null |
        jq -r '.data // empty' 2>/dev/null
}

tb()    { awk -v b="${1:-0}" 'BEGIN{printf "%.1f", b/1e12}'; }
tempc() { awk -v k="${1:-0}" 'BEGIN{printf "%d", k-273.15}'; }

nvme_body="" sata_body=""

while read -r name tran type; do
    [[ "$type" == "disk" && ( "$tran" == "nvme" || "$tran" == "sata" ) ]] || continue
    dev="/dev/$name"
    obj=$(drive_path "$dev") || continue
    [[ -n "$obj" ]] || continue
    model=$(lsblk -dno MODEL "$dev" 2>/dev/null | sed 's/ *$//')

    if is_nvme "$obj"; then
        iface=org.freedesktop.UDisks2.NVMe.Controller
        attrs=$(busctl --json=short call org.freedesktop.UDisks2 "$obj" "$iface" \
            SmartGetAttributes 'a{sv}' 0 2>/dev/null) || attrs=""
        av() { jq -r --arg k "$1" '.data[0][$k].data // empty' <<<"$attrs" 2>/dev/null; }

        used=$(av percent_used)
        written=$(av total_data_written)
        media=$(av media_errors)
        hours=$(prop "$obj" "$iface" SmartPowerOnHours)
        tempk=$(prop "$obj" "$iface" SmartTemperature)
        warn=$(busctl --json=short get-property org.freedesktop.UDisks2 "$obj" "$iface" \
            SmartCriticalWarning 2>/dev/null | jq -r '.data | length' 2>/dev/null)

        if [[ "$used" =~ ^[0-9]+$ ]]; then
            life=$((100 - used))
            (( life <= 10 )) && life="<span color='#f38ba8'>${life}%</span>" || life="${life}%"
        else
            life="n/a"
        fi
        health="OK"
        [[ "$warn" =~ ^[0-9]+$ ]] && (( warn > 0 )) && health="<span color='#f38ba8'>WARN</span>"
        [[ "$media" =~ ^[0-9]+$ ]] && (( media > 0 )) && health="<span color='#f38ba8'>WARN</span>"

        nvme_body="${model} · $(tempc "${tempk:-0}")°C · ${life} life · $(tb "$written") TB written · ${hours:-?} h · ${health}"
    else
        iface=org.freedesktop.UDisks2.Drive.Ata
        failing=$(prop "$obj" "$iface" SmartFailing)
        bad=$(prop "$obj" "$iface" SmartNumBadSectors)
        secs=$(prop "$obj" "$iface" SmartPowerOnSeconds)
        tempk=$(prop "$obj" "$iface" SmartTemperature)
        attrs=$(busctl --json=short call org.freedesktop.UDisks2 "$obj" "$iface" \
            SmartGetAttributes 'a{sv}' 0 2>/dev/null) || attrs=""
        life=$(jq -r '([.data[0][] | select(.[1] | test("life|wear|percent"))][0] // []) | .[3] // empty' \
            <<<"$attrs" 2>/dev/null)
        hours=$(( ${secs:-0} / 3600 ))

        health="OK"
        [[ "$failing" == "true" ]] && health="<span color='#f38ba8'>FAIL</span>"
        [[ "$bad" =~ ^[0-9]+$ ]] && (( bad > 0 )) && health="<span color='#f38ba8'>WARN</span>"
        if [[ "$life" =~ ^[0-9]+$ ]]; then
            (( life <= 10 )) && life="<span color='#f38ba8'>${life}%</span>" || life="${life}%"
        else
            life="n/a"
        fi

        sata_body="${model} · $(tempc "${tempk:-0}")°C · life ${life} · ${bad:-?} bad sectors · ${hours} h · ${health}"
    fi
done < <(lsblk -dno NAME,TRAN,TYPE 2>/dev/null)

lines=()
[[ -n "$nvme_body" ]] && lines+=("<b><span color='#89dceb'> NVMe </span></b>  ${nvme_body}")
[[ -n "$sata_body" ]] && lines+=("<b><span color='#a6e3a1'> SATA </span></b>  ${sata_body}")

if (( ${#lines[@]} == 0 )); then
    echo "<b><span color='#89dceb'> SSD </span></b>   no SMART data"
    exit 0
fi

out=$(printf '%s\n' "${lines[@]}")
out=${out%$'\n'}

mkdir -p "$(dirname "$CACHE")"
printf '%s\n' "$out" | tee "$CACHE"
