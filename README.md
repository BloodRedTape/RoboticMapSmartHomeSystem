# Smart Home Map Viewer

## Backend (Python FastAPI)

1. Install dependencies:
```bash
cd backend_python
pip install -r requirements.txt
```

2. Parse map data (one time):
```bash
python parse_map.py
```

3. Run server:
```bash
python server.py
```

Server will run on http://localhost:5000

## Frontend (Flutter)

1. Get dependencies:
```bash
cd frontend_flutter
flutter pub get
```

2. Run app:
```bash
flutter run -d chrome
```

Make sure backend is running before starting frontend.
