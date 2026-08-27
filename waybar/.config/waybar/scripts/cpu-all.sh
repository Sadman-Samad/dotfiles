#!/bin/bash
# Waybar module: CPU usage — bar shows usage + Tctl; hover tooltip carries
# everything: model/topology, per-core load % + SMT thread bars + per-core
# frequency, clocks, governor, fan, and all temps (board, NVMe, SATA).
set -uo pipefail

# --- Load sample: /proc/stat deltas, 250 ms apart ------------------------------
mapfile -t s1 < <(grep '^cpu[0-9]' /proc/stat)
sleep 0.25
mapfile -t s2 < <(grep '^cpu[0-9]' /proc/stat)
ncpu=${#s1[@]}
blocks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
pcts=() core_bars=() usage_sum=0 freqs=()

# Per-logical-CPU frequency (kHz), same index order as /proc/stat.
for ((i = 0; i < ncpu; i++)); do
    f=$(cat "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_cur_freq" 2>/dev/null) || f=0
    freqs+=("$f")
done

for ((i = 0; i < ncpu; i++)); do
    read -r _ u1 n1 s1_ i1 w1 q1 o1 _ <<<"${s1[i]}"
    read -r _ u2 n2 s2_ i2 w2 q2 o2 _ <<<"${s2[i]}"
    tot1=$((u1+n1+s1_+i1+w1+q1+o1)); tot2=$((u2+n2+s2_+i2+w2+q2+o2))
    busy=$((tot2-tot1-(i2-i1)-(w2-w1))); dt=$((tot2-tot1)); (( dt <= 0 )) && dt=1
    pct=$((100*busy/dt)); (( pct<0 )) && pct=0; (( pct>100 )) && pct=100
    pcts+=("$pct"); usage_sum=$((usage_sum+pct))
    core_bars+=("${blocks[pct*7/100]}")
done
usage=$((usage_sum/ncpu))

# --- Model + topology -----------------------------------------------------------
model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//; s/ Processor//; s/AMD //')
smt=$(lscpu | awk -F: '/Thread\(s\) per core/{gsub(/ /,"",$2); print $2}')
cores=$((ncpu / smt))

# --- Clocks ---------------------------------------------------------------------
freq_sum=0 freq_peak=0
for v in "${freqs[@]}"; do freq_sum=$((freq_sum+v)); (( v > freq_peak )) && freq_peak=$v; done
avg_ghz=$(awk -v s="$freq_sum" -v n="$ncpu" 'BEGIN{printf "%.2f", s/n/1e6}')
peak_ghz=$(awk -v p="$freq_peak" 'BEGIN{printf "%.2f", p/1e6}')
boost_ghz=$(awk -v b="$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 0)" \
    'BEGIN{printf "%.2f", b/1e6}')
gov=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null) || gov="?"
epp=$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null) || epp=""
drv=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_driver 2>/dev/null) || drv="?"

# --- Per-core rows: id  thread-bars  load%  freq (2 cores per line) --------------
# Physical core c owns logical CPUs 2c and 2c+1. Load = max of the SMT pair
# (a core is as busy as its busiest thread); freq = avg of the pair.
core_rows=()
for ((c = 0; c < cores; c++)); do
    a=$((c*2)); b=$((c*2+1))
    load=$((( pcts[a] > pcts[b] ) ? pcts[a] : pcts[b]))
    cf=$(awk -v x="${freqs[a]}" -v y="${freqs[b]}" 'BEGIN{printf "%.1f", (x+y)/2/1e6}')
    core_rows+=("$(printf '%x %s%s %3d%% %4sG' "$c" "${core_bars[a]}" "${core_bars[b]}" "$load" "$cf")")
done
row1=""; for ((c = 0; c < cores; c += 2)); do row1+="${core_rows[c]}   "; done
row2=""; for ((c = 1; c < cores; c += 2)); do row2+="${core_rows[c]}   "; done

# --- Temps (chips resolved by name) ---------------------------------------------
hwmon_dir() {
    local chip="$1" f
    for f in /sys/class/hwmon/hwmon*/name; do
        [[ "$(cat "$f" 2>/dev/null)" == "$chip" ]] && { dirname "$f"; return 0; }
    done
    return 1
}
rt() { local v; v=$(cat "$1/$2_input" 2>/dev/null) || return 1; awk -v t="$v" 'BEGIN{printf "%d", t/1000}'; }

cpu_dir=$(hwmon_dir k10temp) || cpu_dir=""
tctl=$(rt "$cpu_dir" temp1) || tctl="—"
tccd=$(rt "$cpu_dir" temp3) || tccd="—"
mb_dir=$(hwmon_dir nct6797) || mb_dir=""
cputin=$(rt "$mb_dir" temp2) || cputin="—"
systin=$(rt "$mb_dir" temp1) || systin="—"
nvme_dir=$(hwmon_dir nvme) || nvme_dir=""
if [[ -n "$nvme_dir" ]]; then
    nvm=$(rt "$nvme_dir" temp1) || nvm="—"
    nvm_crit=$(awk -v t="$(cat "$nvme_dir/temp1_crit" 2>/dev/null || echo 0)" 'BEGIN{printf "%d", t/1000}')
else
    nvm="—"; nvm_crit="—"
fi
sata=$(busctl get-property org.freedesktop.UDisks2 \
    /org/freedesktop/UDisks2/drives/T_FORCE_512GB_TPBF2410210010101837 \
    org.freedesktop.UDisks2.Drive.Ata SmartTemperature 2>/dev/null \
    | awk '{k=$2+0; if (k<200) exit 1; printf "%d", k-273.15}') || sata="—"

# --- CPU fan (nct6797, first non-zero) ------------------------------------------
fan_rpm="—"
[[ -n "$mb_dir" ]] && for i in 1 2 3 4 5 6; do
    r=$(cat "$mb_dir/fan${i}_input" 2>/dev/null)
    [[ -n "$r" && "$r" != "0" ]] && { fan_rpm="$r rpm"; break; }
done

tip=$(cat <<EOF
<tt><b><span color='#fab387'> ${model} </span></b>  ${cores}C/${ncpu}T
 Usage  ${usage}%   avg ${avg_ghz} GHz   peak ${peak_ghz} GHz
 Boost  ${boost_ghz} GHz   ${drv} ${gov}/${epp}
 Temps  Tctl ${tctl}°C   Tccd1 ${tccd}°C   Fan ${fan_rpm}

 <b><span color='#fab387'>Core  Th  Load Freq</span></b>
 ${row1}
 ${row2}

<b><span color='#94e2d5'> Board </span></b>  CPUTIN ${cputin}°C   SYSTIN ${systin}°C
<b><span color='#89dceb'> SSD </span></b>   NVMe ${nvm}°C (crit ${nvm_crit}°C)   SATA ${sata}°C
<b><span color='#cba6f7'> RAM </span></b>   no temp sensor</tt>
EOF
)

cls=""
[[ "$tctl" =~ ^[0-9]+$ ]] && (( tctl >= 80 )) && cls="critical"

jq -nc --arg text "  ${usage}%  󰔏 ${tctl}°C" \
      --arg tooltip "$tip" \
      --arg cls "$cls" \
      '{text:$text, tooltip:$tooltip, class:$cls}'
