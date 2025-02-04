#repo --name="copr:copr.fedorainfracloud.org:cappyishihara:budgie-desktop" --baseurl=https://download.copr.fedorainfracloud.org/results/cappyishihara/budgie-desktop/fedora-$releasever-$basearch/
# Now included in Ultramarine Repos
%packages
@standard
@base-x
@input-methods
@multimedia
@fonts
@pantheon-desktop
policycoreutils
coreutils
-setroubleshoot

gnome-system-monitor
file-roller
evince
seahorse
gnome-sound-recorder
gnome-disk-utility
gnome-screenshot
abrt
xdg-user-dirs-gtk
-gnome-software
appcenter

ultramarine-release-basic
ultramarine-backgrounds-gnome
ultramarine-backgrounds-basic

xorg-x11-server-Xorg
#funny theme


%end