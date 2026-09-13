#!/bin/bash
# Waybar module: GPU temperature + CPU/GPU fans.
#   - Compact display: GPU temp only (topbar stays clean).
#   - Hover tooltip: CPU fan RPM, GPU temp/fan/util/power/clock.
#
# Sensor paths are resolved by chip name so they survive reboot/hwmon renumbering:
#   - CPU temp: k10temp (Tctl)        -> sysfs, instant
#   - CPU fan: nct6797 (first non-zero fan*_input)
#   - GPU:      nvidia-smi (NVML)      -> the only reliable source on desktop GeForce
set -uo pipefail

# Locate a hwmon dir by chip name (e.g. "k10temp").
hwmon_dir() {
    local chip="$1" f
    for f in /sys/class/hwmon/hwmon*/name; do
        [[ "$(cat "$f" 2>/dev/null)" == "$chip" ]] && { dirname "$f"; return 0; }
    done
    return 1
}

# CPU temperature (k10temp Tctl) millidegrees -> degrees C.
cpu_temp() {
    local dir
    dir=$(hwmon_dir k10temp) || return 1
    awk -v t="$(cat "$dir/temp1_input" 2>/dev/null)" 'BEGIN{printf "%d", t/1000}'
}

# First non-zero CPU/case fan reading from the Nuvoton Super I/O.
cpu_fan_rpm() {
    local dir i rpm
    dir=$(hwmon_dir nct6797) || return 1
    for i in $(seq 1 6); do
        rpm=$(cat "$dir/fan${i}_input" 2>/dev/null)
        [[ -n "$rpm" && "$rpm" != "0" ]] && { echo "$rpm"; return 0; }
    done
    return 1
}

# CPU package power estimate for Ryzen 3700X (88 W PPT), no zenpower installed.
# Model: idle floor + linear term in (load% x avg clock / boost clock), clamped
# to PPT. Uses 1 s of /proc/stat; labeled as estimate in the tooltip.
cpu_power_est() {
    local s1 s2 u1 n1 i1 w1 u2 n2 i2 w2
    read -r _ u1 n1 _ i1 w1 _ _ <<<"$(grep '^cpu ' /proc/stat)"
    sleep 1
    read -r _ u2 n2 _ i2 w2 _ _ <<<"$(grep '^cpu ' /proc/stat)"
    local tot1=$((u1+n1+i1+w1)) tot2=$((u2+n2+i2+w2))
    local busy=$(( (u2-u1)+(n2-n1) )) dt=$(( tot2-tot1 ))
    (( dt <= 0 )) && dt=1
    local pct=$(( 100*busy/dt )); (( pct<0 )) && pct=0; (( pct>100 )) && pct=100
    local fsum=0 f v
    for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
        v=$(cat "$f" 2>/dev/null) || continue
        fsum=$((fsum+v))
    done
    local ncpu=$(nproc)
    local avg_mhz=$(( fsum/ncpu/1000 ))
    # 88 W PPT at 100% load at boost clock; ~12 W floor at idle clocks.
    awk -v p="$pct" -v m="$avg_mhz" -v mx="4400" 'BEGIN{
        base=12 + 76*(p/100)*(m/mx); if (base>88) base=88;
        printf "%d", base }'
}

# Build tooltip (Pango markup). Passed as args, printf-style is avoided to dodge quoting hell.
build_tooltip() {
    local cpu_fan="$1" cput="$2" gpu_temp="$3" gpu_fan="$4" util="$5" power="$6" clock="$7"
    local cpu_w="$8" total_w="$9"
    cat <<EOF
<tt><b><span color='#cba6f7'> CPU </span></b>   ${cpu_fan}   ${cput}°C   ~${cpu_w} W est
<b><span color='#89b4fa'> GPU </span></b>   ${gpu_temp}°C   ${gpu_fan}% fan   ${power} W

<b><span color='#a6e3a1'> Draw </span></b>
   GPU  : ${power} W (metered)
   CPU  : ~${cpu_w} W (estimated)
   Board+RAM+SSDs+fans: ~25 W
   Wall : ~${total_w} W (PSU ~88% eff.)</tt>
EOF
}

main() {
    # nvidia-smi CSV (noheader,nounits) -> "49,30,11,44.32,1777". Split on comma.
    local line
    line=$(nvidia-smi \
        --query-gpu=temperature.gpu,fan.speed,utilization.gpu,power.draw,clocks.current.graphics \
        --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')

    # Driver not loaded / no GPU -> show nothing rather than junk.
    if [[ -z "$line" ]]; then
        printf '{"text":"","tooltip":"GPU unavailable"}\n'
        return
    fi

    IFS=, read -r gpu_temp gpu_fan gpu_util gpu_power gpu_clock <<<"$line"

    local cput cpu_fan_str
    cput=$(cpu_temp 2>/dev/null || echo "?")
    local rpm; rpm=$(cpu_fan_rpm 2>/dev/null || true)
    if [[ -n "$rpm" ]]; then
        cpu_fan_str="CPU Fan : ${rpm} RPM"
    else
        cpu_fan_str="CPU Fan : —"
    fi

    # Total draw: GPU metered + CPU estimate + fixed overhead.
    local cpu_w total_w
    cpu_w=$(cpu_power_est)
    total_w=$(awk -v g="${gpu_power%.*}" -v c="$cpu_w" 'BEGIN{
        d=g+c+25; printf "%d", d/0.88 }')

    local tip
    tip=$(build_tooltip "$cpu_fan_str" "$cput" "$gpu_temp" "$gpu_fan" "$gpu_util" "$gpu_power" "$gpu_clock" "$cpu_w" "$total_w")

    # Bar text: just GPU temp. Color/threshold handled in CSS via class.
    local icon cls
    icon="󰢮"   # nf-md-monitor
    if (( $(printf '%d' "${gpu_temp%.*}" 2>/dev/null || echo 0) >= 80 )); then
        cls="critical"
    elif (( $(printf '%d' "${gpu_temp%.*}" 2>/dev/null || echo 0) >= 70 )); then
        cls="warn"
    else
        cls=""
    fi

    jq -nc --arg text "${icon}  ${gpu_temp}°C  󰾆 ${total_w}W" \
          --arg tooltip "$tip" \
          --arg cls "$cls" \
          '{text:$text, tooltip:$tooltip, class:$cls}'
}

main
