# heart_beat

A flutter plugin to calculate Heart beat and oxygene saturation from camera images.

## Getting Started

`O2Process` is an object to calculate the heart information from images.
Call `processStackOfFrames` to input all frames from a video and calculate both oxygene stauration (o2) and beat per minutes (bpm).

To process the images one by one call `processFrameCamera` or `processFrame` depending on you input format and once all images have been inputed run `processO2` to get final results.

After every calculation, call `reset` to reinitialize all data of the O2process.
