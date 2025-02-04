# base-desktop.ks
#
# Defines the basics for a basic desktop environment.
#services --disabled=openvpn-server@\\x2a,openvpn-server@\x2a

%packages

# Common modules (see fedora-workstation-common.ks)
@base-x
@core
@hardware-support
bash-completion
bind-utils
btrfs-progs
microcode_ctl
psmisc
# Multimedia
@multimedia
libva-vdpau-driver
libvdpau-va-gl
mesa-*-drivers
xorg-x11-drivers
#akmod-nvidia # NVIDIA drivers because nouveau isnt loading for some reason

#nouveau-firmware
xorg-x11-drv-nouveau

# Fonts
google-noto-sans-fonts
google-noto-sans-mono-fonts
google-noto-serif-fonts
@fonts
-google-noto-emoji-color-fonts
# We like Twemoji
twitter-twemoji-fonts
liberation-mono-fonts
liberation-s*-fonts
cascadia-*-*-fonts

# Networking
@networkmanager-submodules
firewalld
firewall-config

# Internet
firefox
-fedora-bookmarks
#mozilla-openh264
# Software
PackageKit
PackageKit-gstreamer-plugin
PackageKit-command-not-found
xdg-desktop-portal
# deltarpm
dnf-plugins-core
# drpm
flatpak
flatpak-selinux-fix

# System
rpm-plugin-systemd-inhibit

# Tools
blivet-gui			# Storage management
exfatprogs
htop
rsync
unar
git

# The rice
ultramarine-shell-config

%end


%post



# Antialiasing by default.
# Set Noto fonts as preferred family.
cat > /etc/fonts/local.conf << EOF_FONTS
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>

<!-- Settins for better font rendering -->
<match target="font">
	<edit mode="assign" name="rgba"><const>rgb</const></edit>
	<edit mode="assign" name="hinting"><bool>true</bool></edit>
	<edit mode="assign" name="hintstyle"><const>hintfull</const></edit>
	<edit mode="assign" name="antialias"><bool>true</bool></edit>
	<edit mode="assign" name="lcdfilter"><const>lcddefault</const></edit>
</match>

<!-- Local default fonts -->
<!-- Serif faces -->
	<alias>
		<family>serif</family>
		<prefer>
			<family>Noto Serif</family>
			<family>DejaVu Serif</family>
			<family>Liberation Serif</family>
		</prefer>
	</alias>
<!-- Sans-serif faces -->
	<alias>
		<family>sans-serif</family>
		<prefer>
			<family>Noto Sans</family>
			<family>DejaVu Sans</family>
			<family>Liberation Sans</family>
		</prefer>
	</alias>
<!-- Monospace faces -->
	<alias>
		<family>monospace</family>
		<prefer>
			<family>Cascadia Code PL</family>
			<family>Noto Sans Mono</family>
			<family>DejaVu Sans Mono</family>
			<family>Liberation Mono</family>
		</prefer>
	</alias>
</fontconfig>
EOF_FONTS

# Sets a default grub config if not present (rhb #886502)
# Provides some reasonable defaults when the bootloader is not installed
if [ ! -f "/etc/default/grub" ]; then
cat > /etc/default/grub << EOF_DEFAULT_GRUB
GRUB_TIMEOUT=3
GRUB_DISTRIBUTOR="\$(sed 's, release .*\$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_CMDLINE_LINUX="rd.md=0 rd.dm=0 rd.luks=0 inst.profile=ultramarine rhgb quiet"
GRUB_DISABLE_RECOVERY=false
# GRUB_DISABLE_OS_PROBER=true
EOF_DEFAULT_GRUB
fi

# Disable weak dependencies to avoid unwanted stuff
echo "install_weak_deps=False" >> /etc/dnf/dnf.conf
cat >> /etc/dnf/dnf.conf << EOF
install_weak_deps=False
defaultyes=True
max_parallel_downloads=20

EOF

# Set default boot theme
#fails because no command, it works without this anyway
#plymouth-set-default-theme spinner
# disabled again so we get back EFI logos

%end
