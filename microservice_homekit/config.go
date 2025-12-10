package main

import (
	"os"
	"strconv"
)

type Config struct {
	ListenHost        string
	ListenPort        int
	BackendURL        string
	LogLevel          string
	StoragePath       string
	BridgePin         string
	BridgeName        string
	BridgeManufacturer string
	BridgeModel       string
	ReconnectInterval int
}

func LoadConfig() *Config {
	return &Config{
		ListenHost:        getEnv("LISTEN_HOST", "0.0.0.0"),
		ListenPort:        getEnvInt("LISTEN_PORT", 5583),
		BackendURL:        getEnv("BACKEND_URL", "http://localhost:8080"),
		LogLevel:          getEnv("LOG_LEVEL", "INFO"),
		StoragePath:       getEnv("STORAGE_PATH", "./data"),
		BridgePin:         getEnv("BRIDGE_PIN", "00102003"),
		BridgeName:        getEnv("BRIDGE_NAME", "SmartHome Bridge"),
		BridgeManufacturer: getEnv("BRIDGE_MANUFACTURER", "SmartHome"),
		BridgeModel:       getEnv("BRIDGE_MODEL", "Bridge v1.0"),
		ReconnectInterval: getEnvInt("RECONNECT_INTERVAL", 5),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}
