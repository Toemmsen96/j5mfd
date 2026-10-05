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
| `patches/0002-regulator-sm5703-*.patch` | Regulator driver: 3 LDOs, buck, 2 USB LDOs |
| `patches/0003-arm64-dts-qcom-msm8916-samsung-j5-Add-SM5703-*.patch` | J5 device tree: PMIC on BLSP I2C6, LDO3 feeds the touchscreen, touchscreen bus enabled |
| `patches/0004-arm64-dts-qcom-msm8916-samsung-j5-Add-vibrator-*.patch` | J5 device tree: vibrator (SM5703 LDO2), Coreriver touch keys, GP2AP002 proximity sensor |
| `patches/0005-Input-tm2-touchkey-*.patch` | tm2-touchkey driver: decode the Coreriver TC300K press/release bitmap the J5's key controller reports |
| `patches/0006-power-supply-Add-Silicon-Mitus-SM5703-fuel-gauge-*.patch` | New power-supply driver for the SM5703 fuel gauge (voltage, current, SoC, chip temperature, low-SoC alert, battery parameter programming from DT) |
| `patches/0007-arm64-dts-qcom-msm8916-samsung-j5-Add-SM5703-fuel-ga*.patch` | J5 device tree: fuel gauge at 0x71 on a bit-banged bus (GPIO 14/15), alert on GPIO 121, J5 battery tables |
| `kernel/` | The new source files as plain files, for reading or reuse |
| `pmaports/apply.sh` | Installs the patches and kernel config options into pmaports |
| `pmaports/kconfig.fragment` | `CONFIG_MFD_SM5703=m`, `CONFIG_REGULATOR_SM5703=m`, `CONFIG_GP2AP002=m`, `CONFIG_BATTERY_SM5703=m` |

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
pmbootstrap install                           # ssh keys are copied if enabled in init
pmbootstrap flasher flash_rootfs              # flash_kernel fails on the J5, see below
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

## Updating an already flashed phone

After changing the patches, rebuild the kernel package and push it to the
phone over the USB network instead of reflashing:

```sh
pmaports/apply.sh
pmbootstrap build --force linux-postmarketos-qcom-msm8916
pmbootstrap sideload linux-postmarketos-qcom-msm8916
ssh 172.16.42.1 # This is the address of the phone over USB
sudo reboot
```

## Status

- Drivers compile with clang for arm64 against the postmarketOS msm8916
  config (see below for how this was tested).
- Device tree blob builds; the PMIC and touchscreen nodes are present and
  the touchscreen bus is enabled.
- Reviewed against the downstream Samsung sources (register map, voltage
  tables, reset polarity, bus wiring, regulator constraints): no issues.
- Tested on an SM-J500F running postmarketOS v26.06 (GNOME Mobile): the
  touchscreen works.
- Patches 4 and 5 on hardware: touch keys (press and release for both
  keys; postmarketOS's udev hwdb remaps the left key from KEY_APPSELECT
  to KEY_MENU, which is expected), vibrator (feedbackd haptic events) and
  proximity sensor (NEAR/FAR IIO events) all work. The proximity sensor
  only works because GPIO 73 is driven as its power enable; without it
  the sensor never raises an interrupt, which matches the old wiki note.
- Patches 6 and 7 (battery): compile-tested, not yet run on hardware. Before
  them the phone exposes no power_supply device at all. The driver reports
  the gauge's own state of charge and programs the Samsung battery tables
  only when the chip has lost them (removable battery pulled).
- Still open on the wiki's list: camera (no mainline support for these
  sensors), battery (SM5703 fuel gauge at a separate I2C address, no
  mainline driver, now addressed by patches 6/7), USB OTG (needs the SM5703 VBUS boost), accelerometer
  mount matrix (needs testing by rotating the phone).

## Note on flashing

The J5's boot partition is only 12.5 MB, so `pmbootstrap flasher
flash_kernel` fails with "size too large" (the systemd initramfs alone is
14 MB). That is harmless: lk2nd looks for `/extlinux/extlinux.conf` on
any ext2 partition larger than 16 MiB before falling back to a boot
image, and the pmOS rootfs image flashed to userdata carries exactly
that, so the kernel boots from there. Flash the rootfs and reboot.
