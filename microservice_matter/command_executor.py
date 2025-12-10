from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

class CommandExecutor:
    def __init__(self, matter_client):
        self.matter_client = matter_client

    async def execute_command(self, node_id: int, command: str, params: Dict[str, Any]) -> bool:
        try:
            if command == "turn_on":
                return await self._turn_on(node_id)
            elif command == "turn_off":
                return await self._turn_off(node_id)
            elif command == "toggle":
                return await self._toggle(node_id)
            elif command == "set_brightness":
                return await self._set_brightness(node_id, params.get("brightness"))
            elif command == "set_color_temp":
                return await self._set_color_temp(node_id, params.get("color_temp"))
            elif command == "set_color":
                return await self._set_color(node_id, params.get("hue"), params.get("saturation"))
            elif command == "lock":
                return await self._lock(node_id)
            elif command == "unlock":
                return await self._unlock(node_id)
            elif command == "set_temperature":
                return await self._set_temperature(node_id, params.get("temperature"))
            elif command == "set_mode":
                return await self._set_mode(node_id, params.get("mode"))
            elif command == "open":
                return await self._open(node_id)
            elif command == "close":
                return await self._close(node_id)
            elif command == "set_position":
                return await self._set_position(node_id, params.get("position"))
            else:
                logger.warning(f"Unknown command: {command}")
                return False
        except Exception as e:
            logger.error(f"Error executing command {command} on node {node_id}: {e}")
            return False

    async def _turn_on(self, node_id: int) -> bool:
        await self.matter_client.send_command(node_id, 0x0006, 0x01, {})
        return True

    async def _turn_off(self, node_id: int) -> bool:
        await self.matter_client.send_command(node_id, 0x0006, 0x00, {})
        return True

    async def _toggle(self, node_id: int) -> bool:
        await self.matter_client.send_command(node_id, 0x0006, 0x02, {})
        return True

    async def _set_brightness(self, node_id: int, brightness: int) -> bool:
        level = int(brightness * 2.54)
        await self.matter_client.send_command(node_id, 0x0008, 0x04, {"level": level, "transitionTime": 0})
        return True

    async def _set_color_temp(self, node_id: int, color_temp: int) -> bool:
        await self.matter_client.send_command(node_id, 0x0300, 0x0A, {"colorTemperature": color_temp, "transitionTime": 0})
        return True

    async def _set_color(self, node_id: int, hue: int, saturation: int) -> bool:
        await self.matter_client.send_command(node_id, 0x0300, 0x06, {"hue": hue, "saturation": saturation, "transitionTime": 0})
        return True

    async def _lock(self, node_id: int) -> bool:
        await self.matter_client.send_command(node_id, 0x0101, 0x00, {})
        return True

    async def _unlock(self, node_id: int) -> bool:
        await self.matter_client.send_command(node_id, 0x0101, 0x01, {})
        return True

    async def _set_temperature(self, node_id: int, temperature: float) -> bool:
        temp_scaled = int(temperature * 100)
        await self.matter_client.send_command(node_id, 0x0201, 0x00, {"occupiedHeatingSetpoint": temp_scaled})
        return True

    async def _set_mode(self, node_id: int, mode: str) -> bool:
        mode_mapping = {"off": 0, "heat": 4, "cool": 3, "auto": 1}
        mode_value = mode_mapping.get(mode, 0)
        await self.matter_client.send_command(node_id, 0x0201, 0x00, {"systemMode": mode_value})
        return True

    async def _open(self, node_id: int) -> bool:
        await self.matter_client.send_command(node_id, 0x0102, 0x00, {})
        return True

    async def _close(self, node_id: int) -> bool:
        await self.matter_client.send_command(node_id, 0x0102, 0x01, {})
        return True

    async def _set_position(self, node_id: int, position: int) -> bool:
        pos_scaled = int(position * 100)
        await self.matter_client.send_command(node_id, 0x0102, 0x05, {"liftPercent100thsValue": pos_scaled})
        return True
