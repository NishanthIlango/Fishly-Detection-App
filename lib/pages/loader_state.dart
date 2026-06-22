import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';
import 'package:flutter_pytorch/pigeon.dart';
import 'package:speedometer_chart/speedometer_chart.dart';

class DetectionResultScreen extends StatefulWidget {
  final File image;

  DetectionResultScreen({required this.image});

  @override
  _DetectionResultScreenState createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {
  bool _loading = true;
  List<ResultObjectDetection>? _output;
  late ModelObjectDetection _objectModel;

  @override
  void initState() {
    super.initState();
    loadModelAndDetect();
  }

  Future<void> loadModelAndDetect() async {
    // Load the model
    String pathObjectDetectionModel = "assets/models/Trained_100eps_v5.torchscript";
    try {
      _objectModel = await FlutterPytorch.loadObjectDetectionModel(
        pathObjectDetectionModel,
        6,  // Number of classes in your model
        640,
        640,
        labelPath: "assets/models/label.txt",
      );

      // Once the model is loaded, detect the image
      await detectImage();
    } catch (e) {
      print("Error loading model: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> detectImage() async {
    setState(() {
      _loading = true;
    });

    try {
      // Detect the image using the model
      List<ResultObjectDetection>? prediction = (await _objectModel.getImagePrediction(
        await widget.image.readAsBytes(),
        minimumScore: 0.5,
        IOUThershold: 0.3,
      )).cast<ResultObjectDetection>();

      setState(() {
        _output = prediction;
        _loading = false;
      });
    } catch (e) {
      print("Error during detection: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Detection Results"),
        backgroundColor: Color.fromARGB(255, 17, 92, 154),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20),
                  Text("Detected fish partner", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Image.file(widget.image, height: 200),
                  SizedBox(height: 30),
                  if (_output != null && _output!.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          '${_output!.first.className}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        SpeedometerChart(
                          value: _output!.first.score * 100,
                          dimension: 300,
                          minValue: 0,
                          maxValue: 100,
                          graphColor: [Colors.red, Colors.yellow, Colors.green],
                          pointerColor: Colors.black,
                        ),
                        SizedBox(height: 5),
                        Text(
                          "${(_output!.first.score * 100).toStringAsFixed(0)}% Confident",
                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No objects detected.',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
