Tracking Python Microservice

Simple REST API for video tracking with camera-to-map coordinate transformation using YOLOv8 and DeepSORT.
Integrates with Dart backend to create, update, and delete humans in real-time.

Installation

pip install -r requirements.txt

Usage

1. Place your video file as input.mp4 in demo/ directory
2. Start Dart backend on port 5000
3. Run the tracking service:
   python tracking_service.py
4. Service runs on http://localhost:5001

API Endpoints

GET /api/first_frame
Returns first frame of video as base64 JPEG for calibration UI
Response: {frame_base64, width, height}

POST /api/calibrate
Calibrate camera homography transformation
Body: {
  camera_points: [{x, y}, {x, y}, {x, y}, {x, y}],
  map_points: [{x, y}, {x, y}, {x, y}, {x, y}]
}
Minimum 4 point pairs required.
Calibration persists in calibration.json file.

GET /api/calibration
Get current calibration data
Response: {camera_points, map_points}

POST /api/process
Process entire video and sync humans with Dart backend
- Creates human on backend when track appears
- Updates human position on every frame
- Deletes human when track disappears
Response: {total_frames, message}

Backend Integration

The service communicates with Dart backend at http://localhost:5000:
- POST /api/humans - create new human
- PUT /api/humans/{id}/move - update human position
- DELETE /api/humans/{id} - delete human

Track ID to Human ID mapping is maintained locally during processing.
