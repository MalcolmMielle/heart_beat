import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as imglib;


int nearest_power_of_two(int v){
//  print(v);
  v--;
  v |= v >> 1;
  v |= v >> 2;
  v |= v >> 4;
  v |= v >> 8;
  v |= v >> 16;
  v++;

  return v;
}

Future<List<FileSystemEntity>> make_frames_from_video(String video_path, String save_frames_to_path) async {

  var dir = await Directory(save_frames_to_path).create(recursive: true);
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

  print("FFMPEG");
  _flutterFFmpeg
      .execute("-i " + video_path + " " + path.join(save_frames_to_path + "frame%04d.jpg"))
      .then((rc) => print("FFmpeg process exited with rc $rc"));

  List<FileSystemEntity> files = dir.listSync();
  for (var el in files) {
    print(el.toString());
  }
  int frame_nb = files.length;

  return files;
}



Future<List<imglib.Image>> load_frames_from_path(String frame_path) async {
  var dir = await Directory(frame_path);
  var files = dir.listSync();
  return load_frames(files);
}

Future<List<imglib.Image>> load_frames(List<FileSystemEntity> files) async {

  files.sort((FileSystemEntity a, FileSystemEntity b)=>a.path.compareTo(b.path));

  List<imglib.Image> images = List<imglib.Image>();
  for (var el in files) {
//    print("Loading " + el.path);
    imglib.Image image = imglib.decodeImage(File(el.path).readAsBytesSync());
    images.add(image);
  }

  return images;
}