// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image/image.dart';

// class MyImageWidget extends StatelessWidget {
//   final Image image;

//   const MyImageWidget({required this.image});

//   @override
//   Widget build(BuildContext context) {
//     final width = image.width.toDouble();
//     final height = image.height.toDouble();
//     final widget = Image.memory(
//       encodePng(image),
//       width: width,
//       height: height,
//     );
//     return widget;
//   }
// }

// void main() {
//   // Load the image
//   final file = File('image.jpg');
//   final image = decodeImage(file.readAsBytesSync());

//   // Define the coordinates of the bounding box
//   const x = 100;
//   const y = 100;
//   const w = 200;
//   const h = 200; // Example bounding box coordinates

//   // Crop the ROI using the bounding box coordinates
//   final roi = image!.crop(x, y, w, h);

//   // Use this widget to display the cropped ROI
//   final widget = MyImageWidget(image: Image.memory(roi.getBytes()));

//   runApp(MaterialApp(home: Scaffold(body: widget)));
// }
