import 'dart:io';

import 'package:alpr_research/main.dart';
import 'package:alpr_research/render-box-image-render.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_4/factory/pathfrom.dart';
import 'package:opencv_4/opencv_4.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pytorch_lite/pigeon.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:image/image.dart' as image_;

// import 'dart:ui' as ui;
class PlatDetection extends StatefulWidget {
  const PlatDetection({super.key});

  @override
  State<PlatDetection> createState() => _PlatDetectionState();
}

class _PlatDetectionState extends State<PlatDetection> {
  late CameraController _controller;
  File? image, imageGray, imageThreshold, imageDilate, image90, imageAsli;
  late ModelObjectDetection platModel, charModel;
  List<ResultObjectDetection?> platDetect = [];
  List<ResultObjectDetection?> charDetect = [];
  List<dynamic> cek = [];
  List<dynamic> cekLefts = [];
  String? hasilPlat;
  List<String> plat = [];
  image_.Image? croppedImage;
  List<Map<String, dynamic>> list_crop = [];
  String? angka;
  List<String> parts = [];
  Uint8List? _byte, gray, threshold, dilate;
  String? pathImage, thresholdPath, dilatePath;
  List<Map<String, dynamic>> boundingBox = [];
  bool flash = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
    modelDetection();
  }

  Future modelDetection() async {
    String pathPlatModel = 'assets/models/bestv1.torchscript';
    String pathCharModel = 'assets/model/alpha_numeric_v1.torchscript';
    try {
      platModel = await PytorchLite.loadObjectDetectionModel(
          pathPlatModel, 2, 640, 640,
          labelPath: "assets/models/labels_license.txt");
      charModel = await PytorchLite.loadObjectDetectionModel(
          pathCharModel, 36, 640, 640,
          labelPath: "assets/models/labels_alpha_numeric.txt");
    } catch (e) {
      debugPrint('Error is $e');
    }
  }

  Future runPlatDetection() async {
    final XFile file = await _controller.takePicture();

    setState(() {
      image = File(file.path);
      pathImage = file.path;
      imageAsli = File(file.path);
    });

    image_.Image? contrast = image_.decodeImage(imageAsli!.readAsBytesSync());
    contrast = image_.copyRotate(contrast!, 90);
    imageAsli!.writeAsBytesSync(image_.encodeJpg(contrast));
    setState(() {
      image90 = imageAsli;
    });
    //BGR to RGB
    _byte = await Cv2.cvtColor(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: image90!.path,
      outputType: Cv2.COLOR_BGR2RGB,
    );
    //BGR to GRAY
    gray = await Cv2.cvtColor(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: pathImage!,
      outputType: Cv2.COLOR_BGR2GRAY,
    );

    setState(() {
      _byte;
      gray;
    });
    //save image gray to storage
    final directory = await getExternalStorageDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fileSave = File('${directory!.path}/$fileName');
    var a = await fileSave.writeAsBytes(gray!);
    setState(() {
      imageGray = a;
    });
    //threshold image
    threshold = await Cv2.threshold(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: imageGray!.path,
      thresholdValue: 100,
      maxThresholdValue: 255,
      thresholdType: Cv2.THRESH_BINARY_INV | Cv2.THRESH_OTSU,
    );
    //save image threshold to storage
    var c = await fileSave.writeAsBytes(threshold!);
    setState(() {
      imageThreshold = c;
    });
    //dilate image
    dilate = await Cv2.morphologyEx(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: imageThreshold!.path,
      operation: Cv2.MORPH_DILATE,
      kernelSize: [3, 3],
    );
    var d = await fileSave.writeAsBytes(dilate!);
    setState(() {
      imageDilate = d;
    });
    platDetect = (await platModel.getImagePrediction(await a.readAsBytes(),
            minimumScore: 0.1, IOUThershold: 0.3))
        .cast<ResultObjectDetection?>();
    platDetect.asMap().forEach((key, value) {
      if (value!.className == 'licence') {
        boundingBox.add({
          'name': value.className,
          'left': value.rect.left,
          'top': value.rect.top,
          'bottom': value.rect.bottom,
          'right': value.rect.right,
          'width': value.rect.width,
          'height': value.rect.height,
        });
      }
    });
  }

  Future thresholdImage() async {
    setState(() {
      thresholdPath = imageGray!.path;
    });
    threshold = await Cv2.threshold(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: thresholdPath!,
      thresholdValue: 100,
      maxThresholdValue: 255,
      thresholdType: Cv2.THRESH_BINARY_INV | Cv2.THRESH_OTSU,
    );

    setState(() {
      threshold;
    });
    final directory = await getExternalStorageDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final fileSave = File('${directory!.path}/$fileName');
    var c = await fileSave.writeAsBytes(threshold!);
    setState(() {
      imageThreshold = c;
    });
    dilateImage();
  }

  Future dilateImage() async {
    setState(() {
      dilatePath = imageThreshold!.path;
    });
    dilate = await Cv2.morphologyEx(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: dilatePath!,
      operation: Cv2.MORPH_DILATE,
      kernelSize: [3, 3],
    );
    final directory = await getExternalStorageDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final fileSave = File('${directory!.path}/$fileName');
    var d = await fileSave.writeAsBytes(dilate!);
    setState(() {
      dilate;
      imageDilate = d;
    });
    platDetection(imageDilate!);
  }

  Future platDetection(File imageDilates) async {
    platDetect = (await platModel.getImagePrediction(
            await imageDilates.readAsBytes(),
            minimumScore: 0.1,
            IOUThershold: 0.2))
        .cast<ResultObjectDetection?>();
    platDetect.asMap().forEach((key, value) {
      if (value!.className == 'licence') {
        boundingBox.add({
          'name': value.className,
          'left': value.rect.left,
          'top': value.rect.top,
          'bottom': value.rect.bottom,
          'right': value.rect.right,
          'width': value.rect.width,
          'height': value.rect.height,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // for (var i in platDetect) {
    //   print(i!.className);
    // }
    for (var i in platDetect) {
      print(i!.className);
      print('left: ${i.rect.left}');
      print('right: ${i.rect.right}');
      print('top: ${i.rect.top}');
      print('bottom: ${i.rect.bottom}');
      print('score: ${i.score}');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Plat Nomor'),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: image == null
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    flash = !flash;
                    flash
                        ? _controller.setFlashMode(FlashMode.off)
                        : _controller.setFlashMode(FlashMode.always);
                  });
                },
                child: Icon(
                  flash ? Icons.flash_off_sharp : Icons.flash_on_sharp,
                  color: Colors.white,
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: Stack(
        children: [
          image == null
              ? CameraPreview(_controller)
              : kDebugMode
                  ? Image.memory(threshold!)
                  // ? Image.file(
                  //     imageGray!,
                  //   )
                  : renderBoxImage(image90!, platDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        image == null;
                        // image90 = null;
                        imageAsli = null;
                        imageGray = null;
                        imageThreshold = null;
                        imageDilate = null;
                        platDetect = [];
                      });
                    },
                    child: const Text('Reset')),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        image == null;
                      });
                      runPlatDetection();
                    },
                    child: const Text('Deteksi')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
