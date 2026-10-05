#!/bin/sh
# Install the SM5703 / Galaxy J5 touchscreen patches into a pmaports checkout.
#
# Usage: ./apply.sh [PMAPORTS_DIR]
#   PMAPORTS_DIR defaults to the pmaports path configured in pmbootstrap.
#
# Afterwards build and install as usual:
#   pmbootstrap build --force linux-postmarketos-qcom-msm8916
#   pmbootstrap install --ssh-keys
set -eu

here=$(cd "$(dirname "$0")" && pwd)
patches="$here/../patches"
fragment="$here/kconfig.fragment"

pmaports=${1:-$(pmbootstrap config aports 2>/dev/null || true)}
if [ -z "$pmaports" ] || [ ! -d "$pmaports/device" ]; then
	echo "pmaports checkout not found; pass its path as the first argument" >&2
	exit 1
fi

kdir=$(find "$pmaports/device" -maxdepth 2 -type d -name linux-postmarketos-qcom-msm8916 | head -n1)
[ -n "$kdir" ] || { echo "linux-postmarketos-qcom-msm8916 not found in $pmaports" >&2; exit 1; }
apkbuild="$kdir/APKBUILD"
echo "Kernel package: $kdir"

if grep -q 'sm5703' "$apkbuild"; then
	echo "APKBUILD already references the sm5703 patches; refreshing patch files only"
else
	# Insert the patch file names before the closing quote of source="...".
	names=$(cd "$patches" && ls *.patch | sed 's/^/\t/')
	awk -v names="$names" '
		/^source="/ { insrc=1 }
		insrc && /^"$/ { print names; insrc=0 }
		{ print }
	' "$apkbuild" > "$apkbuild.tmp" && mv "$apkbuild.tmp" "$apkbuild"

	rel=$(sed -n 's/^pkgrel=//p' "$apkbuild")
	sed -i "s/^pkgrel=.*/pkgrel=$((rel + 1))/" "$apkbuild"
	echo "pkgrel bumped to $((rel + 1))"
fi

cp "$patches"/*.patch "$kdir/"

for cfg in "$kdir"/config-postmarketos-qcom-msm8916.*; do
	while IFS= read -r line; do
		opt=${line%%=*}
		if grep -q "^$opt=" "$cfg"; then
			sed -i "s|^$opt=.*|$line|" "$cfg"
		elif grep -q "^# $opt is not set" "$cfg"; then
			sed -i "s|^# $opt is not set|$line|" "$cfg"
		else
			printf '%s\n' "$line" >> "$cfg"
		fi
	done < "$fragment"
	echo "updated $(basename "$cfg")"
done

if command -v pmbootstrap >/dev/null 2>&1; then
	pmbootstrap checksum linux-postmarketos-qcom-msm8916
else
	echo "pmbootstrap not in PATH: run 'pmbootstrap checksum linux-postmarketos-qcom-msm8916' yourself" >&2
fi

echo
echo "Done. Next:"
echo "  pmbootstrap build --force linux-postmarketos-qcom-msm8916"
echo "  pmbootstrap install --ssh-keys"
