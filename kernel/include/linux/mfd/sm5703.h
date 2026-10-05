/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Silicon Mitus SM5703 PMIC register definitions.
 *
 * Based on the "Add support for Silicon Mitus SM5703 MFD" series by
 * Markuss Broks <markuss.broks@gmail.com> (v5, April 2022), with the
 * register map cross-checked against the Samsung downstream driver
 * (include/linux/battery/charger/sm5703_charger.h).
 */

#ifndef _SM5703_H
#define _SM5703_H

#include <linux/bits.h>

struct device;
struct regmap;
struct gpio_desc;

struct sm5703_dev {
	struct device *dev;
	struct regmap *regmap;
	struct gpio_desc *reset_gpio;
};

/* Interrupt registers */
#define SM5703_REG_INT1				0x00
#define SM5703_REG_INT2				0x01
#define SM5703_REG_INT3				0x02
#define SM5703_REG_INT4				0x03
#define SM5703_REG_INTMSK1			0x04
#define SM5703_REG_INTMSK2			0x05
#define SM5703_REG_INTMSK3			0x06
#define SM5703_REG_INTMSK4			0x07
#define SM5703_REG_STATUS1			0x08
#define SM5703_REG_STATUS2			0x09
#define SM5703_REG_STATUS3			0x0A
#define SM5703_REG_STATUS4			0x0B
#define SM5703_REG_STATUS5			0x6B

/* Control register: operation mode (bits 0-2) and USB LDO enables */
#define SM5703_REG_CNTL				0x0C
#define SM5703_OPERATION_MODE_MASK		GENMASK(2, 0)
#define SM5703_OPERATION_MODE_SUSPEND		0x00
#define SM5703_OPERATION_MODE_CHARGING_OFF	0x04
#define SM5703_OPERATION_MODE_CHARGING_ON	0x05
#define SM5703_OPERATION_MODE_FLASH_BOOST_MODE	0x06
#define SM5703_OPERATION_MODE_USB_OTG_MODE	0x07
#define SM5703_REG_USBLDO12			SM5703_REG_CNTL
#define SM5703_REG_EN_USBLDO1			BIT(6)
#define SM5703_REG_EN_USBLDO2			BIT(7)

/* Charger registers */
#define SM5703_REG_VBUSCNTL			0x0D
#define SM5703_REG_CHGCNTL1			0x0E
#define SM5703_REG_CHGCNTL2			0x0F
#define SM5703_REG_CHGCNTL3			0x10
#define SM5703_REG_CHGCNTL4			0x11
#define SM5703_REG_CHGCNTL5			0x12
#define SM5703_REG_CHGCNTL6			0x13
#define SM5703_REG_OTGCURRENTCNTL		0x60
#define SM5703_REG_Q3LIMITCNTL			0x66

/* Flash LED registers */
#define SM5703_REG_FLEDCNTL1			0x14
#define SM5703_REG_FLEDCNTL2			0x15
#define SM5703_REG_FLEDCNTL3			0x16
#define SM5703_REG_FLEDCNTL4			0x17
#define SM5703_REG_FLEDCNTL5			0x18
#define SM5703_REG_FLEDCNTL6			0x19

/* LDO / buck regulators: voltage select in low bits, enable bit above */
#define SM5703_REG_LDO1				0x1A
#define SM5703_REG_LDO2				0x1B
#define SM5703_REG_LDO3				0x1C
#define SM5703_LDO_EN				BIT(3)
#define SM5703_LDO_VOLT_MASK			GENMASK(2, 0)
#define SM5703_REG_BUCK				0x1D
#define SM5703_REG_EN_BUCK			BIT(6)
#define SM5703_BUCK_VOLT_MASK			GENMASK(4, 0)

#define SM5703_USBLDO_MICROVOLT			4800000

#define SM5703_REG_DEVICE_ID			0x1E

#endif /* _SM5703_H */
