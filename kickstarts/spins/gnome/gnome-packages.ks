#repo --name="copr:copr.fedorainfracloud.org:cappyishihara:budgie-desktop" --baseurl=https://download.copr.fedorainfracloud.org/results/cappyishihara/budgie-desktop/fedora-$releasever-$basearch/
# Now included in Ultramarine Repos
%packages
@core
@standard
@base-x
-@input-methods
-@dial-up
@multimedia
@fonts
@gnome-desktop
policycoreutils
coreutils
#-setroubleshoot

gnome-system-monitor
file-roller
evince
seahorse
gnome-sound-recorder
gnome-disk-utility
gnome-screenshot
abrt
gnome-weather
gnome-clocks
xdg-user-dirs-gtk
xdg-desktop-portal-gtk
gnome-initial-setup
-totem
clapper
@^workstation-product-environment
-gedit

# Extra ricing
gnome-extensions-app
gnome-shell-extension-pop-shell
pop-launcher
xprop
gnome-shell-extension-appindicator

ultramarine-release-basic
ultramarine-backgrounds-gnome
ultramarine-backgrounds-basic
ultramarine-gnome-filesystem



%end