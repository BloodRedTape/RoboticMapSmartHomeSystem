import struct
import zlib
from typing import Dict, List, Any, Optional, Tuple
import logging

logger = logging.getLogger(__name__)

class MapProcessor:
    CHARGER = 1
    IMAGE = 2
    PATH = 3
    GOTO_PATH = 4
    GOTO_PREDICTED_PATH = 5
    CURRENTLY_CLEANED_ZONES = 6
    GOTO_TARGET = 7
    ROBOT_POSITION = 8
    NO_GO_AREAS = 9
    VIRTUAL_WALLS = 10
    BLOCKS = 11
    NO_MOP_AREAS = 12
    OBSTACLES = 13
    IGNORED_OBSTACLES = 14
    OBSTACLES_WITH_PHOTO = 15
    CARPET_MAP = 16

    @staticmethod
    def parse_map(raw_data: bytes) -> Optional[Dict[str, Any]]:
        try:
            if raw_data[:2] == b'\x1f\x8b':
                raw_data = zlib.decompress(raw_data)

            if len(raw_data) < 0x30:
                logger.error("Map data too short")
                return None

            header = struct.unpack('<2H5I', raw_data[0:0x1C])

            map_data = {
                "header": {
                    "map_index": header[0],
                    "map_sequence": header[1],
                },
                "image": None,
                "robot_position": None,
                "charger_position": None,
                "path": [],
                "goto_path": [],
                "goto_target": None,
                "no_go_areas": [],
                "virtual_walls": [],
                "blocks": [],
                "obstacles": [],
            }

            offset = 0x14

            while offset < len(raw_data):
                if offset + 4 > len(raw_data):
                    break

                block_type = struct.unpack('<H', raw_data[offset:offset+2])[0]
                block_length = struct.unpack('<H', raw_data[offset+2:offset+4])[0]

                offset += 4

                if offset + block_length > len(raw_data):
                    break

                block_data = raw_data[offset:offset+block_length]

                if block_type == MapProcessor.IMAGE:
                    map_data["image"] = MapProcessor._parse_image(block_data)
                elif block_type == MapProcessor.ROBOT_POSITION:
                    map_data["robot_position"] = MapProcessor._parse_position(block_data)
                elif block_type == MapProcessor.CHARGER:
                    map_data["charger_position"] = MapProcessor._parse_position(block_data)
                elif block_type == MapProcessor.PATH:
                    map_data["path"] = MapProcessor._parse_path(block_data)
                elif block_type == MapProcessor.GOTO_PATH:
                    map_data["goto_path"] = MapProcessor._parse_path(block_data)
                elif block_type == MapProcessor.GOTO_TARGET:
                    map_data["goto_target"] = MapProcessor._parse_position(block_data)
                elif block_type == MapProcessor.NO_GO_AREAS:
                    map_data["no_go_areas"] = MapProcessor._parse_areas(block_data)
                elif block_type == MapProcessor.VIRTUAL_WALLS:
                    map_data["virtual_walls"] = MapProcessor._parse_walls(block_data)
                elif block_type == MapProcessor.BLOCKS:
                    map_data["blocks"] = MapProcessor._parse_blocks(block_data)
                elif block_type == MapProcessor.OBSTACLES:
                    map_data["obstacles"] = MapProcessor._parse_obstacles(block_data)

                offset += block_length

            return map_data

        except Exception as e:
            logger.error(f"Error parsing map: {e}")
            return None

    @staticmethod
    def _parse_image(data: bytes) -> Optional[Dict[str, Any]]:
        if len(data) < 28:
            return None

        header = struct.unpack('<7I', data[0:28])

        top = header[0]
        left = header[1]
        height = header[2]
        width = header[3]

        pixel_data = data[28:]

        return {
            "top": top,
            "left": left,
            "height": height,
            "width": width,
            "pixels": list(pixel_data),
        }

    @staticmethod
    def _parse_position(data: bytes) -> Optional[Tuple[float, float, float]]:
        if len(data) < 12:
            return None

        x, y, angle = struct.unpack('<3I', data[0:12])

        return (x / 1000.0, y / 1000.0, angle / 100.0)

    @staticmethod
    def _parse_path(data: bytes) -> List[Tuple[float, float]]:
        if len(data) < 16:
            return []

        num_points = struct.unpack('<I', data[12:16])[0]
        path = []

        offset = 16
        for i in range(num_points):
            if offset + 8 > len(data):
                break
            x, y = struct.unpack('<2I', data[offset:offset+8])
            path.append((x / 1000.0, y / 1000.0))
            offset += 8

        return path

    @staticmethod
    def _parse_areas(data: bytes) -> List[Dict[str, float]]:
        if len(data) < 4:
            return []

        num_areas = struct.unpack('<I', data[0:4])[0]
        areas = []

        offset = 4
        for i in range(num_areas):
            if offset + 16 > len(data):
                break
            x1, y1, x2, y2 = struct.unpack('<4I', data[offset:offset+16])
            areas.append({
                "x1": x1 / 1000.0,
                "y1": y1 / 1000.0,
                "x2": x2 / 1000.0,
                "y2": y2 / 1000.0,
            })
            offset += 16

        return areas

    @staticmethod
    def _parse_walls(data: bytes) -> List[Dict[str, float]]:
        if len(data) < 4:
            return []

        num_walls = struct.unpack('<I', data[0:4])[0]
        walls = []

        offset = 4
        for i in range(num_walls):
            if offset + 16 > len(data):
                break
            x1, y1, x2, y2 = struct.unpack('<4I', data[offset:offset+16])
            walls.append({
                "x1": x1 / 1000.0,
                "y1": y1 / 1000.0,
                "x2": x2 / 1000.0,
                "y2": y2 / 1000.0,
            })
            offset += 16

        return walls

    @staticmethod
    def _parse_blocks(data: bytes) -> List[int]:
        if len(data) < 4:
            return []

        num_blocks = struct.unpack('<I', data[0:4])[0]
        return list(struct.unpack(f'<{num_blocks}I', data[4:4+num_blocks*4]))

    @staticmethod
    def _parse_obstacles(data: bytes) -> List[Dict[str, Any]]:
        if len(data) < 4:
            return []

        num_obstacles = struct.unpack('<I', data[0:4])[0]
        obstacles = []

        offset = 4
        for i in range(num_obstacles):
            if offset + 12 > len(data):
                break
            x, y, obstacle_type = struct.unpack('<2IH', data[offset:offset+10])
            obstacles.append({
                "x": x / 1000.0,
                "y": y / 1000.0,
                "type": obstacle_type,
            })
            offset += 12

        return obstacles

    @staticmethod
    def convert_to_common_format(roborock_map: Dict[str, Any]) -> Dict[str, Any]:
        common_map = {
            "width": 0,
            "height": 0,
            "resolution": 0.05,
            "origin_x": 0,
            "origin_y": 0,
            "pixels": [],
            "robot_position": None,
            "charger_position": None,
        }

        if roborock_map.get("image"):
            img = roborock_map["image"]
            common_map["width"] = img["width"]
            common_map["height"] = img["height"]
            common_map["origin_x"] = img["left"] / 1000.0
            common_map["origin_y"] = img["top"] / 1000.0
            common_map["pixels"] = img["pixels"]

        if roborock_map.get("robot_position"):
            x, y, angle = roborock_map["robot_position"]
            common_map["robot_position"] = {"x": x, "y": y, "angle": angle}

        if roborock_map.get("charger_position"):
            x, y, angle = roborock_map["charger_position"]
            common_map["charger_position"] = {"x": x, "y": y, "angle": angle}

        return common_map
