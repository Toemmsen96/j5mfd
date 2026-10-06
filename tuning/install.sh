#!/bin/sh
# Run on the phone as the login user. Installs the tuned profiles, the
# sysctl file and the GNOME Software autostart override from this directory.
set -eu

here=$(cd "$(dirname "$0")" && pwd)

for p in j5-interactive j5-balanced j5-balanced-battery; do
	sudo install -Dm644 "$here/$p/tuned.conf" "/etc/tuned/profiles/$p/tuned.conf"
done
sudo install -m644 "$here/90-j5-zram.conf" /etc/sysctl.d/90-j5-zram.conf

[ -e /etc/tuned/ppd.conf.orig ] || sudo cp -p /etc/tuned/ppd.conf /etc/tuned/ppd.conf.orig
sudo sed -i \
	-e 's/^performance=.*/performance=j5-interactive/' \
	-e 's/^balanced=balanced$/balanced=j5-balanced/' \
	-e 's/^balanced=balanced-battery$/balanced=j5-balanced-battery/' \
	/etc/tuned/ppd.conf
sudo systemctl restart tuned-ppd.service
sudo sysctl -q -p /etc/sysctl.d/90-j5-zram.conf

# GNOME Software: do not start at login, keep it launchable on demand.
# Masking the unit alone would break D-Bus activation, so the session bus
# gets a service file that starts the binary directly.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
install -Dm644 "$here/org.gnome.Software.service" \
	"${XDG_DATA_HOME:-$HOME/.local/share}/dbus-1/services/org.gnome.Software.service"
systemctl --user mask --now gnome-software.service
systemctl --user reload dbus-broker.service

# Its search provider would start it again on every search in the overview.
disabled=$(gsettings get org.gnome.desktop.search-providers disabled)
case "$disabled" in
*org.gnome.Software.desktop*) ;;
"@as []") gsettings set org.gnome.desktop.search-providers disabled "['org.gnome.Software.desktop']" ;;
*) echo "add org.gnome.Software.desktop to org.gnome.desktop.search-providers disabled yourself (now: $disabled)" >&2 ;;
esac

echo "tuned profile: $(tuned-adm active)"
