import cv2
import numpy as np
from ultralytics import YOLO
import asyncio
import websockets
import json
from typing import Dict, List, Tuple

class RealtimePeoplePositioning:
    def __init__(self, camera_configs: Dict):
        self.model = YOLO('yolov8n.pt')
        self.camera_configs = camera_configs
        self.homography_matrices = {}
        self.active_detections = {}

    def calibrate_camera(self, camera_id: str, image_points: List[Tuple], map_points: List[Tuple]):
        """Калібрування камери через відповідність точок"""
        img_pts = np.float32(image_points)
        map_pts = np.float32(map_points)

        homography_matrix, _ = cv2.findHomography(img_pts, map_pts, cv2.RANSAC, 5.0)
        self.homography_matrices[camera_id] = homography_matrix

        return homography_matrix

    def detect_people(self, frame: np.ndarray) -> List[Tuple[int, int, int, int]]:
        """Детекція людей через YOLOv8"""
        results = self.model(frame, classes=[0], conf=0.5)

        detections = []
        for result in results:
            boxes = result.boxes
            for box in boxes:
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                detections.append((int(x1), int(y1), int(x2), int(y2)))

        return detections

    def get_foot_position(self, bbox: Tuple[int, int, int, int]) -> Tuple[float, float]:
        """Визначення позиції стоп людини (нижня середня точка bbox)"""
        x1, y1, x2, y2 = bbox
        foot_x = (x1 + x2) / 2
        foot_y = y2
        return foot_x, foot_y

    def project_to_map(self, camera_id: str, image_point: Tuple[float, float]) -> Tuple[int, int]:
        """Проєкція координат з камери на карту"""
        if camera_id not in self.homography_matrices:
            raise ValueError(f"Camera {camera_id} not calibrated")

        H = self.homography_matrices[camera_id]
        point = np.array([[image_point]], dtype=np.float32)

        transformed = cv2.perspectiveTransform(point, H)
        map_x, map_y = transformed[0][0]

        return int(map_x), int(map_y)

    async def process_camera_stream(self, camera_id: str, video_source: str):
        """Обробка відео потоку з камери"""
        cap = cv2.VideoCapture(video_source)

        while True:
            ret, frame = cap.read()
            if not ret:
                break

            detections = self.detect_people(frame)
            positions = []

            for detection in detections:
                foot_pos = self.get_foot_position(detection)

                try:
                    map_x, map_y = self.project_to_map(camera_id, foot_pos)
                    positions.append({
                        'camera_id': camera_id,
                        'x': map_x,
                        'y': map_y,
                        'confidence': 0.85
                    })
                except ValueError:
                    continue

            self.active_detections[camera_id] = positions

            await asyncio.sleep(0.033)

        cap.release()

    def merge_detections(self, threshold: int = 500) -> List[Dict]:
        """Об'єднання детекцій з різних камер"""
        all_positions = []
        for camera_detections in self.active_detections.values():
            all_positions.extend(camera_detections)

        merged = []
        used = set()

        for i, pos1 in enumerate(all_positions):
            if i in used:
                continue

            cluster = [pos1]
            used.add(i)

            for j, pos2 in enumerate(all_positions[i+1:], start=i+1):
                if j in used:
                    continue

                distance = np.sqrt((pos1['x'] - pos2['x'])**2 + (pos1['y'] - pos2['y'])**2)
                if distance < threshold:
                    cluster.append(pos2)
                    used.add(j)

            avg_x = int(np.mean([p['x'] for p in cluster]))
            avg_y = int(np.mean([p['y'] for p in cluster]))

            merged.append({
                'x': avg_x,
                'y': avg_y,
                'detection_count': len(cluster)
            })

        return merged

    async def send_positions_to_backend(self, backend_url: str):
        """Відправка позицій на backend через WebSocket"""
        async with websockets.connect(backend_url) as websocket:
            while True:
                merged_positions = self.merge_detections()

                message = {
                    'type': 'people_positions',
                    'data': merged_positions
                }

                await websocket.send(json.dumps(message))
                await asyncio.sleep(0.1)


async def main():
    camera_configs = {
        'living_room_cam': {
            'source': 'rtsp://192.168.1.100/stream',
            'position': (5000, 3000),
            'fov': 90
        },
        'kitchen_cam': {
            'source': 'rtsp://192.168.1.101/stream',
            'position': (8000, 6000),
            'fov': 110
        }
    }

    positioning = RealtimePeoplePositioning(camera_configs)

    positioning.calibrate_camera(
        'living_room_cam',
        image_points=[(100, 400), (540, 400), (100, 100), (540, 100)],
        map_points=[(4000, 2000), (6000, 2000), (4000, 4000), (6000, 4000)]
    )

    tasks = [
        positioning.process_camera_stream('living_room_cam', camera_configs['living_room_cam']['source']),
        positioning.process_camera_stream('kitchen_cam', camera_configs['kitchen_cam']['source']),
        positioning.send_positions_to_backend('ws://localhost:5000/ws')
    ]

    await asyncio.gather(*tasks)


if __name__ == '__main__':
    asyncio.run(main())
