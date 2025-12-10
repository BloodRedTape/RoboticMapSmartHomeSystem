import cv2
import numpy as np
from ultralytics import YOLO
from deep_sort_realtime.deepsort_tracker import DeepSort
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
import base64
import requests

app = Flask(__name__)
CORS(app)

VIDEO_PATH = '../demo/input2.mp4'
CALIBRATION_FILE = 'calibration.json'
BACKEND_URL = 'http://localhost:5000'

model = YOLO('yolov8n.pt', verbose=False)
tracker = DeepSort(max_age=30, n_init=3, max_iou_distance=0.7)

homography_matrix = None
calibration_data = None
track_to_human_map = {}
image_dimensions = None

def load_map_data():
    global image_dimensions
    try:
        response = requests.get(f'{BACKEND_URL}/api/map', timeout=5)
        if response.status_code == 200:
            map_data = response.json()
            image_dimensions = map_data.get('image_dimensions')
            print(f"Loaded map dimensions: {image_dimensions}")
    except Exception as e:
        print(f"Error loading map data: {e}")

def load_calibration():
    global homography_matrix, calibration_data
    if os.path.exists(CALIBRATION_FILE):
        with open(CALIBRATION_FILE, 'r') as f:
            calibration_data = json.load(f)
            if 'matrix' in calibration_data:
                homography_matrix = np.array(calibration_data['matrix'])

def save_calibration(camera_points, map_points, matrix):
    with open(CALIBRATION_FILE, 'w') as f:
        json.dump({
            'camera_points': camera_points,
            'map_points': map_points,
            'matrix': matrix.tolist()
        }, f, indent=2)

def transform_point(x, y):
    if homography_matrix is None:
        return None

    point = np.array([[[x, y]]], dtype=np.float32)
    transformed = cv2.perspectiveTransform(point, homography_matrix)
    return (float(transformed[0][0][0]), float(transformed[0][0][1]))

def block_to_world_coords(block_x, block_y):
    if image_dimensions is None:
        return (block_x, block_y)

    offset_x = image_dimensions.get('left', 0)
    offset_y = image_dimensions.get('top', 0)
    image_height = image_dimensions.get('height', 0)

    world_x = (block_x + offset_x) * 50.0
    world_y = (image_height - block_y + offset_y) * 50.0

    return (world_x, world_y)

@app.route('/api/first_frame', methods=['GET'])
def get_first_frame():
    if not os.path.exists(VIDEO_PATH):
        return jsonify({'error': 'Video file not found'}), 404

    cap = cv2.VideoCapture(VIDEO_PATH)
    ret, frame = cap.read()
    cap.release()

    if not ret:
        return jsonify({'error': 'Failed to read video'}), 500

    _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
    frame_base64 = base64.b64encode(buffer).decode('utf-8')

    return jsonify({
        'frame_base64': frame_base64,
        'width': frame.shape[1],
        'height': frame.shape[0]
    })

@app.route('/api/calibrate', methods=['POST'])
def calibrate():
    global homography_matrix, calibration_data

    data = request.json
    camera_points = data.get('camera_points', [])
    map_points = data.get('map_points', [])

    if len(camera_points) < 4 or len(camera_points) != len(map_points):
        return jsonify({'error': 'At least 4 corresponding points required'}), 400

    camera_points_list = [(p['x'], p['y']) for p in camera_points]
    map_points_list = [(p['x'], p['y']) for p in map_points]

    src_pts = np.float32(camera_points_list)
    dst_pts = np.float32(map_points_list)

    matrix, status = cv2.findHomography(src_pts, dst_pts, cv2.RANSAC, 5.0)

    if matrix is None:
        return jsonify({'error': 'Calibration failed'}), 500

    homography_matrix = matrix
    calibration_data = {
        'camera_points': camera_points,
        'map_points': map_points
    }

    save_calibration(camera_points, map_points, matrix)

    return jsonify({'message': 'Calibrated successfully'})

@app.route('/api/calibration', methods=['GET'])
def get_calibration():
    if calibration_data is None:
        return jsonify({'error': 'Not calibrated'}), 404

    return jsonify(calibration_data)

def create_human_on_backend():
    try:
        response = requests.post(f'{BACKEND_URL}/api/humans', timeout=2)
        if response.status_code == 200:
            human_data = response.json()
            return human_data['id']
    except Exception as e:
        print(f"Error creating human: {e}")
    return None

def move_human_on_backend(human_id, x, y):
    try:
        requests.put(f'{BACKEND_URL}/api/humans/{human_id}/move',
                    json={'x': x, 'y': y},
                    timeout=2)
    except Exception as e:
        print(f"Error moving human {human_id}: {e}")

def delete_human_on_backend(human_id):
    try:
        requests.delete(f'{BACKEND_URL}/api/humans/{human_id}', timeout=2)
    except Exception as e:
        print(f"Error deleting human {human_id}: {e}")

@app.route('/api/process', methods=['POST'])
def process_video():
    global track_to_human_map

    if not os.path.exists(VIDEO_PATH):
        return jsonify({'error': 'Video file not found'}), 404

    cap = cv2.VideoCapture(VIDEO_PATH)

    track_to_human_map = {}
    previous_track_ids = set()
    frame_count = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        results = model(frame, classes=[0], conf=0.5, verbose=False)

        detections = []
        for result in results:
            boxes = result.boxes
            for box in boxes:
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                confidence = box.conf[0].cpu().numpy()
                bbox = [int(x1), int(y1), int(x2 - x1), int(y2 - y1)]
                detections.append((bbox, confidence, 'person'))

        tracks = tracker.update_tracks(detections, frame=frame)

        current_track_ids = set()

        for track in tracks:
            if not track.is_confirmed():
                continue

            track_id = track.track_id
            current_track_ids.add(track_id)

            bbox = track.to_ltrb()
            x1, y1, x2, y2 = int(bbox[0]), int(bbox[1]), int(bbox[2]), int(bbox[3])

            foot_x = (x1 + x2) // 2
            foot_y = y2

            if homography_matrix is not None:
                block_coords = transform_point(foot_x, foot_y)
                if block_coords:
                    block_x, block_y = block_coords
                    world_x, world_y = block_to_world_coords(block_x, block_y)

                    if track_id not in track_to_human_map:
                        human_id = create_human_on_backend()
                        if human_id:
                            track_to_human_map[track_id] = human_id
                            print(f"Created human {human_id} for track {track_id}")

                    if track_id in track_to_human_map:
                        human_id = track_to_human_map[track_id]
                        move_human_on_backend(human_id, world_x, world_y)

        disappeared_tracks = previous_track_ids - current_track_ids
        for track_id in disappeared_tracks:
            if track_id in track_to_human_map:
                human_id = track_to_human_map[track_id]
                delete_human_on_backend(human_id)
                del track_to_human_map[track_id]
                print(f"Deleted human {human_id} for track {track_id}")

        previous_track_ids = current_track_ids
        frame_count += 1

    for track_id, human_id in list(track_to_human_map.items()):
        delete_human_on_backend(human_id)
        print(f"Cleanup: Deleted human {human_id} for track {track_id}")

    track_to_human_map = {}
    cap.release()

    return jsonify({
        'total_frames': frame_count,
        'message': 'Processing complete'
    })

if __name__ == '__main__':
    load_map_data()
    load_calibration()
    app.run(host='0.0.0.0', port=5001, debug=True)
