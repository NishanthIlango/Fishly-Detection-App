import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';
import 'package:flutter_pytorch/pigeon.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speedometer_chart/speedometer_chart.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  File? _image;
  List<ResultObjectDetection>? _output;
  late ModelObjectDetection _objectModel;
  List<ResultObjectDetection?> objDetect = [];
  final picker = ImagePicker();
  bool showIcons=false;
  final urlImage=[
    'assets/image/1.png',
    'assets/image/2.png',
    'assets/image/3.png',
    'assets/image/4.jpg',
    'assets/image/5.jpg'
  ];

  final urlNames=[
    'Cakalang -Katsuwonus Pelamis-',
    'Kakap Merah -Lutjanus Malabaricus-',
    'Kakatua -Saridae-',
    'Kembung -Rastrelliger Kanagurta-',
    'Malalugis -Decapterus Macarellus-',
    'Unlabeled'
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    String pathObjectDetectionModel = "assets/models/Trained_100eps_v5.torchscript";
    try {
      _objectModel = await FlutterPytorch.loadObjectDetectionModel(
        pathObjectDetectionModel,
        6,  // Ensure this matches the number of classes in your model
        640,
        640,
        labelPath: "assets/models/label.txt",
      );
      setState(() {
        _loading = false;
      });
    } catch (e) {
      print("Error loading model: $e");
      setState(() {
        _loading = false;
      });
    }
  }
  

  Future<void> detectImage(File image) async {
    setState(() {
      _loading = true;
    });

    // Run the model on the image
    List<ResultObjectDetection>? prediction = (await _objectModel.getImagePrediction(
      await image.readAsBytes(),
      minimumScore: 0.5,  // Adjust confidence threshold as needed
      IOUThershold: 0.3,  // Adjust IoU threshold as needed
    )).cast<ResultObjectDetection>();
    objDetect.forEach((element) {
      print({
        "score": element?.score,
        "className": element?.className,
        "class": element?.classIndex,
        "rect": {
          "left": element?.rect.left,
          "top": element?.rect.top,
          "width": element?.rect.width,
          "height": element?.rect.height,
          "right": element?.rect.right,
          "bottom": element?.rect.bottom,
        },
      });
    });

    setState(() {
      _output = prediction;
      _loading = false;
    });

    // Debugging output
    if (_output != null) {
      for (var result in _output!) {
        print('Detected: ${result.className} with confidence: ${result.score}');
      }
    } else {
      print('No detection occurred.');
    }
  }

  Future<void> pickImage() async {
    var image = await picker.getImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _image = File(image.path);
    });

    await detectImage(_image!);
  }

  Future<void> pickGalleryImage() async {
    var image = await picker.getImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _image = File(image.path);
    });

    await detectImage(_image!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 17, 92, 154),
        leading: _image!=null?
        IconButton(onPressed: () {
          setState(() {
            _image=null;
          });
        }, icon: Icon(Icons.arrow_back_ios,color: Colors.white,)):Container(),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Row with icons, only shown when 'showIcons' is true
          if (showIcons)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    FloatingActionButton(
                  onPressed: () {
                    pickImage();
                    showIcons=!showIcons;
                  },
                  // heroTag: 'camera',
                  backgroundColor: Color.fromARGB(255, 43, 93, 134),
                  // shape: CircleBorder(),
                  child: Icon(Icons.camera,color: Colors.white,),
                ),
                SizedBox(height: 10,),
                Text("Camera",style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                ),)
                  ],
                ),
                SizedBox(width: 140),
                Column(
                  children: [
                    FloatingActionButton(
                  onPressed: () {
                    pickGalleryImage();
                    showIcons=!showIcons;
                  },
                  backgroundColor: Color.fromARGB(255, 43, 93, 134),
                  heroTag: 'gallery',
                  child: Icon(Icons.photo,color: Colors.white,),
                ),
                SizedBox(height: 10,),
                Text("Gallery",style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold 
                ),),
                  ],
                )
              ],
            ),
          
          SizedBox(height: 20), // Space between FAB and row

          // Main FAB
          FloatingActionButton(
            onPressed: () {
              setState(() {
                showIcons = !showIcons; // Toggle visibility of Row
              });
            },
            backgroundColor: Color.fromARGB(255, 43, 93, 134),
            child: Icon(IconlyLight.scan,color: Colors.white,),
          ),
          SizedBox(height: 10),
          Text("Capture",style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold
          ),),
          SizedBox(height: 10,)
        ],
      ),
      body: GestureDetector(
        onTap: (){
          setState(() {
            showIcons =false;
          });
        },
        child: Stack(
          children: [
            Positioned(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color.fromARGB(255, 17, 92, 154),Colors.lightBlue],
                  begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4,0.7],
                    tileMode: TileMode.repeated
                  )
                ),
                
              ),
            ),
            Positioned(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if(_image!=null)
                        const SizedBox(height: 20),
                      if(_image==null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10,bottom: 10),
                              child: RichText(text: TextSpan(
                                style: TextStyle(fontSize: 35, color: Colors.white,fontFamily: 'Ubuntu'),
                                children: [
                                  TextSpan(
                                   text: 'Discover  ',style: TextStyle(fontWeight: FontWeight.w900) 
                                  ),
                                  
                                  TextSpan(
                                    text: ' your'
                                  ),
                                ]
                              )),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RichText(text: TextSpan(
                                style: TextStyle(fontSize: 35, color: Colors.white,fontFamily: 'Ubuntu'),
                                children: [
                                  TextSpan(
                                    text: 'fish   partner'
                                  )
                                ]
                              )),
                            ),
                            SizedBox(height: 40,),
                            Text("Detectable fishes",style: TextStyle(fontSize: 25,color: Colors.white,fontFamily: 'Ubuntu',),),
                            SizedBox(height: 30,),
                            Container(
                              width: MediaQuery.of(context).size.width-40,
                              child: CarouselSlider.builder(itemCount: urlImage.length, itemBuilder: (context,index,realIndex){
                                final urlImages=urlImage[index];
                                final fishName=urlNames[index];
                                return buildImage(urlImages,fishName,index);
                              }, options: CarouselOptions(
                                height: 300,
                                
                                autoPlay: true,
                                reverse: false,
                                autoPlayAnimationDuration: Duration(seconds: 4)
                              )),
                            )
                           
                          ]
                        ),
                      Center(
                        child: _loading
                            ? CircularProgressIndicator()
                            : _image != null
                                ? SingleChildScrollView(
                                  child: Column(
                                      children: <Widget>[
                                        Text("Detected fish partner",style: TextStyle(
                                          fontSize: 25,fontFamily: 'Ubuntu',color: Colors.white),),
                                        SizedBox(height: 20,),
                                        Container(
                                          height: 200,
                                          width: MediaQuery.of(context).size.width-80,
                                          child: _objectModel.renderBoxesOnImage(_image!, objDetect),
                                        ),
                                        SizedBox(height: 30,),
                                        if(_output != null && _output!.isNotEmpty)
                                          Container(
                                            child: Column(
                                              children:[ 
                                                _output != null && _output!.isNotEmpty
                                            ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
      
                                                Text(
                                                    '${_output!.first.className}',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                  SizedBox(height: 10,),
                                                  // if(_output!.first.className=='Malalugis -Decapterus Macarellus-')
                                                  //   Text("data",style: TextStyle(
                                                  //     color: Colors.white,
                                                  //     fontSize: 40
                                                  //   ),)
                                              ],
                                            )
                                            : Text(
                                                'No objects detected.',
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              
                                                SizedBox(height: 20,),
                                                Container(
                                                  child: SpeedometerChart(
                                                  value: _output!.first.score*100,
                                                  dimension: 300,
                                                  minValue: 0,
                                                  hasIconPointer: false,
                                                  maxValue: 100,
                                                  graphColor: [Colors.red,Colors.yellow,Colors.green],
                                                //  valueWidget: Text(" ${(_output!.first.score * 100).toStringAsFixed(0)}%"),
                                                  pointerColor: Colors.black,
                                                  minWidget: Text("0",style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                  ),),
                                                  maxWidget: Text("100",style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20
                                                  ),),
                                                ),
                                                ),
                                                SizedBox(height: 5,),
                                                Text(" ${(_output!.first.score * 100).toStringAsFixed(0)}% Confident",style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.bold
                                                ),)
                                                ]
                                            ),
                                          ),
                                         
                                      ],
                                    ),
                                )
                                : Container(),
                      ),
                      
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );

    
  }
  Widget buildImage(String urlImage,String fishName,int index)=> Container(
    margin: EdgeInsets.symmetric(horizontal: 10),
    color: Colors.transparent,
    child: Container(
      height: 200,
      
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(urlImage),fit: BoxFit.fill
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Text(fishName,style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold
        ),),
      ),
    )
  );
}