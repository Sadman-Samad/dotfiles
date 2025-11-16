#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="galib-os"
iso_label="GALIBOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Galib OS - Omarchy-based Linux Distribution"
iso_application="Galib OS Live/Install Environment"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/root/install-arch.sh"]="0:0:755"
  ["/root/welcome.sh"]="0:0:755"
  ["/root/setup-omarchy.sh"]="0:0:755"
  ["/root/sync-dotfiles.sh"]="0:0:755"
  ["/root/auto-start-hyprland.sh"]="0:0:755"
  ["/root/install-aur-packages.sh"]="0:0:755"
  ["/root/dotfiles/install.sh"]="0:0:755"
  ["/root/dotfiles/stowup"]="0:0:755"
  ["/root/dotfiles/stowDown"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/deploy-dotfiles"]="0:0:755"
  ["/usr/local/bin/omarchy-launch-*"]="0:0:755"
)
