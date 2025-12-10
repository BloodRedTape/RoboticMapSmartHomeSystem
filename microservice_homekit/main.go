package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/brutella/hap"
	"github.com/brutella/hap/accessory"
	"github.com/gorilla/mux"
)

type Device struct {
	ID              string                 `json:"id"`
	Name            string                 `json:"name"`
	Type            string                 `json:"type"`
	Model           string                 `json:"model"`
	Manufacturer    string                 `json:"manufacturer"`
	FirmwareVersion string                 `json:"firmware_version"`
	Paired          bool                   `json:"paired"`
	Reachable       bool                   `json:"reachable"`
	Characteristics map[string]interface{} `json:"characteristics"`
	LastSeen        time.Time              `json:"last_seen"`
}

type HomeKitMicroservice struct {
	router      *mux.Router
	accessories map[string]*accessory.Accessory
	devices     map[string]*Device
	discovering bool
	mu          sync.RWMutex
}

func NewHomeKitMicroservice() *HomeKitMicroservice {
	return &HomeKitMicroservice{
		router:      mux.NewRouter(),
		accessories: make(map[string]*accessory.Accessory),
		devices:     make(map[string]*Device),
		discovering: false,
	}
}

func (h *HomeKitMicroservice) setupRoutes() {
	h.router.HandleFunc("/devices", h.getDevices).Methods("GET")
	h.router.HandleFunc("/devices/discover", h.discoverDevices).Methods("POST")
	h.router.HandleFunc("/devices/{id}", h.getDevice).Methods("GET")
	h.router.HandleFunc("/devices/{id}/pair", h.pairDevice).Methods("POST")
	h.router.HandleFunc("/devices/{id}/unpair", h.unpairDevice).Methods("POST")
	h.router.HandleFunc("/devices/{id}", h.removeDevice).Methods("DELETE")

	h.router.HandleFunc("/devices/{id}/characteristics", h.getCharacteristics).Methods("GET")
	h.router.HandleFunc("/devices/{id}/characteristics/{characteristic}", h.getCharacteristic).Methods("GET")
	h.router.HandleFunc("/devices/{id}/characteristics/{characteristic}", h.setCharacteristic).Methods("PUT")

	h.router.HandleFunc("/devices/{id}/command", h.sendCommand).Methods("POST")
	h.router.HandleFunc("/devices/{id}/services", h.getServices).Methods("GET")
}

func (h *HomeKitMicroservice) getDevices(w http.ResponseWriter, r *http.Request) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	devices := make([]*Device, 0, len(h.devices))

	for _, device := range h.devices {
		devices = append(devices, device)
	}

	json.NewEncoder(w).Encode(devices)
}

func (h *HomeKitMicroservice) discoverDevices(w http.ResponseWriter, r *http.Request) {
	h.mu.Lock()
	if h.discovering {
		h.mu.Unlock()
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(map[string]string{"error": "Discovery already in progress"})
		return
	}
	h.discovering = true
	h.mu.Unlock()

	discovered := []map[string]interface{}{
		{
			"id":           "homekit_light_001",
			"name":         "Living Room Light",
			"type":         "lightbulb",
			"model":        "Philips Hue",
			"manufacturer": "Signify",
			"paired":       false,
		},
		{
			"id":           "homekit_switch_001",
			"name":         "Bedroom Switch",
			"type":         "switch",
			"model":        "Eve Energy",
			"manufacturer": "Elgato",
			"paired":       false,
		},
	}

	h.mu.Lock()
	h.discovering = false
	h.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":     "success",
		"discovered": discovered,
	})
}

func (h *HomeKitMicroservice) getDevice(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deviceID := vars["id"]

	h.mu.RLock()
	device, exists := h.devices[deviceID]
	h.mu.RUnlock()

	w.Header().Set("Content-Type", "application/json")

	if exists {
		json.NewEncoder(w).Encode(device)
	} else {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]string{"error": "Device not found"})
	}
}

func (h *HomeKitMicroservice) pairDevice(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deviceID := vars["id"]

	var req struct {
		SetupCode string `json:"setup_code"`
		Name      string `json:"name"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid request"})
		return
	}

	h.mu.Lock()
	device := &Device{
		ID:              deviceID,
		Name:            req.Name,
		Type:            "lightbulb",
		Model:           "Generic HomeKit Device",
		Manufacturer:    "HomeKit",
		FirmwareVersion: "1.0.0",
		Paired:          true,
		Reachable:       true,
		Characteristics: map[string]interface{}{
			"on":         false,
			"brightness": 100,
		},
		LastSeen: time.Now(),
	}
	h.devices[deviceID] = device
	h.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"device": device,
	})
}

func (h *HomeKitMicroservice) unpairDevice(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deviceID := vars["id"]

	h.mu.Lock()
	if device, exists := h.devices[deviceID]; exists {
		device.Paired = false
	}
	h.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
	})
}

func (h *HomeKitMicroservice) removeDevice(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deviceID := vars["id"]

	h.mu.Lock()
	delete(h.devices, deviceID)
	delete(h.accessories, deviceID)
	h.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "success",
		"message": "Device removed",
	})
}

func (h *HomeKitMicroservice) getCharacteristics(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deviceID := vars["id"]

	h.mu.RLock()
	device, exists := h.devices[deviceID]
	h.mu.RUnlock()

	w.Header().Set("Content-Type", "application/json")

	if !exists {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]string{"error": "Device not found"})
		return
	}

	json.NewEncoder(w).Encode(device.Characteristics)
}

func (h *HomeKitMicroservice) getCharacteristic(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deviceID := vars["id"]
	characteristic := vars["characteristic"]

	h.mu.RLock()
	device, exists := h.devices[deviceID]
	h.mu.RUnlock()

	w.Header().Set("Content-Type", "application/json")

	if !exists {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]string{"error": "Device not found"})
		return
	}

	if value, ok := device.Characteristics[characteristic]; ok {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"characteristic": characteristic,
			"value":          value,
		})
	} else {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]string{"error": "Characteristic not found"})
	}
}

func (h *HomeKitMicroservice) setCharacteristic(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deviceID := vars["id"]
	characteristic := vars["characteristic"]

	var req struct {
		Value interface{} `json:"value"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid request"})
		return
	}

	h.mu.Lock()
	device, exists := h.devices[deviceID]
	if exists {
		device.Characteristics[characteristic] = req.Value
		device.LastSeen = time.Now()
	}
	h.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")

	if !exists {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]string{"error": "Device not found"})
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "success",
		"characteristic": characteristic,
		"value":          req.Value,
	})
}

func (h *HomeKitMicroservice) sendCommand(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deviceID := vars["id"]

	var command map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&command); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid request"})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":    "success",
		"device_id": deviceID,
		"command":   command,
	})
}

func (h *HomeKitMicroservice) getServices(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deviceID := vars["id"]

	h.mu.RLock()
	_, exists := h.devices[deviceID]
	h.mu.RUnlock()

	w.Header().Set("Content-Type", "application/json")

	if !exists {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]string{"error": "Device not found"})
		return
	}

	services := []map[string]interface{}{
		{
			"type":            "lightbulb",
			"characteristics": []string{"on", "brightness", "hue", "saturation"},
		},
		{
			"type":            "accessory-information",
			"characteristics": []string{"identify", "manufacturer", "model", "name", "serial-number"},
		},
	}

	json.NewEncoder(w).Encode(services)
}

func (h *HomeKitMicroservice) Run(port int) {
	h.setupRoutes()
	addr := fmt.Sprintf(":%d", port)
	log.Printf("HomeKit microservice listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, h.router))
}

func main() {
	service := NewHomeKitMicroservice()
	service.Run(8082)
}
