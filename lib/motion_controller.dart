//lib/motion_controller.dart

import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum HeadGesture { skip, correct }

class MotionController {
  final _gestureController = StreamController<HeadGesture>.broadcast();
  final _positionController = StreamController<bool>.broadcast();
  
  Stream<HeadGesture> get gestureStream => _gestureController.stream;
  Stream<bool> get positionStream => _positionController.stream;

  static const double skipAngle = 30;       // tilt UP
  static const double correctAngle = -30;   // tilt DOWN
  static const double neutralZone = 15;     // ±15°
  static const int stableMs = 300;

  // Position detection thresholds
  static const double foreheadMinPitch = -100;  // Phone tilted back (on forehead)
  static const double foreheadMaxPitch = -50;   // Range for forehead position
  
  bool _canDetect = true;
  DateTime _lastStable = DateTime.now();
  bool _lastPositionState = false;

  MotionController() {
    accelerometerEvents.listen(_onAccelerometer);
  }

  void _onAccelerometer(AccelerometerEvent e) {
    final pitch = _calculatePitch(e.x, e.y, e.z);

    // Check if phone is in forehead position (tilted back significantly)
    final isInPosition = pitch >= foreheadMinPitch && pitch <= foreheadMaxPitch;
    
    // Only emit position changes to reduce stream updates
    if (isInPosition != _lastPositionState) {
      _lastPositionState = isInPosition;
      _positionController.add(isInPosition);
    }

    // Don't process gestures if not in position
    if (!isInPosition) {
      _canDetect = true; // Reset detection when not in position
      return;
    }

    // Check neutral stability
    if (pitch.abs() < neutralZone) {
      if (!_canDetect &&
          DateTime.now().difference(_lastStable).inMilliseconds > stableMs) {
        _canDetect = true;
      }
      _lastStable = DateTime.now();
      return;
    }

    if (!_canDetect) return;

    if (pitch > skipAngle) {
      _canDetect = false;
      _gestureController.add(HeadGesture.skip);
    } else if (pitch < correctAngle) {
      _canDetect = false;
      _gestureController.add(HeadGesture.correct);
    }
  }

  double _calculatePitch(double x, double y, double z) {
    return atan2(-x, sqrt(y * y + z * z)) * 180 / pi;
  }

  void dispose() {
    
    _gestureController.close();
    _positionController.close();
  }
}

