import 'dart:async';

import 'dart:typed_data';
import 'dart:math';
import 'package:camera/camera.dart';

import 'package:image/image.dart' as img;
import 'package:smart_signal_processing/smart_signal_processing.dart' as signal;
import 'video_loader.dart';

List<double> colorAverageCameraImage(CameraImage image) {
  int r_sum = 0;
  int b_sum = 0;
  int g_sum = 0;

  int width = image.width;
  int height = image.height;
//  var img = imglib.Image(image.planes[0].bytesPerRow, height); // Create Image buffer
  const int hexFF = 0xFF000000;
  final int uvyButtonStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel;
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      final int uvIndex =
          uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
      final int index = y * width + x;
      final yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];
      // Calculate pixel color
      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .round()
          .clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
      // color: 0x FF  FF  FF  FF
      //           A   B   G   R
//      img.data[index] = hexFF | (b << 16) | (g << 8) | r;

      r_sum = r_sum + r;
      b_sum = b_sum + b;
      g_sum = g_sum + g;
    }
  }
  // Rotate 90 degrees to upright
//    var img1 = imglib.copyRotate(img, 90);

  int size_img = width * height;

  print("rgb: " +
      r_sum.toString() +
      " " +
      b_sum.toString() +
      " " +
      g_sum.toString());

  return [b_sum / size_img, g_sum / size_img, r_sum / size_img];
//  return img;
}

List<double> colorAverage(img.Image frame) {
  int red = 0;
  int blue = 0;
  int green = 0;

  for (int w = 0; w < frame.width; ++w) {
    for (int h = 0; h < frame.height; ++h) {
      var pixel = frame.getPixelSafe(w, h);
      red = red + img.getRed(pixel);
      blue = blue + img.getBlue(pixel);
      green = green + img.getGreen(pixel);
    }
  }

//  print("final red " + red);

  var image_size = frame.width * frame.height;
  List<double> colors = [
    blue / image_size,
    green / image_size,
    red / image_size
  ];

  return colors;
}

class O2Process {
//  List<img.Image> frames = List<img.Image>();

  double RedBlueRatio = 0;
  double Stdr = 0;
  double Stdb = 0;
  double sumred = 0;
  double sumblue = 0;
  int o2;

  //Arraylist
  List<double> redAvgList = new List<double>();
  List<double> blueAvgList = new List<double>();

  void reset() {
    RedBlueRatio = 0;
    Stdr = 0;
    Stdb = 0;
    sumred = 0;
    sumblue = 0;
    o2 = null;

    //Arraylist
    redAvgList = new List<double>();
    blueAvgList = new List<double>();
  }

  Future<double> FFT_O2(
      List<double> redAvgList_input, double samplingFrequency) async {
    double temp = 0;
    double POMP = 0;
    double frequency;

    //Zero padding to nearest power of two
    int len_start = redAvgList_input.length;
    int len_np = nearest_power_of_two(len_start);

    for (int i = len_start; i < len_np; ++i) {
      redAvgList_input.add(0);
    }

    assert(redAvgList_input.length == len_np);

    Float64List redAvgList_input_floatlist =
        Float64List.fromList(redAvgList_input);

    Float64List imags_redAvgList = Float64List(redAvgList_input.length);

    signal.FFT.transform(redAvgList_input_floatlist, imags_redAvgList);

    for (int p = 35; p < len_start; p++) {
      redAvgList_input_floatlist[p] = redAvgList_input_floatlist[p].abs();
      assert(redAvgList_input_floatlist[p] >= 0);
    }

    for (int p = 35; p < len_start; p++) {

      assert(redAvgList_input_floatlist[p] >= 0);
//      print("freq = " + redAvgList_input_floatlist[p].toString() + " at " + p.toString());
      // 12 was chosen because it is a minimum frequency that we think people can get to determine heart rate.
      if (temp < redAvgList_input_floatlist[p]) {
        temp = redAvgList_input_floatlist[p];
        POMP = p.toDouble();
      }
    }

//    print("t");
    if (POMP < 35) {
      POMP = 0;
    }

//    print("POMP: " + POMP.toString());

//    print("t");
    frequency =
        POMP * samplingFrequency / (2 * len_start);
//    print("end");
    return frequency;
  }

  Future<List<int>> processO2(int total_time_in_sec) async {
    if (redAvgList.length == 0) {
//      print("We need at least one frame");
      return [-4, -4];
    }

//            startTime = System.currentTimeMillis();
    double samplingFreq = (redAvgList.length / total_time_in_sec);
//  double red = RedAvgList.toArray(new Double[RedAvgList.size()]);
//  Double[] Blue = BlueAvgList.toArray(new Double[BlueAvgList.size()]);
//  Float64List imags_redAvgList = Float64List(redAvgList.length);

//    print("fourier with a sampling frequency of : " + samplingFreq.toString());

    int len_start = redAvgList.length;

    List redAvgList_clone = redAvgList.map((element)=>element).toList();
    double HRFreq = await FFT_O2(redAvgList_clone, samplingFreq);
//    print("Done fourier freq: " + HRFreq.toString());

    assert(len_start == redAvgList.length);

    int bpm = (HRFreq * 60).ceil();

    double meanr = sumred / redAvgList.length;
    double meanb = sumblue / redAvgList.length;

    for (int i = 0; i < blueAvgList.length - 1; i++) {
      double bufferb = blueAvgList[i];
      Stdb = Stdb + ((bufferb - meanb) * (bufferb - meanb));
      double bufferr = redAvgList[i];
      Stdr = Stdr + ((bufferr - meanr) * (bufferr - meanr));
    }

    double varr = sqrt(Stdr / (redAvgList.length - 1));
    double varb = sqrt(Stdb / (redAvgList.length - 1));

    double R = (varr / meanr) / (varb / meanb);

    double spo2 = 100 - 5 * (R);
    o2 = spo2.toInt();

//    if ((o2 < 80 || o2 > 99) || (bpm < 45 || bpm > 200)) {
//      print("Measurement failed");
//      return -1;
//    }

//        }

    if (o2 != 0) {
      return [o2, bpm];
    }
    return [-10, -10];
//        if(RedAvg!=0){
//            ProgP=inc++/34;;
//            ProgO2.setProgress(ProgP);}
//
//        processing.set(false);
  }

  Future<List<int>> processStackOfFrames(
      List<img.Image> frames_input, int total_time_in_sec) async {
    if (frames_input.length == 0) {
      print("We need at least one frame");
      return [-2, -2];
    }

    for (int i = 0; i < frames_input.length; i++) {
//      print("frame -> " + i.toString());
      int ret = processFrame(frames_input[i]);
      if (ret == -1) {
        return [-3, -3];
      }
      //put width + height of the camera inside the variables
      //        int width = size.width;
      //        int height = size.height;

//      print("frame number " + i.toString());
    }

//        long endTime = System.currentTimeMillis();
//        double totalTimeInSecs = (endTime - startTime) / 1000d; //to convert time to seconds
//        if (totalTimeInSecs >= 30) { //when 30 seconds of measuring passes do the following " we chose 30 seconds to take half sample since 60 seconds is normally a full sample of the heart beat

    return processO2(total_time_in_sec);

  }

  int processFrame(img.Image frame) {
    var colors = colorAverage(frame);

    double redAvg = colors[2];
    double blueAvg = colors[1];

    sumred = sumred + redAvg;
    sumblue = sumred + blueAvg;
//    sumred = sumred + colors[2];

    redAvgList.add(colors[2]);
    blueAvgList.add(colors[1]);

    //        ++counter; //countes number of frames in 30 seconds

    //To check if we got a good red intensity to process if not return to the condition and set it again until we get a good red intensity
//    if (redAvg < 200) {
//      print("!! ATTENTION !! redavg < 200 -> " + redAvg.toString());
//      return -1;
//    }
    return 1;
  }

  int processFrameCamera(CameraImage frame) {
    var colors = colorAverageCameraImage(frame);

    double redAvg = colors[2];
    double blueAvg = colors[1];

    sumred = sumred + redAvg;
    sumblue = sumred + blueAvg;
//    sumred = sumred + colors[2];

    redAvgList.add(colors[2]);
    blueAvgList.add(colors[1]);

    //        ++counter; //countes number of frames in 30 seconds

    //To check if we got a good red intensity to process if not return to the condition and set it again until we get a good red intensity
//    if (redAvg < 200) {
//      return -1;
//    }
    return 1;
  }
}
