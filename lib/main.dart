import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = '未请求';
  Position? _position;

  // 新增：流订阅与监听状态
  StreamSubscription<Position>? _positionSub;
  bool _watching = false;

  Future<bool> _ensureLocationPermission() async {
    // 1. 定位服务是否开启
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _status = '定位服务未开启，请开启系统定位';
      });
      await Geolocator.openLocationSettings();
      return false;
    }

    // 2. 检查并申请权限
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 3. 处理各种状态
    if (permission == LocationPermission.denied) {
      setState(() {
        _status = '用户拒绝了定位权限';
      });
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _status = '权限被永久拒绝，请在系统设置中手动开启';
      });
      await Geolocator.openAppSettings();
      return false;
    }

    // granted 或 whileInUse
    return true;
  }

  Future<Position?> _acquireAccurate({
    double targetAccuracyMeters = 10,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final ok = await _ensureLocationPermission();
    if (!ok) return null;

    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      setState(() {
        _position = last;
        _status = '已显示最近位置，正在搜星以提高精度…';
      });
    } else {
      setState(() {
        _status = '正在搜星获取位置…';
      });
    }

    final settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      intervalDuration: const Duration(seconds: 3),
      distanceFilter: 2,
      forceLocationManager: false,
    );

    final completer = Completer<Position?>();
    Position? best = last;

    late StreamSubscription<Position> sub;
    sub = Geolocator.getPositionStream(locationSettings: settings).listen((p) {
      if (best == null || p.accuracy < best!.accuracy) {
        best = p;
        setState(() {
          _position = best;
          _status = best!.accuracy <= targetAccuracyMeters
              ? '已达到精度阈值（≤${targetAccuracyMeters.toStringAsFixed(0)}m）'
              : '正在提高精度… 当前约 ${best!.accuracy.toStringAsFixed(1)} m';
        });
      }
      if (best != null && best!.accuracy <= targetAccuracyMeters) {
if (!completer.isCompleted) completer.complete(best);
      }
    });

    // 新增：15 秒无较好结果则切换到系统定位（适配无 Google Play 服务）
    final gmsFallbackTimer = Timer(const Duration(seconds: 15), () async {
      if (!completer.isCompleted && (best == null || best!.accuracy > 30)) {
        await sub.cancel();
        setState(() {
          _status = '未检测到 Google Play 服务，切换为系统定位…';
        });
        final lmSettings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          intervalDuration: const Duration(seconds: 3),
          distanceFilter: 2,
          forceLocationManager: true,
        );
        sub = Geolocator.getPositionStream(locationSettings: lmSettings).listen((p) {
          if (best == null || p.accuracy < best!.accuracy) {
            best = p;
            setState(() {
              _position = best;
              _status = best!.accuracy <= targetAccuracyMeters
                  ? '已达到精度阈值（≤${targetAccuracyMeters.toStringAsFixed(0)}m）'
                  : '正在提高精度… 当前约 ${best!.accuracy.toStringAsFixed(1)} m';
            });
          }
          if (best != null && best!.accuracy <= targetAccuracyMeters) {
            if (!completer.isCompleted) completer.complete(best);
          }
        });
      }
    });

    // 新增：30 秒"室内兜底"，避免一直等到硬超时
    final softTimer = Timer(const Duration(seconds: 30), () async {
      if (!completer.isCompleted && best != null && best!.accuracy <= 25) {
        setState(() {
          _status = '已采用室内兜底精度：≈${best!.accuracy.toStringAsFixed(1)} m';
        });
        completer.complete(best);
      }
    });

    final timer = Timer(timeout, () async {
      await sub.cancel();
      setState(() {
        _status = best == null
            ? '获取超时（${timeout.inSeconds}秒）。请到户外/开阔地再试，或开启Wi‑Fi辅助定位'
            : '已超时，采用当前最佳精度：≈${best!.accuracy.toStringAsFixed(1)} m';
      });
      if (!completer.isCompleted) completer.complete(best);
    });

    final result = await completer.future;
    if (timer.isActive) timer.cancel();
    if (softTimer.isActive) softTimer.cancel();
    if (gmsFallbackTimer.isActive) gmsFallbackTimer.cancel();
    await sub.cancel();
    return result;
  }

  Future<void> _requestAndGetOnce() async {
    setState(() {
      _status = '检查权限中...';
      _position = null;
    });

    final pos = await _acquireAccurate();
    if (pos == null) return;
    setState(() {
      _position = pos;
    });
  }

  // 新增：开始 5 秒一次监听
  Future<void> _startWatch() async {
    if (_watching) return;
    setState(() {
      _status = '检查权限中...';
    });
    final ok = await _ensureLocationPermission();
    if (!ok) return;

    // 仅针对 Android 的 5 秒间隔设置；若做跨平台可配合 AppleSettings
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 5),
      distanceFilter: 0,
      forceLocationManager: false,
    );

    setState(() {
      _status = '开始监听（每5秒）...';
      _watching = true;
    });

    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (pos) {
        setState(() {
          _position = pos;
          _status = '监听中（最近更新：${DateTime.now().toIso8601String()}）';
        });
        _uploadPosition(pos); // 在这里上传到数据库
      },
      onError: (e) {
        setState(() {
          _status = '监听错误：$e';
          _watching = false;
        });
      },
      cancelOnError: false,
    );
  }

  // 新增：停止监听
  Future<void> _stopWatch() async {
    await _positionSub?.cancel();
    _positionSub = null;
    setState(() {
      _watching = false;
      _status = '已停止监听';
    });
  }

  // 你可以把现有上传数据库的逻辑搬到这里
  Future<void> _uploadPosition(Position pos) async {
    // TODO: 调用你的后端/数据库接口，例如：
    // await yourApi.sendPosition(
    //   lat: pos.latitude,
    //   lon: pos.longitude,
    //   accuracy: pos.accuracy,
    //   time: pos.timestamp ?? DateTime.now(),
    // );
  }

  String _getAccuracyLevel(double accuracy) {
    if (accuracy <= 3) return '极高精度';
    if (accuracy <= 8) return '高精度';
    if (accuracy <= 15) return '中等精度';
    if (accuracy <= 30) return '一般精度';
    return '低精度';
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy <= 3) return Colors.green.shade700;
    if (accuracy <= 8) return Colors.green;
    if (accuracy <= 15) return Colors.orange;
    if (accuracy <= 30) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lat = _position?.latitude.toStringAsFixed(6);
    final lon = _position?.longitude.toStringAsFixed(6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('高精度GPS定位测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // GPS优化提示卡片
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'GPS精度优化提示',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 请到户外开阔地带测试\n'
                      '• 确保手机Wi-Fi辅助定位已开启\n'
                      '• 避免在高楼、隧道等遮挡环境\n'
                      '• 首次搜星可能需要15-30秒',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('状态：$_status'),
            const SizedBox(height: 12),
            if (_position != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '位置信息',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('纬度：$lat', style: const TextStyle(fontFamily: 'monospace')),
                      Text('经度：$lon', style: const TextStyle(fontFamily: 'monospace')),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('精度：${_position!.accuracy.toStringAsFixed(1)} m  '),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getAccuracyColor(_position!.accuracy),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getAccuracyLevel(_position!.accuracy),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestAndGetOnce,
                icon: const Icon(Icons.my_location),
                label: const Text('获取高精度位置'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _watching ? _stopWatch : _startWatch,
                icon: Icon(_watching ? Icons.stop : Icons.play_arrow),
                label: Text(_watching ? '停止实时更新' : '开始实时更新'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _watching ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}