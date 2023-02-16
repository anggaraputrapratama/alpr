// import 'dart:io';
// import 'package:alpr_research/bottom-sheet.dart';
// import 'package:alpr_research/main.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import 'package:pytorch_lite/pigeon.dart';
// import 'package:pytorch_lite/pytorch_lite.dart';
// import 'package:image/image.dart' as image_;

// class PlatDeteksi extends StatefulWidget {
//   const PlatDeteksi({super.key});

//   @override
//   State<PlatDeteksi> createState() => _PlatDeteksiState();
// }

// class _PlatDeteksiState extends State<PlatDeteksi> {
//   late CameraController _controller;
//   File? image, contrastImage, im2, cekImage, hasilCrop;
//   late ModelObjectDetection _objectModel, licenseModel;
//   List<ResultObjectDetection?> objDetect = [];
//   List<ResultObjectDetection?> licenseDetect = [];
//   Map<String, Object?>? data;
//   bool dataResult = false;
//   final List<String> _prediction = [];
//   List<dynamic> cek = [];
//   List<dynamic> cekLefts = [];
//   String? hasilPlat;
//   List<String> plat = [];
//   image_.Image? croppedImage;
//   List<Map<String, dynamic>> list_crop = [];
//   String? angka;
//   List<String> parts = [];
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
//     loadModel();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future loadModel() async {
//     // String pathPlateDetection = 'assets/models/';
//     String pathObjectDetectionModel =
//         'assets/models/alpha_numeric_v1.torchscript';
//     String pathLicenseDetectionModel = 'assets/models/plat.torchscript';
//     try {
//       _objectModel = await PytorchLite.loadObjectDetectionModel(
//           pathObjectDetectionModel, 36, 640, 640,
//           labelPath: "assets/models/labels_alpha_numeric.txt");
//       licenseModel = await PytorchLite.loadObjectDetectionModel(
//           pathLicenseDetectionModel, 2, 640, 640,
//           labelPath: "assets/models/labels_license.txt");
//     } catch (e) {
//       if (e is PlatformException) {
//         debugPrint('only supported for android, Error is $e');
//       } else {
//         debugPrint('Error is $e');
//       }
//     }
//   }

//   image_.Image? imageCrop;
//   Future runLicenseDetect() async {
//     final XFile file = await _controller.takePicture();
//     setState(() {
//       cekImage = File(file.path);
//     });
//     contrastImage = File(file.path);

//     image_.Image? contrast =
//         image_.decodeImage(contrastImage!.readAsBytesSync());
//     contrast = image_.copyRotate(contrast!, 90);
//     contrastImage!.writeAsBytesSync(image_.encodeJpg(contrast));
//     setState(() {
//       image = contrastImage;
//     });

//     licenseDetect = (await licenseModel.getImagePrediction(
//             await image!.readAsBytes(),
//             minimumScore: 0.1,
//             IOUThershold: 0.2))
//         .cast<ResultObjectDetection?>();

//     licenseDetect.asMap().forEach((key, value) {
//       if (value!.className == 'licence') {
//         boundingPoint.add({
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
//     final bytes = await cekImage!.readAsBytes();
//     final Uint8List uint8list = Uint8List.fromList(bytes);
//     // var imag = image_.decodeImage(contrastImage!.readAsBytesSync());
//     image_.Image imag = image_.decodeImage(uint8list)!;

//     croppedImage = image_.copyCrop(
//         imag,
//         bulatkanNilai(boundingPoint[0]['left']).toInt(),
//         bulatkanNilai(boundingPoint[0]['right']).toInt(),
//         bulatkanNilai(boundingPoint[0]['width']).toInt(),
//         bulatkanNilai(boundingPoint[0]['height']).toInt());
//     // var coba = image_.decodeImage(croppedImage!.getBytes());
//     contrastImage!.writeAsBytesSync(image_.encodeJpg(croppedImage!));
//     // final directory = await getTemporaryDirectory();
//     // final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
//     // final fileSave = File('${directory!.path}/$fileName');
//     setState(() {});
//   }

//   Future runObjDetect() async {
//     list_crop.clear();
//     plat.clear();
//     final XFile file = await _controller.takePicture();
//     contrastImage = File(file.path);

//     image_.Image? contrast =
//         image_.decodeImage(contrastImage!.readAsBytesSync());
//     contrast = image_.copyRotate(contrast!, 90);
//     contrastImage!.writeAsBytesSync(image_.encodeJpg(contrast));
//     setState(() {
//       image = contrastImage;
//     });

//     objDetect = (await _objectModel.getImagePrediction(
//             await image!.readAsBytes(),
//             minimumScore: 0.1,
//             IOUThershold: 0.2))
//         .cast<ResultObjectDetection?>();

//     cekLefts = objDetect.map((e) {
//       return (e!.rect.left);
//     }).toList();
//     cek = objDetect.map((e) {
//       if (e!.rect.top >= 0 && e.rect.bottom <= 0.5) {
//         return (e.className);
//       }
//     }).toList();
//     cekLefts.sort();

//     var a = cekLefts.take(cek.length).toList();

//     a.asMap().forEach((index, element) {
//       objDetect.asMap().forEach((key, value) {
//         if (value!.rect.left == element && value.score >= 0.76) {
//           list_crop.add({
//             'name': value.className,
//             'left': value.rect.left,
//             'top': value.rect.top,
//             'bottom': value.rect.bottom,
//             'right': value.rect.right,
//           });
//         }
//       });
//     });

//     for (var i in list_crop) {
//       plat.add(i['name'].toString());
//     }

//     setState(() {
//       dataResult = true;
//       hasilPlat = plat.join();
//       var azs = hasilPlat!.codeUnits.where((e) => e != 13).toList();

//       hasilPlat = String.fromCharCodes(azs);

//       RegExp exp = RegExp(r'\d');

//       parts = hasilPlat!
//           .splitMapJoin(
//             RegExp(r'[a-zA-Z]'),
//             onMatch: (value) => '${value[0]}',
//             onNonMatch: (p0) => '',
//           )
//           .split('');
//       var numbers = hasilPlat?.splitMapJoin(exp,
//           onMatch: (value) => '${value[0]}', onNonMatch: (value) => '');

//       if (numbers != null) {
//         angka = numbers;
//       } else {
//         print('Angka tidak ditemukan');
//       }
//     });
//   }

//   bool flash = false;
//   List<Map<String, dynamic>> listCrop = [];
//   List<Map<String, dynamic>> boundingPoint = [];
//   double bulatkanNilai(double nilai) {
//     if (nilai % 1 == 0.5) {
//       return nilai.ceilToDouble();
//     } else {
//       return nilai.roundToDouble();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Map<String, double> ratios = {
//     //   '1:1': 1 / 1,
//     //   '9:16': 9 / 16,
//     //   '3:4': 3 / 4,
//     //   '9:21': 9 / 21,
//     //   'full': MediaQuery.of(context).size.aspectRatio,
//     // };
//     final size = MediaQuery.of(context).size;
//     if (!_controller.value.isInitialized) {
//       return Container();
//     }
//     var bytes = Uint8List.fromList(image_.encodePng(croppedImage!));

//     // int offsetx =
//     //     (imageCrop!.width - min(imageCrop!.width, imageCrop!.height)) ~/ 2;
//     // print(offsetx);

//     // print(boundingPoint[0]['right']);
//     // print();
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       resizeToAvoidBottomInset: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
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
//                   ? Image.file(
//                       image!,
//                     )
//                   : licenseModel.renderBoxesOnImage(cekImage!, licenseDetect),
//           BottomSheetCustom(
//               size: size,
//               onDetectionPlate: () async {
//                 setState(() {
//                   image = null;
//                   dataResult = false;
//                 });
//                 await runLicenseDetect();
//               },
//               onRetakePicture: () {
//                 setState(() {
//                   image = null;
//                   dataResult = false;
//                   plat.clear();
//                   hasilPlat = null;
//                   list_crop.clear();
//                   parts.clear();
//                   angka = null;
//                   boundingPoint.clear();
//                   licenseDetect = [];
//                 });
//               },
//               onTakePicture: () async {
//                 setState(() {
//                   image = null;
//                   dataResult = false;
//                 });
//                 await runObjDetect();
//                 // await runLicenseDetect();
//               },
//               text: croppedImage == null
//                   ? const Text('Cropped image tidak ada')
//                   : Image.memory(bytes),
//               // : Image.memory(),
//               // text: Row(
//               //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               //   children: const [
//               //     // Text(hasilPlat == null ? '' : hasilPlat!),
//               //     // Text(parts.isEmpty ? 'kosong' : 'Dpn:${parts.first}'),
//               //     // Text(angka == null ? '' : angka!),
//               //     // Text(hasilPlat == null
//               //     //     ? 'ko'
//               //     //     : 'Belakang: ${parts.last + parts[parts.length - 2]}')
//               //   ],
//               // ),
//               dataResult: true,
//               itemCount: plat == null ? 0 : plat.length,
//               itemBuilder: (context, index) {
//                 return Center(
//                     child: Text(
//                   plat[index],
//                   style: Theme.of(context)
//                       .textTheme
//                       .labelLarge!
//                       .copyWith(fontWeight: FontWeight.w700, fontSize: 20),
//                 ));
//               }),
//         ],
//       ),
//     );
//   }
// }
