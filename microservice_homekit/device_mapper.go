package main

import (
	"fmt"
	"github.com/brutella/hap/accessory"
)

type DeviceMapper struct{}

var homekitToCommonTypes = map[string]string{
	"lightbulb":          "light",
	"dimmer":             "dimmer_light",
	"outlet":             "plug",
	"switch":             "switch",
	"thermostat":         "thermostat",
	"temperature_sensor": "temperature_sensor",
	"humidity_sensor":    "humidity_sensor",
	"contact_sensor":     "contact_sensor",
	"motion_sensor":      "motion_sensor",
	"occupancy_sensor":   "occupancy_sensor",
	"leak_sensor":        "leak_sensor",
	"smoke_sensor":       "smoke_sensor",
	"lock":               "door_lock",
	"garage_door":        "garage_door",
	"window_covering":    "window_covering",
	"fan":                "fan",
}

func (dm *DeviceMapper) MapHomekitDevice(acc *accessory.Accessory) map[string]interface{} {
	aid := acc.ID
	accType := dm.getAccessoryType(acc)

	if commonType, ok := homekitToCommonTypes[accType]; !ok {
		return nil
	} else {
		attributes := dm.extractAttributes(acc)
		commands := dm.getAvailableCommands(accType)

		return map[string]interface{}{
			"id":       fmt.Sprintf("homekit_%d", aid),
			"type":     commonType,
			"name":     acc.Info.Name.Value(),
			"protocol": "homekit",
			"attributes": attributes,
			"commands":   commands,
			"metadata": map[string]interface{}{
				"aid":          aid,
				"manufacturer": acc.Info.Manufacturer.Value(),
				"model":        acc.Info.Model.Value(),
				"serial":       acc.Info.SerialNumber.Value(),
				"firmware":     acc.Info.FirmwareRevision.Value(),
			},
		}
	}
}

func (dm *DeviceMapper) getAccessoryType(acc *accessory.Accessory) string {
	switch acc.Type {
	case accessory.TypeLightbulb:
		return "lightbulb"
	case accessory.TypeOutlet:
		return "outlet"
	case accessory.TypeSwitch:
		return "switch"
	case accessory.TypeThermostat:
		return "thermostat"
	case accessory.TypeTemperatureSensor:
		return "temperature_sensor"
	case accessory.TypeHumiditySensor:
		return "humidity_sensor"
	case accessory.TypeContactSensor:
		return "contact_sensor"
	case accessory.TypeMotionSensor:
		return "motion_sensor"
	case accessory.TypeOccupancySensor:
		return "occupancy_sensor"
	case accessory.TypeLeakSensor:
		return "leak_sensor"
	case accessory.TypeSmokeSensor:
		return "smoke_sensor"
	case accessory.TypeDoorLock:
		return "lock"
	case accessory.TypeGarageDoorOpener:
		return "garage_door"
	case accessory.TypeWindowCovering:
		return "window_covering"
	case accessory.TypeFan:
		return "fan"
	default:
		return "unknown"
	}
}

func (dm *DeviceMapper) extractAttributes(acc *accessory.Accessory) []map[string]interface{} {
	attributes := []map[string]interface{}{}

	if lightbulb := acc.Lightbulb; lightbulb != nil {
		attributes = append(attributes, map[string]interface{}{
			"name":  "state",
			"value": lightbulb.On.Value(),
			"type":  "boolean",
		})
		if lightbulb.Brightness != nil {
			attributes = append(attributes, map[string]interface{}{
				"name":  "brightness",
				"value": lightbulb.Brightness.Value(),
				"type":  "percentage",
			})
		}
	}

	if outlet := acc.Outlet; outlet != nil {
		attributes = append(attributes, map[string]interface{}{
			"name":  "state",
			"value": outlet.On.Value(),
			"type":  "boolean",
		})
	}

	if thermostat := acc.Thermostat; thermostat != nil {
		attributes = append(attributes, map[string]interface{}{
			"name":  "current_temperature",
			"value": thermostat.CurrentTemperature.Value(),
			"type":  "temperature",
		})
		attributes = append(attributes, map[string]interface{}{
			"name":  "target_temperature",
			"value": thermostat.TargetTemperature.Value(),
			"type":  "temperature",
		})
	}

	if tempSensor := acc.TemperatureSensor; tempSensor != nil {
		attributes = append(attributes, map[string]interface{}{
			"name":  "temperature",
			"value": tempSensor.CurrentTemperature.Value(),
			"type":  "temperature",
		})
	}

	if humiditySensor := acc.HumiditySensor; humiditySensor != nil {
		attributes = append(attributes, map[string]interface{}{
			"name":  "humidity",
			"value": humiditySensor.CurrentRelativeHumidity.Value(),
			"type":  "percentage",
		})
	}

	return attributes
}

func (dm *DeviceMapper) getAvailableCommands(accType string) []string {
	commandMapping := map[string][]string{
		"lightbulb":       {"turn_on", "turn_off", "toggle", "set_brightness"},
		"dimmer":          {"turn_on", "turn_off", "set_brightness"},
		"outlet":          {"turn_on", "turn_off", "toggle"},
		"switch":          {"turn_on", "turn_off", "toggle"},
		"thermostat":      {"set_temperature", "set_mode"},
		"lock":            {"lock", "unlock"},
		"garage_door":     {"open", "close"},
		"window_covering": {"open", "close", "set_position"},
		"fan":             {"turn_on", "turn_off", "set_speed"},
	}

	if commands, ok := commandMapping[accType]; ok {
		return commands
	}
	return []string{}
}
