# Samsung Galaxy J5 2015 (SM-J500F) on postmarketOS: kernel patches

Kernel patches for `linux-postmarketos-qcom-msm8916` (6.12.1) that bring up
the hardware of the Galaxy J5 2015 (`samsung-j5`, j5lte, msm8916) which the
mainline kernel and postmarketOS left unsupported, plus a script that drops
them into a pmbootstrap checkout so the stock kernel package is rebuilt with
them.

What the series adds, in order:

1. **SM5703 PMIC core and regulators** (patches 1 and 2). The J5 uses a
   Silicon Mitus SM5703 for its LDOs, buck, charger, flash LED and fuel
   gauge, and mainline has no driver for it. These are the 2022 upstream
   submission by Markuss Broks adapted to 6.12, with the USB LDO enable
   register corrected against Samsung's downstream driver.
2. **Touchscreen** (patch 3). The Imagis IST3038C is powered from SM5703
   LDO3; the device tree now describes the PMIC on BLSP I2C6, feeds LDO3 to
   the touchscreen and enables its bus. This was the original "touchscreen
   broken without SM5703 MFD driver" entry on the wiki.
3. **Vibrator, touch keys, proximity sensor** (patches 4 and 5). The motor
   is SM5703 LDO2 behind a regulator-haptic node, the two capacitive keys
   are a Coreriver TC300K (which needed a new press/release bitmap variant
   in the tm2-touchkey driver), and the GP2AP002 proximity sensor works once
   GPIO 73 is driven as its power enable.
4. **Battery** (patches 6, 7, 11, 12). A new power-supply driver for the
   SM5703 fuel gauge (percentage, voltage, current, chip temperature,
   low-battery alert, Samsung battery table programming), and a read-only
   charger power supply that tells the fuel gauge whether external power is
   present. Before these the phone exposed no battery at all.
5. **Front camera** (patches 8 to 10). A new V4L2 driver for the S5K5E3YX
   sensor with modes from Samsung's Exynos tables, a 26 MHz MCLK entry in
   the msm8916 clock driver, and CCI/camss wiring in the device tree.
6. **Screen brightness** (patch 13). A backlight device for the AMOLED
   panel with a port of Samsung's smart-dimming gamma generation, so the
   brightness slider works across 62 levels from 5 to 360 cd.

Hardware facts come from the downstream Samsung kernel for j5lte
(`msm8916-sec-j5lte-eur-r05.dtsi` and the related driver sources).

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
| `patches/0008-clk-qcom-gcc-msm8916-*.patch` | 26 MHz camera MCLK entry (GPLL1 / 34, as downstream) |
| `patches/0009-media-i2c-Add-Samsung-S5K5E3-*.patch` | New V4L2 driver for the front camera sensor (S5K5E3YX, RAW10, 2576x1932 / 1280x960 / 640x480 modes from Samsung's Exynos tables) |
| `patches/0010-arm64-dts-qcom-msm8916-samsung-j5-Enable-front-camer*.patch` | J5 device tree: CCI and camss enabled, front sensor on CCI at 0x10 with MCLK1, reset GPIO 28, core enable GPIO 33 |
| `patches/0011-power-supply-Add-SM5703-charger-status-driver.patch` | Read-only SM5703 charger power supply (VBUS present, charging/full state, configured currents), polled every 5 s |
| `patches/0012-power-supply-sm5703-fuel-gauge-Derive-status-from-th*.patch` | Fuel gauge takes Charging/Discharging from the charger instead of the near-zero battery current |
| `patches/0013-drm-panel-samsung-s6e8aa5x01-ams497hy01-Add-brightne*.patch` | Brightness control for the AMOLED panel: backlight device, Samsung smart-dimming gamma from the panel's MTP data, AID/ELVSS/ACL per level (62 steps, 5 to 360 cd) |
| `kernel/` | The new source files as plain files, for reading or reuse |
| `pmaports/apply.sh` | Installs the patches and kernel config options into pmaports |
| `pmaports/kconfig.fragment` | `CONFIG_MFD_SM5703=m`, `CONFIG_REGULATOR_SM5703=m`, `CONFIG_GP2AP002=m`, `CONFIG_BATTERY_SM5703=m`, `CONFIG_VIDEO_S5K5E3=m`, `CONFIG_CHARGER_SM5703=m` |

Patch provenance: the SM5703 PMIC and regulator drivers are the v5
submission by Markuss Broks from April 2022 ("Add support for Silicon
Mitus SM5703 MFD"), adapted to kernel 6.12, with the USB LDO enable bits
moved to the control register 0x0C as in Samsung's downstream driver.
Device-tree values (SM5703 at 0x49 on GPIO 22/23 with reset on GPIO 24,
LDO3 at 3.0 V for the touchscreen, USBLDO1 always on, and all the GPIOs
listed in the table above) come from the downstream j5lte device tree.

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

## GNOME: make the Menu touch key open the app grid

postmarketOS's udev hwdb maps the left touch key to KEY_MENU, which GNOME
ignores by default. On the phone, as your user:

```sh
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super>a', 'Menu']"
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
- Patches 6 and 7 (battery) on hardware: the gauge probes at 0x71 and the
  phone now has a `sm5703-fuel-gauge` power supply with percentage,
  voltage, current and chip temperature; GNOME shows the battery level.
  Before them the phone exposed no power_supply device at all. The driver
  programs the Samsung battery tables only when the chip has lost them
  (removable battery pulled); on this phone they were still present.
- Patch 13 (brightness): compile-tested, not yet run on hardware. Before it
  there is no backlight device at all, which is the wiki's "screen partial".
- Patches 11 and 12 (charger status): compile-tested, not yet run on
  hardware. On a PC USB port the battery current hovers around zero, so
  without them the status flips between Charging and Discharging every few
  seconds.
- Patches 8 to 10 (front camera): compile-tested, not yet run on hardware.
  First checkpoint is the sensor ID in `dmesg | grep s5k5e3`; then raw
  frames on the camss RDI path with `media-ctl` and `yavta`, then libcamera
  (`cam -l`). The rear camera (S5K3L2XX, 4 lanes, autofocus) is not started.
- Still open on the wiki's list: camera (no mainline support for these
  sensors), battery (SM5703 fuel gauge at a separate I2C address, no
  mainline driver, now addressed by patches 6/7), screen brightness (patch
  13), USB OTG (needs the SM5703 VBUS boost), accelerometer
  mount matrix (needs testing by rotating the phone).

## Note on flashing

The J5's boot partition is only 12.5 MB, so `pmbootstrap flasher
flash_kernel` fails with "size too large" (the systemd initramfs alone is
14 MB). That is harmless: lk2nd looks for `/extlinux/extlinux.conf` on
any ext2 partition larger than 16 MiB before falling back to a boot
image, and the pmOS rootfs image flashed to userdata carries exactly
that, so the kernel boots from there. Flash the rootfs and reboot.
