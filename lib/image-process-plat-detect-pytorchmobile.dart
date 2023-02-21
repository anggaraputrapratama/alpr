// import 'dart:io';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:opencv_4/factory/pathfrom.dart';
// import 'package:opencv_4/opencv_4.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image/image.dart' as image_;
// import 'package:pytorch_mobile/model.dart';
// import 'package:pytorch_mobile/pytorch_mobile.dart';

// import 'main.dart';

// class PlatDeteksiMobile extends StatefulWidget {
//   const PlatDeteksiMobile({super.key});

//   @override
//   State<PlatDeteksiMobile> createState() => _PlatDeteksiMobileState();
// }

// class _PlatDeteksiMobileState extends State<PlatDeteksiMobile> {
//   late CameraController _controller;
//   File? image, imageGray, imageThreshold, imageDilate, image90, imageAsli;
//   // late Model platModel, charModel;
//   // List<ResultObjectDetection?> platDetect = [];
//   // List<ResultObjectDetection?> charDetect = [];
//   String? platDetect;
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
//   late Model? _imageModel, _customModel;

//   @override
//   void initState() {
//     super.initState();
//     loadModel();
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
//   }

//   Future loadModel() async {
//     String pathCustomModel = "assets/models/best-400.pt";
//     try {
//       _customModel = await PyTorchMobile.loadModel(pathCustomModel);
//     } on PlatformException {
//       print("only supported for android and ios so far");
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
//     platDetect = await _customModel!
//         .getImagePrediction(c, 640, 640, 'assets/models/labels.csv');

//     // boundingBox1 = [
//     //   await boundingBox[0]['left'],
//     //   await boundingBox[0]['right'],
//     //   await boundingBox[0]['width'],
//     //   await boundingBox[0]['height']
//     // ];

//     // Uint8List imageData = await imageAsli!.readAsBytes();
//     // ui.Codec codec = await ui.instantiateImageCodec(imageData);
//     // ui.FrameInfo fi = await codec.getNextFrame();
//     // ui.Image image1 = fi.image;

//     // ByteData? byteData =
//     //     await image1.toByteData(format: ui.ImageByteFormat.png);
//     // List<int> imageDatas = byteData!.buffer.asUint8List();
//     // image_.Image? originalImage = image_.decodeImage(imageDatas);

//     // int x = (boundingBox1[0] * originalImage!.height).round();
//     // int y = (boundingBox1[1] * originalImage.width).round();
//     // int width = (boundingBox1[2] * originalImage.height).round();
//     // int height = (boundingBox1[3] * originalImage.width).round();
//     // croppedImage = image_.copyCrop(originalImage, x, y, width, height);
//     // List<int> croppedImageData = image_.encodePng(croppedImage!);
//     // imageUint = Uint8List.fromList(croppedImageData);
//     // croppedImageWidget = Image.memory(imageUint!);
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
//       body: Column(
//         children: [
//           image == null ? CameraPreview(_controller) : Image.file(imageAsli!),
//           // croppedImage == null
//           //     ? const Text(
//           //         'Cropped image tidak ada',
//           //         style: TextStyle(color: Colors.white),
//           //       )
//           //     : Align(
//           //         alignment: Alignment.center, child: Image.memory(imageUint!)),
//           Center(
//             child: Visibility(
//               visible: platDetect != null,
//               child: Text("$platDetect"),
//             ),
//           ),
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
