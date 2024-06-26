import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hellogram/ui/helpers/helpers.dart';
import 'package:hellogram/ui/screens/login/login_page.dart';
import 'package:hellogram/ui/screens/login/register_page.dart';
import 'package:hellogram/ui/widgets/widgets.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StartedPage extends StatefulWidget {
  const StartedPage({Key? key}) : super(key: key);

  @override
  State<StartedPage> createState() => _StartedPageState();
}

class _StartedPageState extends State<StartedPage> {
  late CameraController _cameraController;
  late FaceDetector _faceDetector;
  String mood = "";
  String face = "emotion";
  void sendRequest(filename) async {
    var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            "http://192.168.62.147:5000/predict")); // This is local ip of the network on which flask server is running
    request.files.add(await http.MultipartFile.fromPath('image', filename));
    request.fields.addAll({"face": "emotion"});
    try {
      var res = await request.send();
      var body = await res.stream.bytesToString();
      setState(() {
        face = jsonDecode(body)['prediction'];
      });
      print(face);
    } catch (e) {
      print(e.toString());
    }
  }

  bool isVisible = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: true,
        enableTracking: true,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceDetector.close();
    super.dispose();
  }

  void initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[1], ResolutionPreset.medium);
    await _cameraController.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 55,
              width: size.width,
              child: Row(
                children: [
                  Image.asset(
                    'assets/img/hello.png',
                    height: 30,
                    color: Colors.white,
                  ),
                  const TextCustom(text: ' Social', fontSize: 17)
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(30.0),
                width: size.width,
                child: SvgPicture.asset(
                  'assets/svg/undraw_mobile_content_xvgr.svg',
                ),
              ),
            ),
            const TextCustom(
              text: 'Welcome !',
              letterSpacing: 2.0,
              color: Color.fromARGB(255, 128, 0, 126),
              fontWeight: FontWeight.w600,
              fontSize: 30,
            ),
            const SizedBox(height: 10.0),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: TextCustom(
                text:
                    'The best place to write stories and share your experiences.',
                textAlign: TextAlign.center,
                maxLines: 2,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SizedBox(
                height: 50,
                width: size.width,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(colors: [
                        Color.fromARGB(125, 154, 8, 152),
                        Color.fromARGB(255, 128, 0, 126),
                      ])),
                  child: TextButton(
                      style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0))),
                      child: const TextCustom(
                          text: 'Log in', color: Colors.black, fontSize: 20),
                      onPressed: () {
                        captureImage();
                        Navigator.push(
                            context, routeSlide(page: const LoginPage()));
                      }),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Container(
                height: 50,
                width: size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(colors: [
                        Color.fromARGB(125, 154, 8, 152),
                        Color.fromARGB(255, 128, 0, 126),
                      ])),
                  child: TextButton(
                    child: const TextCustom(
                      text: 'Sign up',
                      fontSize: 20,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.push(
                        context, routeSlide(page: const RegisterPage())),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  void captureImage() async {
    try {
      // final _picker = ImagePicker();
      final XFile image = await _cameraController.takePicture();
      //XFile? image1 = await _picker.pickImage(source: ImageSource.camera);
      setState(() {
        isVisible = false;
        sendRequest(image.path);
        // Reset visibility when capturing a new image
      });
      extractData(image.path);
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  void extractData(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    List<Face> faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty && faces[0].smilingProbability != null) {
      double? prob = faces[0].smilingProbability;

      if (prob! > 0.8) {
        setState(() {
          mood = "Happy";
          Fluttertoast.showToast(msg: "hey good to see you happy and $face ");
        });
      } else if (prob > 0.3 && prob < 0.8) {
        setState(() {
          mood = "Normal";
          Fluttertoast.showToast(msg: "hey good to see you normal and $face");
        });
      } else if (prob > 0.06152385 && prob < 0.3) {
        setState(() {
          mood = "Sad";
          Fluttertoast.showToast(msg: "Hey why are you Sad and $face");
        });
      } else {
        setState(() {
          mood = "Angry";
          Fluttertoast.showToast(msg: "Hey why are you Angry and $face");
        });
      }
      setState(() {
        isVisible = true;
      });
    }
  }
}
