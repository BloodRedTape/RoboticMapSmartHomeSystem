from typing import Dict, List, Any, Optional

MATTER_TO_COMMON_TYPES = {
    0x0100: "light",
    0x0101: "dimmer_light",
    0x010C: "color_light",
    0x010D: "extended_color_light",
    0x0302: "temperature_sensor",
    0x0015: "contact_sensor",
    0x0107: "occupancy_sensor",
    0x010A: "door_lock",
    0x0202: "thermostat",
    0x0303: "window_covering",
    0x0840: "pressure_sensor",
    0x0405: "humidity_sensor",
}

CLUSTER_TO_ATTRIBUTES = {
    0x0006: ["state"],
    0x0008: ["brightness"],
    0x0300: ["color_temp", "hue", "saturation"],
    0x0402: ["temperature"],
    0x0045: ["contact"],
    0x0406: ["occupancy"],
    0x0101: ["lock_state"],
    0x0201: ["target_temperature", "current_temperature", "mode"],
    0x0102: ["position"],
    0x0403: ["pressure"],
    0x0405: ["humidity"],
}

class DeviceMapper:
    @staticmethod
    def map_matter_device(matter_node: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        node_id = matter_node.get("node_id")
        device_type = matter_node.get("device_type_id")

        if device_type not in MATTER_TO_COMMON_TYPES:
            return None

        common_type = MATTER_TO_COMMON_TYPES[device_type]
        attributes = DeviceMapper._extract_attributes(matter_node)
        commands = DeviceMapper._get_available_commands(device_type)

        return {
            "id": f"matter_{node_id}",
            "type": common_type,
            "name": matter_node.get("name", f"Matter Device {node_id}"),
            "protocol": "matter",
            "attributes": attributes,
            "commands": commands,
            "metadata": {
                "node_id": node_id,
                "vendor_id": matter_node.get("vendor_id"),
                "product_id": matter_node.get("product_id"),
                "device_type_id": device_type,
            }
        }

    @staticmethod
    def _extract_attributes(matter_node: Dict[str, Any]) -> List[Dict[str, Any]]:
        attributes = []
        clusters = matter_node.get("clusters", [])

        for cluster in clusters:
            cluster_id = cluster.get("cluster_id")
            if cluster_id in CLUSTER_TO_ATTRIBUTES:
                for attr_name in CLUSTER_TO_ATTRIBUTES[cluster_id]:
                    attr_value = cluster.get("attributes", {}).get(attr_name)
                    if attr_value is not None:
                        attributes.append({
                            "name": attr_name,
                            "value": attr_value,
                            "type": DeviceMapper._get_attribute_type(attr_name)
                        })

        return attributes

    @staticmethod
    def _get_attribute_type(attr_name: str) -> str:
        type_mapping = {
            "state": "boolean",
            "brightness": "percentage",
            "color_temp": "color_temperature",
            "hue": "number",
            "saturation": "number",
            "temperature": "temperature",
            "contact": "boolean",
            "occupancy": "boolean",
            "lock_state": "boolean",
            "target_temperature": "temperature",
            "current_temperature": "temperature",
            "mode": "string",
            "position": "percentage",
            "pressure": "number",
            "humidity": "percentage",
        }
        return type_mapping.get(attr_name, "string")

    @staticmethod
    def _get_available_commands(device_type: int) -> List[str]:
        command_mapping = {
            0x0100: ["turn_on", "turn_off", "toggle"],
            0x0101: ["turn_on", "turn_off", "set_brightness"],
            0x010C: ["turn_on", "turn_off", "set_brightness", "set_color_temp"],
            0x010D: ["turn_on", "turn_off", "set_brightness", "set_color", "set_color_temp"],
            0x010A: ["lock", "unlock"],
            0x0202: ["set_temperature", "set_mode"],
            0x0303: ["open", "close", "set_position"],
        }
        return command_mapping.get(device_type, [])
