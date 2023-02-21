import 'dart:io';

import 'package:alpr_research/main.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_4/factory/pathfrom.dart';
import 'package:opencv_4/opencv_4.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pytorch_lite/pigeon.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:image/image.dart' as image_;

import 'dart:ui' as ui;

class PlatDetection extends StatefulWidget {
  const PlatDetection({super.key});

  @override
  State<PlatDetection> createState() => _PlatDetectionState();
}

class _PlatDetectionState extends State<PlatDetection> {
  late CameraController _controller;
  File? image,
      imageGray,
      imageThreshold,
      imageDilate,
      image90,
      imageAsli,
      imageCrop;
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
  List<Map<String, dynamic>> alphaNumericBox = [];
  List<double> boundingBox1 = [];
  bool flash = false;
  Uint8List? imageUint;
  Image? croppedImageWidget;
  ByteData? byteData;
  TextEditingController cityCode = TextEditingController();
  TextEditingController registeredcode = TextEditingController();
  TextEditingController regionCode = TextEditingController();
  String? angkaHasil;

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
    String pathCharModel = 'assets/models/alpha_numeric_v1.torchscript';
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
    final directory = await getExternalStorageDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fileSave = File('${directory!.path}/$fileName');
    //BGR to RGB
    _byte = await Cv2.cvtColor(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: image90!.path,
      outputType: Cv2.COLOR_BGR2RGB,
    );
    var a = await fileSave.writeAsBytes(_byte!);
    //BGR to GRAY
    gray = await Cv2.cvtColor(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: image90!.path,
      outputType: Cv2.COLOR_BGR2GRAY,
    );

    setState(() {
      _byte;
      gray;
    });
    //save image gray to storage

    var b = await fileSave.writeAsBytes(gray!);
    setState(() {
      imageGray = b;
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
    platDetect = await platModel.getImagePrediction(await c.readAsBytes(),
        minimumScore: 0.1, IOUThershold: 0.2);
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
    boundingBox1 = [
      await boundingBox[0]['left'],
      await boundingBox[0]['right'],
      await boundingBox[0]['width'],
      await boundingBox[0]['height']
    ];

    Uint8List imageData = await imageAsli!.readAsBytes();
    ui.Codec codec = await ui.instantiateImageCodec(imageData);
    ui.FrameInfo fi = await codec.getNextFrame();
    ui.Image image1 = fi.image;

    byteData = await image1.toByteData(format: ui.ImageByteFormat.png);
    List<int> imageDatas = byteData!.buffer.asUint8List();
    // image_.Image? originalImage = image_.decodeImage(imageDatas);

    /// coba dari mas Arib
    image_.Image? cmd = image_.decodeImage(imageDatas);
    var croppedImages = image_.copyResize(cmd!, width: 120);
    var imgHeight = cmd.height;
    var imgWidth = cmd.width;

    var x = (boundingBox1[0] * imgWidth).round();
    var y = (boundingBox1[1] * imgHeight).round();
    var width = (boundingBox1[2] * imgWidth).round();
    var height = (boundingBox1[3] * imgHeight).round();

    // int x = (boundingBox1[0] * originalImage!.height).round();
    // int y = (boundingBox1[1] * originalImage.width).round();
    // int width = (boundingBox1[2] * originalImage.height).round();
    // int height = (boundingBox1[3] * originalImage.width).round();
    croppedImage = image_.copyCrop(cmd, x, y, width, height);
    List<int> croppedImageData = image_.encodePng(croppedImage!);
    imageUint = Uint8List.fromList(croppedImageData);
    croppedImageWidget = Image.memory(imageUint!);

    imageCrop = await fileSave.writeAsBytes(imageUint!);
    runAlphaNumericDetection();
  }

  Future runAlphaNumericDetection() async {
    charDetect = await charModel.getImagePrediction(
        await imageCrop!.readAsBytes(),
        minimumScore: 0.1,
        IOUThershold: 0.2);
    cekLefts = charDetect.map((e) {
      return (e!.rect.left);
    }).toList();
    cek = charDetect.map((e) {
      if (e!.rect.top >= 0 && e.rect.bottom <= 0.5) {
        return (e.className);
      }
    }).toList();
    cekLefts.sort();
    var a = cekLefts.take(cek.length).toList();

    a.asMap().forEach((index, element) {
      charDetect.asMap().forEach((key, value) {
        if (value!.rect.left == element && value.score >= 0.5) {
          alphaNumericBox.add({
            'name': value.className,
            'left': value.rect.left,
            'top': value.rect.top,
            'bottom': value.rect.bottom,
            'right': value.rect.right,
          });
        }
      });
    });

    for (var i = 0; i < alphaNumericBox.length; i++) {
      plat.add(alphaNumericBox[i]['name'].toString());
    }

    setState(() {
      hasilPlat = plat.join();
      var azs = hasilPlat!.codeUnits.where((e) => e != 13).toList();

      hasilPlat = String.fromCharCodes(azs);

      RegExp exp = RegExp(r'\d');

      parts = hasilPlat!
          .splitMapJoin(
            RegExp(r'[a-zA-Z]'),
            onMatch: (value) => '${value[0]}',
            onNonMatch: (p0) => '',
          )
          .split('');
      var numbers = hasilPlat?.splitMapJoin(exp,
          onMatch: (value) => '${value[0]}', onNonMatch: (value) => '');

      if (numbers != null) {
        angkaHasil = numbers;
      } else {
        debugPrint('Angka tidak ditemukan');
      }

      if (parts.isNotEmpty) {
        cityCode.text = parts.first.toUpperCase();
        registeredcode.text = angkaHasil!;
        regionCode.text = parts.last.toUpperCase();
      } else {
        debugPrint('Huruf tidak ditemukan');
      }
    });
  }

  Future cropImage() async {
    List<int> imageDatas = byteData!.buffer.asUint8List();
    image_.Image? originalImage = image_.decodeImage(imageDatas);
    final directory = await getExternalStorageDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fileSave = File('${directory!.path}/$fileName');

    int x = (boundingBox1[0] * originalImage!.height / 2).round();
    int y = (boundingBox1[1] * originalImage.width / 2).round();
    int width = ((boundingBox1[2] / 1.3) * originalImage.height).round();
    int height = ((boundingBox1[3] * 3) * (originalImage.width / 1.5)).round();
    croppedImage = image_.copyCrop(originalImage, x, y, width, height);

    List<int> croppedImageData = image_.encodePng(croppedImage!);
    imageUint = Uint8List.fromList(croppedImageData);
    croppedImageWidget = Image.memory(imageUint!);
    imageCrop = await fileSave.writeAsBytes(imageUint!);
    runAlphaNumericDetection();
  }

  @override
  Widget build(BuildContext context) {
    // for (var i in platDetect) {
    //   print(i!.className);
    // }

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
              : !kDebugMode
                  // ? Image.memory(threshold)
                  ? Image.file(
                      File(dilatePath!),
                    )
                  : platModel.renderBoxesOnImage(image90!, platDetect),
          Text(
            'Hasil Plat Nomor : ${cityCode.text} ${registeredcode.text} ${regionCode.text}',
            style: const TextStyle(color: Colors.white),
          ),
          imageCrop == null
              ? const Text(
                  'Cropped image tidak ada',
                  style: TextStyle(color: Colors.white),
                )
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: ListTile(
                    title: const Text(
                      'Crop Image',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white)),
                        child: Image.file(imageCrop!)),
                  )),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        cityCode.clear();
                        registeredcode.clear();
                        regionCode.clear();
                        plat.clear();
                        alphaNumericBox.clear();
                        cropImage();
                      });
                    },
                    child: const Text('Crop Image')),
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
