# Galaxy J5 (2015) touchscreen on postmarketOS: SM5703 PMIC patches

The Samsung Galaxy J5 2015 (`samsung-j5`, msm8916) powers its Imagis
IST3038C touchscreen from LDO3 of a Silicon Mitus SM5703 PMIC. Mainline
Linux has no driver for that PMIC, so the J5 device tree leaves the
touchscreen bus disabled with the note
`FIXME: Missing sm5703-mfd driver to power up vdd-supply`.

This repo carries kernel patches that fix that, plus a script that drops
them into a pmbootstrap checkout so the stock postmarketOS kernel package
(`linux-postmarketos-qcom-msm8916`, 6.12.1) gets rebuilt with them.

## Contents

| Path | What |
| --- | --- |
| `patches/0001-mfd-sm5703-*.patch` | SM5703 PMIC core driver, register header, device-tree binding |
| `patches/0002-regulator-sm5703-*.patch` | Regulator driver: 3 LDOs, buck, 2 USB LDOs, VBUS |
| `patches/0003-arm64-dts-qcom-msm8916-samsung-j5-*.patch` | J5 device tree: PMIC on BLSP I2C6, LDO3 feeds the touchscreen, touchscreen bus enabled |
| `kernel/` | The new source files as plain files, for reading or reuse |
| `pmaports/apply.sh` | Installs the patches and kernel config options into pmaports |
| `pmaports/kconfig.fragment` | `CONFIG_MFD_SM5703=m`, `CONFIG_REGULATOR_SM5703=m` |

The drivers are the v5 submission by Markuss Broks from April 2022
("Add support for Silicon Mitus SM5703 MFD"), adapted to kernel 6.12 and
with one register fix: the USB LDO enable bits live in the control
register 0x0C, as in Samsung's downstream driver, not in the LDO3
register. The device tree values (I2C address 0x49 on GPIO 22/23, reset
on GPIO 24, LDO3 at 3.0 V for the touchscreen, USBLDO1 always on) come
from the downstream `msm8916-sec-j5lte-eur-r05.dtsi`.

## Build and flash

The phone needs lk2nd. Boot it into lk2nd fastboot mode (it shows up as
`18d1:d00d` on USB).

```sh
sudo pacman -S pmbootstrap android-tools      # Arch / CachyOS
pmbootstrap init                              # channel v26.06, vendor samsung, device j5
pmaports/apply.sh                             # copies patches, bumps pkgrel, updates config, runs checksum
pmbootstrap build --force linux-postmarketos-qcom-msm8916
pmbootstrap install --ssh-keys                # bakes ~/.ssh/*.pub into the image
pmbootstrap flasher flash_kernel
pmbootstrap flasher flash_rootfs
fastboot reboot
```

`samsung-j5` is archived on the pmaports master branch (no maintainer),
but still present on the release branches v25.06, v25.12 and v26.06, so
pick a release channel in `pmbootstrap init`. All of them ship the same
kernel version the patches were made for.

If the device package is not offered by `pmbootstrap init`, set it
directly: `pmbootstrap config device samsung-j5`.

## Verify on the phone

```sh
ssh 172.16.42.1
dmesg | grep -iE 'sm5703|imagis|ist30'
ls /sys/class/regulator/*/name | xargs grep -l vdd_tsp
cat /sys/class/regulator/regulator.*/state      # vdd_tsp should be "enabled"
evtest                                           # pick the IST3038C device, touch the screen
```

## Status

- Drivers compile with clang for arm64 against the postmarketOS msm8916
  config (see below for how this was tested).
- Device tree blob builds; the PMIC and touchscreen nodes are present and
  the touchscreen bus is enabled.
- Not yet tested on hardware: the phone needs reflashing first.
