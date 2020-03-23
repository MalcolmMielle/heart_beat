import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_beat/heart_beat.dart';
import 'package:heart_beat/video_loader.dart';

void main() {
  const MethodChannel channel = MethodChannel('heart_beat');

  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('power of two', () async {
    int v = -1022; // compute the next highest power of 2 of 32-bit v

    print(v);
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;

    print(v);
  });

  test('first test', () async {
    String frame_path = "assets/S98T81/frames";
    var images = await load_frames_from_path(frame_path);
//    expect(images.length, 639);

    O2Process o2 = O2Process();

    var o2_res = await o2.processStackOfFrames(images, 21);
    print(o2_res);


  });

  test('second test', () async {
    String frame_path = "assets/S98T89/frames";
    var images = await load_frames_from_path(frame_path);
//    expect(images.length, 639);

    O2Process o2 = O2Process();

    var o2_res = await o2.processStackOfFrames(images, 21);
    print(o2_res);


  });
}
