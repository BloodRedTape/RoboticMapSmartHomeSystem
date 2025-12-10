from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

class CommandExecutor:
    def __init__(self, roborock_client):
        self.roborock_client = roborock_client

    async def execute_command(self, device_id: str, command: str, params: Dict[str, Any]) -> bool:
        try:
            if command == "start":
                return await self._start_cleaning(device_id)
            elif command == "pause":
                return await self._pause_cleaning(device_id)
            elif command == "stop":
                return await self._stop_cleaning(device_id)
            elif command == "return_to_dock":
                return await self._return_to_dock(device_id)
            elif command == "locate":
                return await self._locate(device_id)
            elif command == "clean_zone":
                return await self._clean_zone(device_id, params)
            elif command == "clean_segment":
                return await self._clean_segment(device_id, params)
            elif command == "goto":
                return await self._goto(device_id, params)
            elif command == "set_fan_speed":
                return await self._set_fan_speed(device_id, params)
            elif command == "set_water_flow":
                return await self._set_water_flow(device_id, params)
            else:
                logger.warning(f"Unknown command: {command}")
                return False
        except Exception as e:
            logger.error(f"Error executing command {command} on device {device_id}: {e}")
            return False

    async def _start_cleaning(self, device_id: str) -> bool:
        await self.roborock_client.send_command(device_id, "app_start")
        logger.info(f"Started cleaning on device {device_id}")
        return True

    async def _pause_cleaning(self, device_id: str) -> bool:
        await self.roborock_client.send_command(device_id, "app_pause")
        logger.info(f"Paused cleaning on device {device_id}")
        return True

    async def _stop_cleaning(self, device_id: str) -> bool:
        await self.roborock_client.send_command(device_id, "app_stop")
        logger.info(f"Stopped cleaning on device {device_id}")
        return True

    async def _return_to_dock(self, device_id: str) -> bool:
        await self.roborock_client.send_command(device_id, "app_charge")
        logger.info(f"Returning to dock on device {device_id}")
        return True

    async def _locate(self, device_id: str) -> bool:
        await self.roborock_client.send_command(device_id, "find_me")
        logger.info(f"Locating device {device_id}")
        return True

    async def _clean_zone(self, device_id: str, params: Dict[str, Any]) -> bool:
        zones = params.get("zones", [])
        if not zones:
            logger.error("No zones provided for zone cleaning")
            return False

        zone_params = []
        for zone in zones:
            x1, y1 = int(zone["x1"] * 1000), int(zone["y1"] * 1000)
            x2, y2 = int(zone["x2"] * 1000), int(zone["y2"] * 1000)
            repeat = zone.get("repeat", 1)
            zone_params.extend([x1, y1, x2, y2, repeat])

        await self.roborock_client.send_command(device_id, "app_zoned_clean", zone_params)
        logger.info(f"Started zone cleaning on device {device_id}")
        return True

    async def _clean_segment(self, device_id: str, params: Dict[str, Any]) -> bool:
        segments = params.get("segments", [])
        if not segments:
            logger.error("No segments provided for segment cleaning")
            return False

        await self.roborock_client.send_command(device_id, "app_segment_clean", segments)
        logger.info(f"Started segment cleaning on device {device_id}")
        return True

    async def _goto(self, device_id: str, params: Dict[str, Any]) -> bool:
        x = params.get("x")
        y = params.get("y")

        if x is None or y is None:
            logger.error("Missing x or y coordinate for goto command")
            return False

        x_scaled = int(x * 1000)
        y_scaled = int(y * 1000)

        await self.roborock_client.send_command(device_id, "app_goto_target", [x_scaled, y_scaled])
        logger.info(f"Sending device {device_id} to position ({x}, {y})")
        return True

    async def _set_fan_speed(self, device_id: str, params: Dict[str, Any]) -> bool:
        fan_speed = params.get("fan_speed")

        if fan_speed is None:
            logger.error("Missing fan_speed parameter")
            return False

        speed_mapping = {
            "silent": 101,
            "standard": 102,
            "medium": 103,
            "turbo": 104,
            "max": 105,
        }

        if isinstance(fan_speed, str):
            fan_speed = speed_mapping.get(fan_speed, 102)

        await self.roborock_client.send_command(device_id, "set_custom_mode", [fan_speed])
        logger.info(f"Set fan speed to {fan_speed} on device {device_id}")
        return True

    async def _set_water_flow(self, device_id: str, params: Dict[str, Any]) -> bool:
        water_flow = params.get("water_flow")

        if water_flow is None:
            logger.error("Missing water_flow parameter")
            return False

        flow_mapping = {
            "low": 200,
            "medium": 201,
            "high": 202,
        }

        if isinstance(water_flow, str):
            water_flow = flow_mapping.get(water_flow, 201)

        await self.roborock_client.send_command(device_id, "set_water_box_custom_mode", [water_flow])
        logger.info(f"Set water flow to {water_flow} on device {device_id}")
        return True
