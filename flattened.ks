# Generated by pykickstart v3.32
#version=DEVEL
# X Window System configuration information
xconfig  --startxonboot
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --iscrypted --lock locked
# System language
lang en_US.UTF-8
# Shutdown after installation
shutdown
# Network information
network  --bootproto=dhcp --device=link --activate
# System authorization information
auth --useshadow --passalgo=sha512
# Firewall configuration
firewall --enabled --service=mdns
# Use network installation
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch"
repo --name="fedora" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name="updates" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch
repo --name="ultramarine" --baseurl=https://download.copr.fedorainfracloud.org/results/cappyishihara/ultramarine/fedora-$releasever-$basearch/
repo --name="fedora-cisco-openh264" --baseurl=https://codecs.fedoraproject.org/openh264/$releasever/$basearch/os/
repo --name="copr:copr.fedorainfracloud.org:cappyishihara:cyber-desktop" --baseurl=https://download.copr.fedorainfracloud.org/results/cappyishihara/cyber-desktop/fedora-$releasever-$basearch/
repo --name="copr:copr.fedorainfracloud.org:cappyishihara:cyber-desktop-testing" --baseurl=https://download.copr.fedorainfracloud.org/results/cappyishihara/cyber-desktop-testing/fedora-$releasever-$basearch/
# System timezone
timezone US/Eastern
# SELinux configuration
selinux --enforcing
# System services
services --disabled="sshd" --enabled="NetworkManager,ModemManager"
# System bootloader configuration
bootloader --location=none
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all
# Disk partitioning information
part / --fstype="ext4" --size=8192

%post
# FIXME: it'd be better to get this installed from a package
cat > /etc/rc.d/init.d/livesys << EOF
#!/bin/bash
#
# live: Init script for live image
#
# chkconfig: 345 00 99
# description: Init script for live image.
### BEGIN INIT INFO
# X-Start-Before: display-manager chronyd
### END INIT INFO

. /etc/init.d/functions

if ! strstr "\`cat /proc/cmdline\`" rd.live.image || [ "\$1" != "start" ]; then
    exit 0
fi

if [ -e /.liveimg-configured ] ; then
    configdone=1
fi

exists() {
    which \$1 >/dev/null 2>&1 || return
    \$*
}

livedir="LiveOS"
for arg in \`cat /proc/cmdline\` ; do
  if [ "\${arg##rd.live.dir=}" != "\${arg}" ]; then
    livedir=\${arg##rd.live.dir=}
    continue
  fi
  if [ "\${arg##live_dir=}" != "\${arg}" ]; then
    livedir=\${arg##live_dir=}
  fi
done

# enable swaps unless requested otherwise
swaps=\`blkid -t TYPE=swap -o device\`
if ! strstr "\`cat /proc/cmdline\`" noswap && [ -n "\$swaps" ] ; then
  for s in \$swaps ; do
    action "Enabling swap partition \$s" swapon \$s
  done
fi
if ! strstr "\`cat /proc/cmdline\`" noswap && [ -f /run/initramfs/live/\${livedir}/swap.img ] ; then
  action "Enabling swap file" swapon /run/initramfs/live/\${livedir}/swap.img
fi

mountPersistentHome() {
  # support label/uuid
  if [ "\${homedev##LABEL=}" != "\${homedev}" -o "\${homedev##UUID=}" != "\${homedev}" ]; then
    homedev=\`/sbin/blkid -o device -t "\$homedev"\`
  fi

  # if we're given a file rather than a blockdev, loopback it
  if [ "\${homedev##mtd}" != "\${homedev}" ]; then
    # mtd devs don't have a block device but get magic-mounted with -t jffs2
    mountopts="-t jffs2"
  elif [ ! -b "\$homedev" ]; then
    loopdev=\`losetup -f\`
    if [ "\${homedev##/run/initramfs/live}" != "\${homedev}" ]; then
      action "Remounting live store r/w" mount -o remount,rw /run/initramfs/live
    fi
    losetup \$loopdev \$homedev
    homedev=\$loopdev
  fi

  # if it's encrypted, we need to unlock it
  if [ "\$(/sbin/blkid -s TYPE -o value \$homedev 2>/dev/null)" = "crypto_LUKS" ]; then
    echo
    echo "Setting up encrypted /home device"
    plymouth ask-for-password --command="cryptsetup luksOpen \$homedev EncHome"
    homedev=/dev/mapper/EncHome
  fi

  # and finally do the mount
  mount \$mountopts \$homedev /home
  # if we have /home under what's passed for persistent home, then
  # we should make that the real /home.  useful for mtd device on olpc
  if [ -d /home/home ]; then mount --bind /home/home /home ; fi
  [ -x /sbin/restorecon ] && /sbin/restorecon /home
  if [ -d /home/liveuser ]; then USERADDARGS="-M" ; fi
}

findPersistentHome() {
  for arg in \`cat /proc/cmdline\` ; do
    if [ "\${arg##persistenthome=}" != "\${arg}" ]; then
      homedev=\${arg##persistenthome=}
    fi
  done
}

if strstr "\`cat /proc/cmdline\`" persistenthome= ; then
  findPersistentHome
elif [ -e /run/initramfs/live/\${livedir}/home.img ]; then
  homedev=/run/initramfs/live/\${livedir}/home.img
fi

# if we have a persistent /home, then we want to go ahead and mount it
if ! strstr "\`cat /proc/cmdline\`" nopersistenthome && [ -n "\$homedev" ] ; then
  action "Mounting persistent /home" mountPersistentHome
fi

if [ -n "\$configdone" ]; then
  exit 0
fi

# add liveuser user with no passwd
action "Adding live user" useradd \$USERADDARGS -c "Live System User" liveuser
passwd -d liveuser > /dev/null
usermod -aG wheel liveuser > /dev/null

# Remove root password lock
passwd -d root > /dev/null

# turn off firstboot for livecd boots
systemctl --no-reload disable firstboot-text.service 2> /dev/null || :
systemctl --no-reload disable firstboot-graphical.service 2> /dev/null || :
systemctl stop firstboot-text.service 2> /dev/null || :
systemctl stop firstboot-graphical.service 2> /dev/null || :

# don't use prelink on a running live image
sed -i 's/PRELINKING=yes/PRELINKING=no/' /etc/sysconfig/prelink &>/dev/null || :

# turn off mdmonitor by default
systemctl --no-reload disable mdmonitor.service 2> /dev/null || :
systemctl --no-reload disable mdmonitor-takeover.service 2> /dev/null || :
systemctl stop mdmonitor.service 2> /dev/null || :
systemctl stop mdmonitor-takeover.service 2> /dev/null || :

# don't enable the gnome-settings-daemon packagekit plugin
gsettings set org.gnome.software download-updates 'false' || :

# don't start cron/at as they tend to spawn things which are
# disk intensive that are painful on a live image
systemctl --no-reload disable crond.service 2> /dev/null || :
systemctl --no-reload disable atd.service 2> /dev/null || :
systemctl stop crond.service 2> /dev/null || :
systemctl stop atd.service 2> /dev/null || :

# turn off abrtd on a live image
systemctl --no-reload disable abrtd.service 2> /dev/null || :
systemctl stop abrtd.service 2> /dev/null || :

# Don't sync the system clock when running live (RHBZ #1018162)
sed -i 's/rtcsync//' /etc/chrony.conf

# Mark things as configured
touch /.liveimg-configured

# add static hostname to work around xauth bug
# https://bugzilla.redhat.com/show_bug.cgi?id=679486
# the hostname must be something else than 'localhost'
# https://bugzilla.redhat.com/show_bug.cgi?id=1370222
echo "localhost-live" > /etc/hostname

EOF

# bah, hal starts way too late
cat > /etc/rc.d/init.d/livesys-late << EOF
#!/bin/bash
#
# live: Late init script for live image
#
# chkconfig: 345 99 01
# description: Late init script for live image.

. /etc/init.d/functions

if ! strstr "\`cat /proc/cmdline\`" rd.live.image || [ "\$1" != "start" ] || [ -e /.liveimg-late-configured ] ; then
    exit 0
fi

exists() {
    which \$1 >/dev/null 2>&1 || return
    \$*
}

touch /.liveimg-late-configured

# read some variables out of /proc/cmdline
for o in \`cat /proc/cmdline\` ; do
    case \$o in
    ks=*)
        ks="--kickstart=\${o#ks=}"
        ;;
    xdriver=*)
        xdriver="\${o#xdriver=}"
        ;;
    esac
done

# if liveinst or textinst is given, start anaconda
if strstr "\`cat /proc/cmdline\`" liveinst ; then
   plymouth --quit
   /usr/sbin/liveinst \$ks
fi
if strstr "\`cat /proc/cmdline\`" textinst ; then
   plymouth --quit
   /usr/sbin/liveinst --text \$ks
fi

# configure X, allowing user to override xdriver
if [ -n "\$xdriver" ]; then
   cat > /etc/X11/xorg.conf.d/00-xdriver.conf <<FOE
Section "Device"
	Identifier	"Videocard0"
	Driver	"\$xdriver"
EndSection
FOE
fi

EOF

chmod 755 /etc/rc.d/init.d/livesys
/sbin/restorecon /etc/rc.d/init.d/livesys
/sbin/chkconfig --add livesys

chmod 755 /etc/rc.d/init.d/livesys-late
/sbin/restorecon /etc/rc.d/init.d/livesys-late
/sbin/chkconfig --add livesys-late

# enable tmpfs for /tmp
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
# note https://bugzilla.redhat.com/show_bug.cgi?id=1135475
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' --whatprovides system-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
echo "Packages within this LiveCD"
rpm -qa
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
/usr/bin/mandb

# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# convince readahead not to collect
# FIXME: for systemd

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Drop the rescue kernel and initramfs, we don't need them on the live media itself.
# See bug 1317709
rm -f /boot/*-rescue*

# Disable network service here, as doing it in the services line
# fails due to RHBZ #1369794
/sbin/chkconfig network off

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

%end

%post --nochroot
cp $INSTALL_ROOT/usr/share/licenses/*-release/* $LIVE_ROOT/

# only works on x86, x86_64
if [ "$(uname -i)" = "i386" -o "$(uname -i)" = "x86_64" ]; then
    # For livecd-creator builds
    if [ ! -d $LIVE_ROOT/LiveOS ]; then mkdir -p $LIVE_ROOT/LiveOS ; fi
    cp /usr/bin/livecd-iso-to-disk $LIVE_ROOT/LiveOS

    # For lorax/livemedia-creator builds
    sed -i '
    /## make boot.iso/ i\
    # Add livecd-iso-to-disk script to .iso filesystem at /LiveOS/\
    <% f = "usr/bin/livecd-iso-to-disk" %>\
    %if exists(f):\
        install ${f} ${LIVEDIR}/${f|basename}\
    %endif\
    ' /usr/share/lorax/templates.d/99-generic/live/x86.tmpl
fi

#Anaconda Config files for Ultramarine
cat << 'EOF' > /etc/anaconda/product.d/ultramarine.conf
# Anaconda configuration file for Fedora Workstation Live.

[Product]
product_name = Ultramarine Linux

[Base Product]
product_name = Fedora
variant_name = Workstation

[User Interface]

EOF



%end

%post


# set default GTK+ theme for root (see #683855, #689070, #808062)
cat > /root/.gtkrc-2.0 << EOF
include "/usr/share/themes/Adwaita/gtk-2.0/gtkrc"
include "/etc/gtk-2.0/gtkrc"
gtk-theme-name="Adwaita"
EOF
mkdir -p /root/.config/gtk-3.0
cat > /root/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name = Adwaita
EOF

# add initscript
cat >> /etc/rc.d/init.d/livesys << ALLEOF

# set up autologin for user liveuser
if [ -f /etc/sddm.conf ]; then
sed -i 's/^#User=.*/User=liveuser/' /etc/sddm.conf
sed -i 's/^#Session=.*/Session=cyber-xsession.desktop/' /etc/sddm.conf
else
cat > /etc/sddm.conf << SDDM_EOF
[Autologin]
User=liveuser
Session=cyber-xsession.desktop
[Theme]
Current=materia
SDDM_EOF
fi

##Configuration
#Create Liveuser dir
mkdir -p /home/liveuser/.config/cyberos
mkdir -p /home/liveuser/.config/
mkdir -p /home/liveuser/Downloads
mkdir -p /home/liveuser/Documents
mkdir -p /home/liveuser/Pictures
mkdir -p /home/liveuser/Videos

#Edit Cyber Configuration
touch /home/liveuser/.config/cyberos/theme.conf
cat << 'EOF' > /home/liveuser/.config/cyberos/theme.conf
[General]
AccentColor=0
DarkMode=false
DarkModeDimsWallpaer=false
PixelRatio=1
Wallpaper=/usr/share/backgrounds/images/default-16_9.png
EOF

#Cyber Dock
touch /home/liveuser/.config/cyberos/dock_pinned.conf
cat << 'EOF' > /home/liveuser/.config/cyberos/dock_pinned.conf

[Firefox]
DesktopPath=/usr/share/applications/firefox.desktop
Exec=firefox
IconName=firefox
Index=0
visibleName=Firefox
 
[cyber-fm]
DesktopPath=/usr/share/applications/cyber-fm.desktop
Exec=cyber-fm
IconName=file-system-manager
Index=3
visibleName=File Manager
 
[cyber-terminal]
DesktopPath=/usr/share/applications/cyber-terminal.desktop
Exec=cyber-terminal
IconName=utilities-terminal
Index=1
visibleName=Terminal
EOF

#Autostart Installer
touch /home/liveuser/.config/autostart/liveinst.desktop
cat << 'EOF' > /home/liveuser/.config/autostart/liveinst.desktop
[Desktop Entry]
Type=Application
Exec=sh -c '/usr/bin/liveinst'
Hidden=false
NoDisplay=false
Name=Install Ultramarine Linux
EOF


#Cyber Dock
touch /home/liveuser/.config/cyberos/dock_pinned.conf
cat << 'EOF' > /home/liveuser/.config/cyberos/dock_pinned.conf
[Anaconda]
DesktopPath=
Exec=/usr/bin/liveinst
IconName=anaconda
Index=2
visibleName=Install Ultramarine
 
[Firefox]
DesktopPath=/usr/share/applications/firefox.desktop
Exec=firefox
IconName=firefox
Index=0
visibleName=Firefox
 
[cyber-fm]
DesktopPath=/usr/share/applications/cyber-fm.desktop
Exec=cyber-fm
IconName=file-system-manager
Index=3
visibleName=File Manager
 
[cyber-terminal]
DesktopPath=/usr/share/applications/cyber-terminal.desktop
Exec=cyber-terminal
IconName=utilities-terminal
Index=1
visibleName=Terminal
EOF



#Set Text Editor for all users
xdg-mime default cyber-edit.desktop text/plain


# make sure to set the right permissions and selinux contexts
chown -R liveuser:liveuser /home/liveuser
restorecon -R /home/liveuser

ALLEOF

##add skeleton home


##Configuration
#Create Liveuser dir
mkdir -p /etc/skel/.config/cyberos
mkdir -p /etc/skel/.config/
mkdir -p /etc/skel/Downloads
mkdir -p /etc/skel/Documents
mkdir -p /etc/skel/Pictures
mkdir -p /etc/skel/Videos

#Edit Cyber Configuration
touch /etc/skel/.config/cyberos/theme.conf
cat << 'EOF' > /etc/skel/.config/cyberos/theme.conf
[General]
AccentColor=0
DarkMode=false
DarkModeDimsWallpaer=false
PixelRatio=1
Wallpaper=/usr/share/backgrounds/images/default-16_9.png
EOF

#Cyber Dock
touch /etc/skel/.config/cyberos/dock_pinned.conf
cat << 'EOF' > /etc/skel/.config/cyberos/dock_pinned.conf

[Firefox]
DesktopPath=/usr/share/applications/firefox.desktop
Exec=firefox
IconName=firefox
Index=0
visibleName=Firefox
 
[cyber-fm]
DesktopPath=/usr/share/applications/cyber-fm.desktop
Exec=cyber-fm
IconName=file-system-manager
Index=3
visibleName=File Manager
 
[cyber-terminal]
DesktopPath=/usr/share/applications/cyber-terminal.desktop
Exec=cyber-terminal
IconName=utilities-terminal
Index=1
visibleName=Terminal
EOF


%end

%post

echo ""
echo "POST BASE DESKTOP ************************************"
echo ""

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
			<family>Noto Sans Mono</family>
			<family>DejaVu Sans Mono</family>
			<family>Liberation Mono</family>
		</prefer>
	</alias>
</fontconfig>
EOF_FONTS

# Set a colored prompt
cat > /etc/profile.d/color-prompt.sh << EOF_PROMPT
## Colored prompt
if [ -n "\$PS1" ]; then
	if [[ "\$TERM" == *256color ]]; then
		if [ \${UID} -eq 0 ]; then
			PS1='\[\e[91m\]\u@\h \[\e[93m\]\W\[\e[0m\]\\$ '
		else
			PS1='\[\e[92m\]\u@\h \[\e[93m\]\W\[\e[0m\]\\$ '
		fi
	else
		if [ \${UID} -eq 0 ]; then
			PS1='\[\e[31m\]\u@\h \[\e[33m\]\W\[\e[0m\]\\$ '
		else
			PS1='\[\e[32m\]\u@\h \[\e[33m\]\W\[\e[0m\]\\$ '
		fi
	fi
fi
EOF_PROMPT

# Sets a default grub config if not present (rhb #886502)
# Provides some reasonable defaults when the bootloader is not installed
if [ ! -f "/etc/default/grub" ]; then
cat > /etc/default/grub << EOF_DEFAULT_GRUB
GRUB_TIMEOUT=3
GRUB_DISTRIBUTOR="\$(sed 's, release .*\$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_CMDLINE_LINUX="rd.md=0 rd.dm=0 rd.luks=0 rhgb quiet"
GRUB_DISABLE_RECOVERY=false
# GRUB_DISABLE_OS_PROBER=true
EOF_DEFAULT_GRUB
fi

# Disable weak dependencies to avoid unwanted stuff
echo "install_weak_deps=False" >> /etc/dnf/dnf.conf

# Set default boot theme
#fails because no command, it works without this anyway
#plymouth-set-default-theme spinner

%end

%post

#enable SDDM
systemctl enable sddm

#le cisco 
dnf config-manager --set-enabled fedora-cisco-openh264

%end

%packages
@admin-tools
@anaconda-tools
@base-x
@core
@dial-up
@firefox
@fonts
@guest-desktop-agents
@hardware-support
@input-methods
@libreoffice
@multimedia
@networkmanager-submodules
@printing
@standard
PackageKit
PackageKit-gstreamer-plugin
aajohan-comfortaa-fonts
anaconda
anaconda-install-env-deps
anaconda-live
bash-completion
bind-utils
blivet-gui
btrfs-progs
chkconfig
coreutils
cyber-calculator
cyber-desktop-common
cyber-disk-usage
cyber-dock
cyber-edit
cyber-fm
cyber-icon-theme
cyber-kwin-plugins
cyber-launcher
cyber-qt-plugins
cyber-recorder
cyber-settings
cyber-terminal
cyber-workspace
dnf-plugins-core
dracut-live
exfatprogs
firefox
firewall-config
firewalld
flatpak
fuse
glibc-all-langpacks
google-noto-emoji-color-fonts
google-noto-sans-fonts
google-noto-sans-mono-fonts
google-noto-serif-fonts
htop
initscripts
kernel
kernel-modules
kernel-modules-extra
liberation-mono-fonts
liberation-s*-fonts
libreoffice-kf5
libva-vdpau-driver
libvdpau-va-gl
materia-kde-sddm
memtest86+
mesa-*-drivers
meuikit
microcode_ctl
mozilla-openh264
plasma-discover
plasma-systemsettings
plymouth-theme-spinner
policycoreutils
psmisc
qt5ct
rpm-plugin-systemd-inhibit
rsync
sddm
sddm-kcm
syslinux
ultramarine-release
unar
xorg-x11-drivers
xorg-x11-server-Xorg
-@ GNOME Desktop Environment
-fedora-logos
-fedora-release
-gnome-session

%end
