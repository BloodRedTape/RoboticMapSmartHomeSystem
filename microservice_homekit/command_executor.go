package main

import (
	"fmt"
	"log"
	"github.com/brutella/hap/accessory"
)

type CommandExecutor struct {
	accessories map[uint64]*accessory.Accessory
}

func NewCommandExecutor() *CommandExecutor {
	return &CommandExecutor{
		accessories: make(map[uint64]*accessory.Accessory),
	}
}

func (ce *CommandExecutor) RegisterAccessory(acc *accessory.Accessory) {
	ce.accessories[acc.ID] = acc
}

func (ce *CommandExecutor) ExecuteCommand(aid uint64, command string, params map[string]interface{}) error {
	acc, ok := ce.accessories[aid]
	if !ok {
		return fmt.Errorf("accessory %d not found", aid)
	}

	switch command {
	case "turn_on":
		return ce.turnOn(acc)
	case "turn_off":
		return ce.turnOff(acc)
	case "toggle":
		return ce.toggle(acc)
	case "set_brightness":
		brightness, ok := params["brightness"].(float64)
		if !ok {
			return fmt.Errorf("invalid brightness parameter")
		}
		return ce.setBrightness(acc, int(brightness))
	case "set_temperature":
		temperature, ok := params["temperature"].(float64)
		if !ok {
			return fmt.Errorf("invalid temperature parameter")
		}
		return ce.setTemperature(acc, temperature)
	case "lock":
		return ce.lock(acc)
	case "unlock":
		return ce.unlock(acc)
	case "open":
		return ce.open(acc)
	case "close":
		return ce.close(acc)
	case "set_position":
		position, ok := params["position"].(float64)
		if !ok {
			return fmt.Errorf("invalid position parameter")
		}
		return ce.setPosition(acc, int(position))
	default:
		return fmt.Errorf("unknown command: %s", command)
	}
}

func (ce *CommandExecutor) turnOn(acc *accessory.Accessory) error {
	if acc.Lightbulb != nil {
		acc.Lightbulb.On.SetValue(true)
		log.Printf("Turned on lightbulb %d", acc.ID)
		return nil
	}
	if acc.Outlet != nil {
		acc.Outlet.On.SetValue(true)
		log.Printf("Turned on outlet %d", acc.ID)
		return nil
	}
	if acc.Switch != nil {
		acc.Switch.On.SetValue(true)
		log.Printf("Turned on switch %d", acc.ID)
		return nil
	}
	return fmt.Errorf("accessory does not support turn_on")
}

func (ce *CommandExecutor) turnOff(acc *accessory.Accessory) error {
	if acc.Lightbulb != nil {
		acc.Lightbulb.On.SetValue(false)
		log.Printf("Turned off lightbulb %d", acc.ID)
		return nil
	}
	if acc.Outlet != nil {
		acc.Outlet.On.SetValue(false)
		log.Printf("Turned off outlet %d", acc.ID)
		return nil
	}
	if acc.Switch != nil {
		acc.Switch.On.SetValue(false)
		log.Printf("Turned off switch %d", acc.ID)
		return nil
	}
	return fmt.Errorf("accessory does not support turn_off")
}

func (ce *CommandExecutor) toggle(acc *accessory.Accessory) error {
	if acc.Lightbulb != nil {
		currentState := acc.Lightbulb.On.Value()
		acc.Lightbulb.On.SetValue(!currentState)
		log.Printf("Toggled lightbulb %d to %v", acc.ID, !currentState)
		return nil
	}
	if acc.Outlet != nil {
		currentState := acc.Outlet.On.Value()
		acc.Outlet.On.SetValue(!currentState)
		log.Printf("Toggled outlet %d to %v", acc.ID, !currentState)
		return nil
	}
	return fmt.Errorf("accessory does not support toggle")
}

func (ce *CommandExecutor) setBrightness(acc *accessory.Accessory, brightness int) error {
	if acc.Lightbulb != nil && acc.Lightbulb.Brightness != nil {
		acc.Lightbulb.Brightness.SetValue(brightness)
		log.Printf("Set brightness of lightbulb %d to %d", acc.ID, brightness)
		return nil
	}
	return fmt.Errorf("accessory does not support brightness")
}

func (ce *CommandExecutor) setTemperature(acc *accessory.Accessory, temperature float64) error {
	if acc.Thermostat != nil {
		acc.Thermostat.TargetTemperature.SetValue(temperature)
		log.Printf("Set target temperature of thermostat %d to %.1f", acc.ID, temperature)
		return nil
	}
	return fmt.Errorf("accessory does not support temperature")
}

func (ce *CommandExecutor) lock(acc *accessory.Accessory) error {
	if acc.LockMechanism != nil {
		acc.LockMechanism.LockTargetState.SetValue(1)
		log.Printf("Locked door lock %d", acc.ID)
		return nil
	}
	return fmt.Errorf("accessory does not support lock")
}

func (ce *CommandExecutor) unlock(acc *accessory.Accessory) error {
	if acc.LockMechanism != nil {
		acc.LockMechanism.LockTargetState.SetValue(0)
		log.Printf("Unlocked door lock %d", acc.ID)
		return nil
	}
	return fmt.Errorf("accessory does not support unlock")
}

func (ce *CommandExecutor) open(acc *accessory.Accessory) error {
	if acc.GarageDoorOpener != nil {
		acc.GarageDoorOpener.TargetDoorState.SetValue(0)
		log.Printf("Opening garage door %d", acc.ID)
		return nil
	}
	if acc.WindowCovering != nil {
		acc.WindowCovering.TargetPosition.SetValue(100)
		log.Printf("Opening window covering %d", acc.ID)
		return nil
	}
	return fmt.Errorf("accessory does not support open")
}

func (ce *CommandExecutor) close(acc *accessory.Accessory) error {
	if acc.GarageDoorOpener != nil {
		acc.GarageDoorOpener.TargetDoorState.SetValue(1)
		log.Printf("Closing garage door %d", acc.ID)
		return nil
	}
	if acc.WindowCovering != nil {
		acc.WindowCovering.TargetPosition.SetValue(0)
		log.Printf("Closing window covering %d", acc.ID)
		return nil
	}
	return fmt.Errorf("accessory does not support close")
}

func (ce *CommandExecutor) setPosition(acc *accessory.Accessory, position int) error {
	if acc.WindowCovering != nil {
		acc.WindowCovering.TargetPosition.SetValue(position)
		log.Printf("Set position of window covering %d to %d", acc.ID, position)
		return nil
	}
	return fmt.Errorf("accessory does not support position")
}
