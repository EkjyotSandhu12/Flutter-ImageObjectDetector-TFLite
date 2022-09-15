import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_detection/widgets/imageExpanded.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

const String ssd = "SSD MobileNet";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: AppBarTheme(color: Color(0xFF2F3C7E)),
        canvasColor: Color(0xFFFBEAEB),
      ),
      debugShowCheckedModeBanner: false,
      home: TfliteHome(),
    );
  }
}

class TfliteHome extends StatefulWidget {
  @override
  _TfliteHomeState createState() => _TfliteHomeState();
}

class _TfliteHomeState extends State<TfliteHome> {
  late File _image = File("");
  bool _busy = false;
  List _recognitions = [];
  final ImagePicker _picker = ImagePicker();

  String detectedObjectName = "";
  Map detectedObject = {};
  double accuracy = 0;
  List<String> similarImages = [];

  @override
  void initState() {
    super.initState();
    _busy = true;

    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  loadModel() async {
    Tflite.close();
    try {
      String? res;
      res = await Tflite.loadModel(
        model: "assets/tflite/ssd_mobilenet.tflite",
        labels: "assets/tflite/ssd_mobilenet.txt",
      );
    } on PlatformException {
      print("Failed to load the model");
    }
  }

  selectFromImagePicker() async {
    XFile? Ximage = await _picker.pickImage!(source: ImageSource.gallery);

    if (Ximage == null) return;
    setState(() {
      _busy = true;
    });

    File image = File(Ximage!.path);

    predictImage(image);
  }

  predictImage(File image) async {
    if (image == null) return;

    await ssdMobileNet(image);

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  ssdMobileNet(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path, numResultsPerClass: 1);

    _recognitions = recognitions!;
    await objectDetection();
    await getSimilarImages();
    setState(() {});
  }

  Future objectDetection() async {
    var HigestAccuractObject = _recognitions[0];

    _recognitions.forEach((obj) {
      if (obj['confidenceInClass'] >
          HigestAccuractObject['confidenceInClass']) {
        HigestAccuractObject = obj;
      }
    });

    detectedObject = HigestAccuractObject;
    detectedObjectName = HigestAccuractObject['detectedClass'];
    accuracy = HigestAccuractObject['confidenceInClass'] * 100;

    return Future<Void>;
  }

  Future getSimilarImages() async {
    if (similarImages.isNotEmpty) {
      print("cleared");
      similarImages.clear();
    }

    var response = await http.get(Uri.parse(
        "https://api.unsplash.com/search/photos?page=1&query=$detectedObjectName&client_id=GlUpzb7r1-eZ4vbhFDszmeI81YSuJPMR9kkah2QTbZQ"));
    var resposeData = json.decode(response.body) as Map<String, dynamic>;
    var imagesArray = resposeData['results'];
    for (int i = 0; i < 10; i++) {
      similarImages.add(imagesArray[i]['urls']['regular']);
    }
  }

  Widget imageGridList(var size) {
    return Container(
      height: 300,
      width: size.width - 30,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          border: Border.all(
              width: 6, color: Color(0xFF2F3C7E), style: BorderStyle.solid)),
      child: GridView.builder(
        itemCount: similarImages.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                    onTap: () => showDialog(
                        context: context,
                        builder: (context) => imageExpanded(
                              imgUrl: similarImages[index],
                            )),
                    child: Image.network(similarImages[index],
                        fit: BoxFit.cover))),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    print(detectedObject);

    return Scaffold(
      appBar: AppBar(
        title: Text("Image Detection"),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.image),
        tooltip: "Pick Image from gallery",
        onPressed: selectFromImagePicker,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Center(
                  child: Container(
                  margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                  width: size.width / 1.4,
                  height: size.width / 1.4,
                  child: _busy
                      ? Center(child: CircularProgressIndicator())
                      : _image.path == ""
                          ? Center(child: Text("No Image Selected"))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _image,
                                fit: BoxFit.cover,
                              ),
                            ),
              ),
                ),
                if(detectedObject.isNotEmpty) Positioned(
                  width: detectedObject['rect']['w'] * size.width / 1.4 + 40,
                  left: detectedObject['rect']['x'] * size.width / 1.4 + 40,
                  height: detectedObject['rect']['h'] * size.width/1.4,
                  top: detectedObject['rect']['y'] * size.width/1.4,
                  child: Container(
                    margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red,
                        width: 4,
                      )
                    ),
                  ),
                ),
              ]
            ),
            Text(
                "Detected: ${detectedObjectName}       Confidence: ${accuracy.toStringAsFixed(0)}%"),
            SizedBox(height: 30),
            Text("Similar Images...", style: TextStyle(fontSize: 30)),
            imageGridList(size),
          ],
        ),
      ),
    );
  }
}
