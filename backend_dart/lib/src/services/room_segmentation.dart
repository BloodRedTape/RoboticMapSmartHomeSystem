import 'dart:collection';
import 'dart:math';

import 'package:dart_common/dart_common.dart';

// Helper class for integer points, similar to C#'s Tuple<int, int>
class PointInt {
  final int x;
  final int y;

  const PointInt(this.x, this.y);

  @override
  bool operator ==(Object other) => identical(this, other) || other is PointInt && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '($x, $y)';
}

class RoomSegmentation {
  List<List<Map<String, int>>> segmentRooms(List<Map<String, int>> walls, int width, int height, List<Door>? userDoors) {
    final wallSet = walls.map((w) => PointInt(w["x"]!, w["y"]!)).toSet();

    Set<PointInt> doors;
    if (userDoors != null && userDoors.isNotEmpty) {
      doors = _convertUserDoorsToBlocks(userDoors);
    } else {
      doors = _detectDoorways(wallSet, width, height);
    }

    final augmentedWalls = Set<PointInt>.from(wallSet);
    augmentedWalls.addAll(doors);

    var initialRooms = _floodFillRooms(augmentedWalls, width, height);
    var filteredRooms = _filterExteriorSpace(initialRooms, width, height);

    var mergedRooms = filteredRooms;
    while (true) {
      int roomsCountBefore = mergedRooms.length;
      mergedRooms = _mergeSmallEnclosedAreas(mergedRooms, doors);
      int roomsCountAfter = mergedRooms.length;

      if (roomsCountBefore == roomsCountAfter) {
        break;
      }
    }

    return mergedRooms;
  }

  Set<PointInt> _convertUserDoorsToBlocks(List<Door> userDoors) {
    final doorBlocks = <PointInt>{};
    for (var door in userDoors) {
      int x0 = door.x0, y0 = door.y0, x1 = door.x1, y1 = door.y1;
      int dx = (x1 - x0).abs(), sx = x0 < x1 ? 1 : -1;
      int dy = -(y1 - y0).abs(), sy = y0 < y1 ? 1 : -1;
      int err = dx + dy, e2;

      while (true) {
        doorBlocks.add(PointInt(x0, y0));
        if (x0 == x1 && y0 == y1) break;
        e2 = 2 * err;
        if (e2 >= dy) {
          err += dy;
          x0 += sx;
        }
        if (e2 <= dx) {
          err += dx;
          y0 += sy;
        }
      }
    }
    return doorBlocks;
  }

  Set<PointInt> _detectDoorways(Set<PointInt> wallSet, int width, int height, {int minDoorWidth = 1, int maxDoorWidth = 3}) {
    final doors = <PointInt>{};
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (wallSet.contains(PointInt(x, y))) continue;

        bool hasWallAbove = List.generate(3, (i) => i + 1).any((dy) => wallSet.contains(PointInt(x, y - dy)));
        bool hasWallBelow = List.generate(3, (i) => i + 1).any((dy) => wallSet.contains(PointInt(x, y + dy)));

        if (hasWallAbove && hasWallBelow) {
          int passageWidth = _measurePassageWidth(x, y, wallSet, "horizontal");
          if (passageWidth >= minDoorWidth && passageWidth <= maxDoorWidth) {
            if (_isOpenSpace(x - 1, y, wallSet) && _isOpenSpace(x + 1, y, wallSet)) {
              doors.add(PointInt(x, y));
              continue;
            }
          }
        }

        bool hasWallLeft = List.generate(3, (i) => i + 1).any((dx) => wallSet.contains(PointInt(x - dx, y)));
        bool hasWallRight = List.generate(3, (i) => i + 1).any((dx) => wallSet.contains(PointInt(x + dx, y)));

        if (hasWallLeft && hasWallRight) {
          int passageWidth = _measurePassageWidth(x, y, wallSet, "vertical");
          if (passageWidth >= minDoorWidth && passageWidth <= maxDoorWidth) {
            if (_isOpenSpace(x, y - 1, wallSet) && _isOpenSpace(x, y + 1, wallSet)) {
              doors.add(PointInt(x, y));
            }
          }
        }
      }
    }
    return doors;
  }

  int _measurePassageWidth(int x, int y, Set<PointInt> wallSet, String direction) {
    int width = 1;
    if (direction == "horizontal") {
      int left = 0;
      while (!wallSet.contains(PointInt(x - left - 1, y)) && left < 5) left++;
      int right = 0;
      while (!wallSet.contains(PointInt(x + right + 1, y)) && right < 5) right++;
      width = left + right + 1;
    } else {
      // vertical
      int up = 0;
      while (!wallSet.contains(PointInt(x, y - up - 1)) && up < 5) up++;
      int down = 0;
      while (!wallSet.contains(PointInt(x, y + down + 1)) && down < 5) down++;
      width = up + down + 1;
    }
    return width;
  }

  bool _isOpenSpace(int x, int y, Set<PointInt> wallSet) {
    return !wallSet.contains(PointInt(x, y));
  }

  List<List<Map<String, int>>> _floodFillRooms(Set<PointInt> wallSet, int width, int height) {
    final visited = <PointInt>{};
    final rooms = <List<Map<String, int>>>[];

    bool isValid(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;
    bool isWalkable(int x, int y) => !wallSet.contains(PointInt(x, y)) && !visited.contains(PointInt(x, y));

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (isValid(x, y) && isWalkable(x, y)) {
          var room = <Map<String, int>>[];
          var queue = Queue<PointInt>();
          queue.add(PointInt(x, y));
          visited.add(PointInt(x, y));

          while (queue.isNotEmpty) {
            var current = queue.removeFirst();
            room.add({"x": current.x, "y": current.y});

            // Directions: Up, Right, Down, Left
            for (var move in [PointInt(0, 1), PointInt(1, 0), PointInt(0, -1), PointInt(-1, 0)]) {
              int nx = current.x + move.x;
              int ny = current.y + move.y;
              if (isValid(nx, ny) && isWalkable(nx, ny)) {
                visited.add(PointInt(nx, ny));
                queue.add(PointInt(nx, ny));
              }
            }
          }
          if (room.length > 10) rooms.add(room);
        }
      }
    }
    return rooms;
  }

  List<List<Map<String, int>>> _mergeSmallEnclosedAreas(List<List<Map<String, int>>> rooms, Set<PointInt> doors, {int minRoomSize = 100}) {
    if (rooms.isEmpty) return rooms;

    var mergedRooms = rooms.map((r) => List<Map<String, int>>.from(r)).toList();
    var roomSets = mergedRooms.map((r) => r.map((b) => PointInt(b["x"]!, b["y"]!)).toSet()).toList();

    bool changed = true;
    while (changed) {
      changed = false;
      int i = 0;
      while (i < mergedRooms.length) {
        int j = i + 1;
        while (j < mergedRooms.length) {
          int adjacentCount = _countAdjacentBlocks(roomSets[i], roomSets[j], doors);
          if (adjacentCount > 0) {
            mergedRooms[i].addAll(mergedRooms[j]);
            roomSets[i].addAll(roomSets[j]);
            mergedRooms.removeAt(j);
            roomSets.removeAt(j);
            changed = true;
          } else {
            j++;
          }
        }
        i++;
      }
    }
    return mergedRooms;
  }

  int _countAdjacentBlocks(Set<PointInt> area1, Set<PointInt> area2, Set<PointInt> doors) {
    doors = doors; // Ensure it's not null, though it should be handled by default parameter if needed.
    int adjacentCount = 0;

    for (var p1 in area1) {
      for (var move in [PointInt(0, 1), PointInt(1, 0), PointInt(0, -1), PointInt(-1, 0)]) {
        var nx = p1.x + move.x;
        var ny = p1.y + move.y;
        if (area2.contains(PointInt(nx, ny)) && !doors.contains(PointInt(nx, ny))) {
          adjacentCount++;
        }
      }
      for (var move in [PointInt(0, 2), PointInt(2, 0), PointInt(0, -2), PointInt(-2, 0)]) {
        var nx = p1.x + move.x;
        var ny = p1.y + move.y;
        if (area2.contains(PointInt(nx, ny))) {
          var midX = p1.x + (move.x ~/ 2);
          var midY = p1.y + (move.y ~/ 2);
          if (!doors.contains(PointInt(midX, midY))) {
            adjacentCount++;
          }
        }
      }
    }
    return adjacentCount;
  }

  Map<String, double> calculateRoomBounds(List<Map<String, int>> roomBlocks) {
    if (roomBlocks.isEmpty) return {"x0": 0, "y0": 0, "x1": 0, "y1": 0};

    int minX = roomBlocks.first["x"]!;
    int minY = roomBlocks.first["y"]!;
    int maxX = roomBlocks.first["x"]!;
    int maxY = roomBlocks.first["y"]!;

    for (var block in roomBlocks) {
      minX = min(minX, block["x"]!);
      minY = min(minY, block["y"]!);
      maxX = max(maxX, block["x"]!);
      maxY = max(maxY, block["y"]!);
    }

    return {"x0": minX.toDouble(), "y0": minY.toDouble(), "x1": maxX.toDouble(), "y1": maxY.toDouble()};
  }

  List<List<Map<String, int>>> mergeSmallRooms(List<List<Map<String, int>>> rooms, {int minSize = 100}) {
    return rooms.where((r) => r.length >= minSize).toList();
  }

  List<Map<String, int>> blocksToRectangles(List<Map<String, int>> blocks) {
    if (blocks.isEmpty) return [];

    final blocksSet = blocks.map((b) => PointInt(b["x"]!, b["y"]!)).toSet();
    final visited = <PointInt>{};
    final rectangles = <Map<String, int>>[];
    final sortedBlocks = List<Map<String, int>>.from(blocks)..sort((a, b) {
      final yComparison = a["y"]!.compareTo(b["y"]!);
      if (yComparison != 0) return yComparison;
      return a["x"]!.compareTo(b["x"]!);
    });

    for (var block in sortedBlocks) {
      var x = block["x"]!;
      var y = block["y"]!;
      final currentPoint = PointInt(x, y);

      if (visited.contains(currentPoint)) continue;

      int width = 1;
      while (blocksSet.contains(PointInt(x + width, y)) && !visited.contains(PointInt(x + width, y)) && (x + width) < 1000) {
        // Added boundary check
        width++;
      }

      int height = 1;
      bool canExpand = true;
      while (canExpand && (y + height) < 1000) {
        // Added boundary check
        for (int dx = 0; dx < width; dx++) {
          if (!blocksSet.contains(PointInt(x + dx, y + height)) || visited.contains(PointInt(x + dx, y + height))) {
            canExpand = false;
            break;
          }
        }
        if (canExpand) height++;
      }

      for (int dy = 0; dy < height; dy++) {
        for (int dx = 0; dx < width; dx++) {
          visited.add(PointInt(x + dx, y + dy));
        }
      }

      rectangles.add({"x": x, "y": y, "width": width, "height": height});
    }
    return rectangles;
  }

  List<List<Map<String, int>>> _filterExteriorSpace(List<List<Map<String, int>>> rooms, int width, int height) {
    if (rooms.isEmpty) return rooms;

    var edgeRooms = <List<Map<String, int>>>[];
    var interiorRooms = <List<Map<String, int>>>[];

    for (var room in rooms) {
      bool touchesEdge = room.any((b) => b["x"] == 0 || b["y"] == 0 || b["x"]! >= width - 1 || b["y"]! >= height - 1);
      if (touchesEdge) {
        edgeRooms.add(room);
      } else {
        interiorRooms.add(room);
      }
    }

    if (edgeRooms.isNotEmpty) {
      var largestEdgeRoom = edgeRooms.reduce((a, b) => a.length > b.length ? a : b);
      edgeRooms.remove(largestEdgeRoom);
      interiorRooms.addAll(edgeRooms);
    }

    return interiorRooms;
  }
}
