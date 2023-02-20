// import 'dart:io';

// import 'package:alpr_research/main.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:opencv_4/factory/pathfrom.dart';
// import 'package:opencv_4/opencv_4.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pytorch_lite/pigeon.dart';
// import 'package:pytorch_lite/pytorch_lite.dart';
// import 'package:image/image.dart' as image_;

// import 'dart:ui' as ui;

// class PlatDetection extends StatefulWidget {
//   const PlatDetection({super.key});

//   @override
//   State<PlatDetection> createState() => _PlatDetectionState();
// }

// class _PlatDetectionState extends State<PlatDetection> {
//   late CameraController _controller;
//   File? image, imageGray, imageThreshold, imageDilate, image90, imageAsli;
//   late ModelObjectDetection platModel, charModel;
//   List<ResultObjectDetection?> platDetect = [];
//   List<ResultObjectDetection?> charDetect = [];
//   List<dynamic> cek = [];
//   List<dynamic> cekLefts = [];
//   String? hasilPlat;
//   List<String> plat = [];
//   image_.Image? croppedImage;
//   List<Map<String, dynamic>> list_crop = [];
//   String? angka;
//   List<String> parts = [];
//   Uint8List? _byte, gray, threshold, dilate;
//   String? pathImage, thresholdPath, dilatePath;
//   List<Map<String, dynamic>> boundingBox = [];
//   List<double> boundingBox1 = [];
//   bool flash = false;
//   Uint8List? imageUint;
//   Image? croppedImageWidget;

//   @override
//   void initState() {
//     super.initState();
//     _controller = CameraController(cameras[0], ResolutionPreset.medium,
//         enableAudio: false);

//     _controller.initialize().then((_) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {});
//     }).catchError((Object e) {
//       if (e is CameraException) {
//         switch (e.code) {
//           case 'CameraAccessDenied':
//             // Handle access errors here.
//             break;
//           default:
//             // Handle other errors here.
//             break;
//         }
//       }
//     });
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

//   Future runPlatDetection() async {
//     final XFile file = await _controller.takePicture();

//     setState(() {
//       image = File(file.path);
//       pathImage = file.path;
//       imageAsli = File(file.path);
//     });

//     image_.Image? contrast = image_.decodeImage(imageAsli!.readAsBytesSync());
//     contrast = image_.copyRotate(contrast!, 90);
//     imageAsli!.writeAsBytesSync(image_.encodeJpg(contrast));
//     setState(() {
//       image90 = imageAsli;
//     });
//     final directory = await getExternalStorageDirectory();
//     final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final fileSave = File('${directory!.path}/$fileName');
//     //BGR to RGB
//     _byte = await Cv2.cvtColor(
//       pathFrom: CVPathFrom.GALLERY_CAMERA,
//       pathString: image90!.path,
//       outputType: Cv2.COLOR_BGR2RGB,
//     );
//     var a = await fileSave.writeAsBytes(_byte!);
//     //BGR to GRAY
//     gray = await Cv2.cvtColor(
//       pathFrom: CVPathFrom.GALLERY_CAMERA,
//       pathString: image90!.path,
//       outputType: Cv2.COLOR_BGR2GRAY,
//     );

//     setState(() {
//       _byte;
//       gray;
//     });
//     //save image gray to storage

//     var b = await fileSave.writeAsBytes(gray!);
//     setState(() {
//       imageGray = b;
//     });
//     //threshold image
//     threshold = await Cv2.threshold(
//       pathFrom: CVPathFrom.GALLERY_CAMERA,
//       pathString: imageGray!.path,
//       thresholdValue: 100,
//       maxThresholdValue: 255,
//       thresholdType: Cv2.THRESH_BINARY_INV | Cv2.THRESH_OTSU,
//     );
//     //save image threshold to storage
//     var c = await fileSave.writeAsBytes(threshold!);
//     setState(() {
//       imageThreshold = c;
//     });
//     //dilate image
//     dilate = await Cv2.morphologyEx(
//       pathFrom: CVPathFrom.GALLERY_CAMERA,
//       pathString: imageThreshold!.path,
//       operation: Cv2.MORPH_DILATE,
//       kernelSize: [3, 3],
//     );
//     var d = await fileSave.writeAsBytes(dilate!);
//     setState(() {
//       imageDilate = d;
//     });
//     platDetect = await platModel.getImagePrediction(await c.readAsBytes(),
//         minimumScore: 0.1, IOUThershold: 0.2);
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
//     boundingBox1 = [
//       await boundingBox[0]['left'],
//       await boundingBox[0]['right'],
//       await boundingBox[0]['width'],
//       await boundingBox[0]['height']
//     ];

//     Uint8List imageData = await imageAsli!.readAsBytes();
//     ui.Codec codec = await ui.instantiateImageCodec(imageData);
//     ui.FrameInfo fi = await codec.getNextFrame();
//     ui.Image image1 = fi.image;

//     ByteData? byteData =
//         await image1.toByteData(format: ui.ImageByteFormat.png);
//     List<int> imageDatas = byteData!.buffer.asUint8List();
//     image_.Image? originalImage = image_.decodeImage(imageDatas);

//     int x = (boundingBox1[0] * originalImage!.height).round();
//     int y = (boundingBox1[1] * originalImage.width).round();
//     int width = (boundingBox1[2] * originalImage.height).round();
//     int height = (boundingBox1[3] * originalImage.width).round();
//     croppedImage = image_.copyCrop(originalImage, x, y, width, height);
//     List<int> croppedImageData = image_.encodePng(croppedImage!);
//     imageUint = Uint8List.fromList(croppedImageData);
//     croppedImageWidget = Image.memory(imageUint!);
//   }

//   @override
//   Widget build(BuildContext context) {
//     // for (var i in platDetect) {
//     //   print(i!.className);
//     // }
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Deteksi Plat Nomor'),
//         backgroundColor: Colors.blue,
//         elevation: 0,
//         leading: image == null
//             ? GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     flash = !flash;
//                     flash
//                         ? _controller.setFlashMode(FlashMode.off)
//                         : _controller.setFlashMode(FlashMode.always);
//                   });
//                 },
//                 child: Icon(
//                   flash ? Icons.flash_off_sharp : Icons.flash_on_sharp,
//                   color: Colors.white,
//                 ),
//               )
//             : const SizedBox.shrink(),
//       ),
//       body: Stack(
//         children: [
//           image == null
//               ? CameraPreview(_controller)
//               : !kDebugMode
//                   // ? Image.memory(threshold)
//                   ? Image.file(
//                       File(dilatePath!),
//                     )
//                   : platModel.renderBoxesOnImage(image90!, platDetect),
//           croppedImage == null
//               ? const Text(
//                   'Cropped image tidak ada',
//                   style: TextStyle(color: Colors.white),
//                 )
//               : Align(
//                   alignment: Alignment.center, child: Image.memory(imageUint!)),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 ElevatedButton(
//                     onPressed: () {
//                       setState(() {
//                         image == null;
//                         // image90 = null;
//                         imageAsli = null;
//                         imageGray = null;
//                         imageThreshold = null;
//                         imageDilate = null;

//                         platDetect = [];
//                       });
//                     },
//                     child: const Text('Reset')),
//                 ElevatedButton(
//                     onPressed: () {
//                       setState(() {
//                         image == null;
//                       });
//                       runPlatDetection();
//                     },
//                     child: const Text('Deteksi')),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
