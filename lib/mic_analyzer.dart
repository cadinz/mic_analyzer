import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MicAnalyzer {
  static const MethodChannel _channel =
      const MethodChannel('mic_analyzer');

  Future<String> getPlatformVersion() async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<double> getAmplitude() async {
    final double amplitude = await _channel.invokeMethod('getAmplitude');
    return amplitude;
  }

  Future<double> getFrequency() async {
    final double amplitude = await _channel.invokeMethod('getFrequency');
    return amplitude;
  }

  Future<void> init() async {
    await _channel.invokeMethod('init');
    debugPrint('init true');
  }

  Future<void> start() async {
    await _channel.invokeMethod('start');
    debugPrint('start true');
  }


}
