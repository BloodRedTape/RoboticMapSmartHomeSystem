Smart Home Map Flutter App

Flutter application that displays smart home map data from the backend API.

Setup

Install dependencies:
flutter pub get

Run the app:
flutter run

Make sure the backend server is running on http://localhost:8000 before starting the app.

Features

View Mode:
- Fetches map data from backend API
- Custom painter to render rooms, walls, charger, and vacuum position
- Different colors for each room
- Real-time map updates via refresh button
- Responsive layout with map information panel

Edit Mode:
- Interactive map editor with multiple tools
- Add new rooms by dragging on canvas
- Edit room names by tapping rooms in edit mode
- Delete rooms by tapping in delete mode
- Draw walls between any two points
- Visual feedback for drawing operations
- Save changes to backend with persistence

Architecture

lib/
  models/ - Data models (MapData, Room, Wall, Point, EditMode, EditState)
  services/ - API service for backend communication
  widgets/ - Custom painters for map rendering (view and interactive)
  screens/ - Map screen and editor screen UI
  main.dart - App entry point

The app uses HTTP client to fetch and save JSON data from the backend. CustomPainter renders the map on canvas with support for interactive editing through GestureDetector.