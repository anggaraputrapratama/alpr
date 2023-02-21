// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:opencv_4/factory/pathfrom.dart';
// import 'package:opencv_4/opencv_4.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image/image.dart' as imglib;
// import 'package:pytorch_lite/pigeon.dart';
// import 'package:pytorch_lite/pytorch_lite.dart';

// class ImageProcessing extends StatefulWidget {
//   const ImageProcessing({super.key});

//   @override
//   State<ImageProcessing> createState() => _ImageProcessingState();
// }

// class _ImageProcessingState extends State<ImageProcessing> {
//   final ImagePicker _picker = ImagePicker();
//   File? images, imageRgb, imageGray, imageThreshold, imageDilate;
//   late XFile? file, fileThreshold, fileDilate, fileBordered;
//   Uint8List? _byte, gray, threshold, dilate;
//   String pathImage = '';
//   String thresholdPath = '';
//   String dilatePath = '';
//   String extractPath = '';
//   late ModelObjectDetection platModel, charModel;
//   List<ResultObjectDetection?> platDetect = [];
//   List<ResultObjectDetection?> charDetect = [];
//   List<Map<String, dynamic>> boundingBox = [];

//   @override
//   void initState() {
//     super.initState();
//     modelDetection();
//   }

//   Future modelDetection() async {
//     String pathPlatModel = 'assets/models/bestv1.torchscript';
//     String pathCharModel = 'assets/model/alpha_numeric_v1.torchscript';
//     try {
//       platModel = await PytorchLite.loadObjectDetectionModel(
//           pathPlatModel, 2, 640, 640,
//           labelPath: "assets/models/labels_license.txt");
//       charModel = await PytorchLite.loadObjectDetectionModel(
//           pathCharModel, 36, 640, 640,
//           labelPath: "assets/models/labels_alpha_numeric.txt");
//     } catch (e) {
//       debugPrint('Error is $e');
//     }
//   }

//   Future imagePicker() async {
//     file = await _picker.pickImage(source: ImageSource.camera);

//     setState(() {
//       pathImage = file!.path;
//       images = File(file!.path);
//     });
//     final directory = await getExternalStorageDirectory();
//     final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final fileSave = File('${directory!.path}/$fileName');

//     _byte = await Cv2.cvtColor(
//       pathFrom: CVPathFrom.GALLERY_CAMERA,
//       pathString: pathImage,
//       outputType: Cv2.COLOR_BGR2RGB,
//     );
//     setState(() {
//       _byte;
//     });
//     var a = await fileSave.writeAsBytes(_byte!);
//     setState(() {
//       imageRgb = a;
//     });
//     gray = await Cv2.cvtColor(
//       pathFrom: CVPathFrom.GALLERY_CAMERA,
//       pathString: imageRgb!.path,
//       outputType: Cv2.COLOR_BGR2GRAY,
//     );

//     setState(() {
//       gray;
//     });
//     var b = await fileSave.writeAsBytes(gray!);
//     setState(() {
//       imageGray = b;
//     });
//     thresholdImage();
//   }

//   Future thresholdImage() async {
//     // fileThreshold = await _picker.pickImage(source: ImageSource.gallery);
//     setState(() {
//       thresholdPath = imageGray!.path;
//     });
//     threshold = await Cv2.threshold(
//       pathFrom: CVPathFrom.GALLERY_CAMERA,
//       pathString: thresholdPath,
//       thresholdValue: 100,
//       maxThresholdValue: 255,
//       thresholdType: Cv2.THRESH_BINARY_INV | Cv2.THRESH_OTSU,
//     );

//     setState(() {
//       threshold;
//     });
//     final directory = await getExternalStorageDirectory();
//     final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
//     final fileSave = File('${directory!.path}/$fileName');
//     var c = await fileSave.writeAsBytes(threshold!);
//     setState(() {
//       imageThreshold = c;
//     });
//     dilateImage();
//   }

//   Future dilateImage() async {
//     // List<List<int>> kernel = List.generate(3, (_) => List.filled(3, 3));
//     // fileDilate = await _picker.pickImage(source: ImageSource.gallery);
//     setState(() {
//       dilatePath = imageThreshold!.path;
//     });
//     dilate = await Cv2.morphologyEx(
//       pathFrom: CVPathFrom.GALLERY_CAMERA,
//       pathString: dilatePath,
//       operation: Cv2.MORPH_DILATE,
//       kernelSize: [2, 2],
//     );
//     final directory = await getExternalStorageDirectory();
//     final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
//     final fileSave = File('${directory!.path}/$fileName');
//     var d = await fileSave.writeAsBytes(dilate!);
//     setState(() {
//       dilate;
//       imageDilate = d;
//     });

//     platDetect = await platModel.getImagePrediction(
//         await imageThreshold!.readAsBytes(),
//         minimumScore: 0.1,
//         IOUThershold: 0.2);

//     platDetect.asMap().forEach((key, value) {
//       if (value!.className == 'licence') {
//         boundingBox.add({
//           'name': value.className,
//           'left': value.rect.left,
//           'top': value.rect.top,
//           'bottom': value.rect.bottom,
//           'right': value.rect.right,
//           'width': value.rect.width,
//           'height': value.rect.height,
//         });
//       }
//     });
//   }

//   Future extractChars() async {
//     var fileLoc = await _picker.pickImage(source: ImageSource.gallery);

//     setState(() {
//       extractPath = fileLoc!.path;
//     });
//     final black = imglib.getColor(0, 0, 0);

//     var contours =
//         await Cv2.findContours(pathString: extractPath, mode: 1, method: 1);
//     print(contours);
//   }

//   @override
//   Widget build(BuildContext context) {
//     print(platDetect.length);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Learning ALPR imageProsesing'),
//       ),
//       body: Center(
//         child: ListView(
//           children: [
//             Column(
//               children: [
//                 const Text('Using Image OCR HandWritting for learning ALPR'),
//                 const SizedBox(height: 20),
//                 SingleChildScrollView(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // images == null
//                       //     ? const Text('No image selected.')
//                       //     : ListTile(
//                       //         title: const Center(child: Text('image awal')),
//                       //         subtitle: Image.file(images!),
//                       //       ),
//                       _byte == null
//                           ? const Text('Image belum di convert BGR to RGB')
//                           : ListTile(
//                               title:
//                                   const Center(child: Text('image BGR to RGB')),
//                               subtitle: Image.memory(_byte!),
//                             ),
//                       gray == null
//                           ? const Text('Image belum di convert BGR to GRAY')
//                           : ListTile(
//                               title: const Center(
//                                   child: Text('image BGR to Gray')),
//                               subtitle: Image.memory(gray!),
//                             ),
//                       threshold == null
//                           ? const Text('Image threshold')
//                           : ListTile(
//                               title: const Center(child: Text('Threshold')),
//                               subtitle: Image.memory(threshold!),
//                             ),
//                       dilate == null
//                           ? const Text('Image dilate')
//                           : ListTile(
//                               title: const Center(child: Text('dilate')),
//                               subtitle: Image.memory(dilate!),
//                             ),
//                       images == null
//                           ? const Text('No image selected.')
//                           : SizedBox(
//                               height: 800,
//                               child: platModel.renderBoxesOnImage(
//                                   images!, platDetect),
//                             ),
//                       // imageBeforeBorder == null
//                       //     ? const Text('No image selected for before bordered')
//                       //     : ListTile(
//                       //         title: const Center(
//                       //             child: Text('image before bordered')),
//                       //         subtitle: Image.file(imageBeforeBorder!),
//                       //       ),
//                       // imageAfterBorder == null
//                       //     ? const Text('No image selected for bordered')
//                       //     : ListTile(
//                       //         title: const Center(child: Text('bordered')),
//                       //         subtitle: Image.file(imageAfterBorder!),
//                       //       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           ElevatedButton(
//                             onPressed: imagePicker,
//                             child: const Text('Pick Image'),
//                           ),
//                           // ElevatedButton(
//                           //     onPressed: borderedImage,
//                           //     child: const Text('Bordered Image')),
//                           ElevatedButton(
//                               onPressed: () => setState(() {
//                                     images = null;
//                                     _byte = null;
//                                     gray = null;
//                                     threshold = null;
//                                     dilate = null;
//                                   }),
//                               child: const Text('reset')),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
