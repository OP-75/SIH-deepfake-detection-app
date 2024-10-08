import 'dart:convert';
import 'dart:io';

import 'package:fake_vision/screens/output_screen.dart';
import 'package:fake_vision/utils/colors.dart';
import 'package:fake_vision/utils/custom_text_style.dart';
import 'package:fake_vision/utils/global_variables.dart';
import 'package:fake_vision/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _image;
  String path = '';
  String type = '';
  String label = '';
  String confidence = '';
  String imageStr = '';

  var data;

  // Initialize video player
  late VideoPlayerController? _videoController;

  void initState() {
    super.initState();
    // Set the status bar color when the screen is created
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: colorStatusBar, // Set your desired status bar color
      statusBarIconBrightness: Brightness.light,
    ));
    _videoController = VideoPlayerController.network('');

    // Set up listener to update video controller state
    _videoController!.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _linkController.dispose();
    // Dispose of the video player when the widget is disposed.
    _videoController!.dispose();
  }

  void scan() async {
    // set loading to true
    setState(() {
      _isLoading = true;
    });

    // Simulating some asynchronous task
    await Future.delayed(Duration(seconds: 2));
    if (path.isNotEmpty) {
      print("****************");

      print(path);
      try {
        var request = http.MultipartRequest(
            'POST',
            Uri.parse(
                'https://insect-ready-minnow.ngrok-free.app/predict_media'));
        // var request = http.MultipartRequest(
        //     'POST', Uri.parse('http://10.0.2.2:5000/predict_media'));

        // Add the video file to the request
        request.files.add(await http.MultipartFile.fromPath('file', path));

        // Send the request
        var streamedResponse = await request.send();

        // Get the response
        var response = await http.Response.fromStream(streamedResponse);

        // Parse the response data
        var decoded = jsonDecode(response.body);

        // Update the output state
        setState(() {
          label = decoded['label'];
          confidence = decoded['confidence'];
          imageStr = json.decode(response.body)["img"].toString();

          // Navigate to the OutputScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => OutputScreen(
                    file_path: path,
                    type: type,
                    label: label,
                    confidence: confidence,
                    imageStr: imageStr)),
          );
        });
      } catch (e) {
        // Handle exceptions here
        print('Error occurred: $e');
      }
    } else {
      // Show an error message or handle the case where no video is selected
      showSnackBar(context, "No File Selected");
    }

    // set loading to false after navigation
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowCompression: true,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      if (file.extension == 'mp4') {
        showSnackBar(context, "Please select an image");
      } else {
        setState(() {
          path = file.path!;
          type = 'Image';
        });
      }
    }
  }

  Future<void> _selectFile() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          backgroundColor: blueColor,
          title: const Text(
            'Select Source',
            style: TextStyle(fontFamily: 'Inter', color: whiteColor),
          ),
          children: <Widget>[
            SimpleDialogOption(
              padding: const EdgeInsets.all(13),
              child: const Text('Image',
                  style: TextStyle(fontFamily: 'Inter', color: whiteColor)),
              onPressed: () async {
                Navigator.pop(context);
                await _selectImage();
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(13),
              child: const Text('Video',
                  style: TextStyle(fontFamily: 'Inter', color: whiteColor)),
              onPressed: () async {
                Navigator.pop(context);
                await _selectVideo();
              },
            ),
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                  decoration: BoxDecoration(
                    color: redColor, // Set the background color to red
                    borderRadius: BorderRadius.circular(35), // Rounded corners
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color:
                          Colors.white, // Text color, white for better contrast
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Future<void> _selectVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowCompression: true,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.size > 17 * 1024 * 1024) {
          // 17 MB in bytes
          showSnackBar(context, "File size exceeds 17 MB");
        } else {
          setState(() {
            path = file.path!;
            // Update video controller with selected video file
            _videoController!.dispose(); // Dispose existing controller
            _videoController = VideoPlayerController.file(File(path));
            _videoController!.initialize().then((_) {
              setState(() {});
              _videoController!.play();
              type = 'Video';
            });
          });
        }
      }
    }
  }

  Widget _buildSelectedFileWidget() {
    if (path.isEmpty) {
      // If no file is selected, show a placeholder
      return Text(
        'No file chosen',
        style: smallWhiteTextStyle,
      );
    } else {
      // If a file is selected, check if it's an image or a video
      if (path.toLowerCase().endsWith('.mp4')) {
        // Display the selected video

        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                  duration: Duration(seconds: 1),
                  child: Container(
                    color: Colors.transparent,
                    child: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Display the selected image
        return Image.file(File(path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('Images/bg13.png'), fit: BoxFit.fill),
          ),
          padding: width > webScreenSize
              ? EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width / 5)
              : const EdgeInsets.symmetric(horizontal: 24),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (width < webScreenSize)
                Image.asset('Images/app_logo-removebg.png',
                    width: 140, height: 140),
              SizedBox(height: 40),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [blue, green],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  'Scan & Detect Deepfakes',
                  style: TextStyle(
                    fontSize: 34.0,
                    fontFamily: 'Inter',
                    // The color must be set to white for the gradient to show
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 40),
              width < webScreenSize
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Upload a Video or Image",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: whiteColor,
                        ),
                      ),
                    )
                  : Text(
                      "Upload a Video or Image",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: whiteColor,
                      ),
                    ),
              const SizedBox(height: 6),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildSelectedFileWidget(),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: _selectFile,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromARGB(255, 109, 175, 175)),
                        overlayColor:
                            MaterialStateProperty.all<Color>(Colors.black),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            side: BorderSide(color: Colors.black),
                          ),
                        ),
                      ),
                      child: Text(
                        'Choose File',
                        style:
                            TextStyle(color: Colors.black, fontFamily: 'Inter'),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              InkWell(
                onTap: scan,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color.fromRGBO(53, 102, 172, 1), // light blue
                          Color.fromARGB(255, 106, 175, 169) // dark blue
                        ]),
                  ),
                  child: !_isLoading
                      ? Text(
                          'Scan',
                          style: smallWhiteTextStyle,
                        )
                      : const CircularProgressIndicator(
                          color: whiteColor,
                        ),
                ),
              ),
              // SizedBox(height: MediaQuery.of(context).size.height / 2),
              const Spacer()
            ],
          ),
        ),
      ),
    );
  }
}
