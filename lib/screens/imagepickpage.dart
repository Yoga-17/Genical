import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medhack/geminiapi.dart';
import 'package:medhack/screens/infopage.dart';

File? galleryFile;
XFile? xfilePick;

class Imagepickpage extends StatefulWidget {
  const Imagepickpage({super.key});

  @override
  State<Imagepickpage> createState() => _ImagepickpageState();
}

class _ImagepickpageState extends State<Imagepickpage> {
  File? galleryFile;
  final picker = ImagePicker();
  Future<String>? output;
  String buttonText = "Let's Genical";
  bool isRetry = false;
  bool isProcessing = false; // Flag to track API call status
  bool isApiCalled = false; // Flag to track FastAPI call

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showPickerAndCamera(context: context));
  }

  void _showPicker({required BuildContext context}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPickerAndCamera({required BuildContext context}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showcamera({required BuildContext context}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future getImage(ImageSource img) async {
    final pickedFile = await picker.pickImage(source: img);
    xfilePick = pickedFile;
    if (mounted) {
      setState(() {
        if (xfilePick != null) {
          galleryFile = File(xfilePick!.path);
          isApiCalled = false; // Reset flag when a new image is picked
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nothing is selected')));
        }
      });
    }
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Retry'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('The output is retry.'),
                Text('Please try uploading the image again.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                buttonText = "Let's Genical";
                _showPickerAndCamera(context: context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processImage(BuildContext context) async {
    if (galleryFile != null && !isApiCalled) {
      setState(() {
        buttonText = "Processing...";
        isProcessing = true; // Set flag to true when processing starts
        isApiCalled = true; // Set flag to true to prevent multiple API calls
      });

      output = GeminiApi(xfilePick: xfilePick!).sendImageToGeminiAPI();

      String result = await output!;
      if (!mounted) return;

      if (result == ' retry') {
        setState(() {
          buttonText = "Retry";
          galleryFile = null;
          isProcessing = false; // Reset flag when processing is done
          isApiCalled = false; // Reset flag when processing is done
        });
        _showMyDialog();
      } else {
        print('called from imagepickpage');

        setState(() {
          print('set state of isprocessing to false');
          isProcessing = false; // Reset flag when processing is done
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Infopage(
              xfilePick: xfilePick!,
              responseText: output!,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nothing is selected or API is already called')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              _showPicker(context: context);
            },
            icon: const Icon(Icons.attach_file),
          ),
          IconButton(
            onPressed: () {
              _showcamera(context: context);
            },
            icon: const Icon(Icons.camera_alt_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Upload the medicine image 🌟',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Georgia",
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Make sure that the image has details in it and good lighting',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: "Georgia",
                ),
              ),
              const SizedBox(height: 70),
              SizedBox(
                height: 430.0,
                width: 430.0,
                child: galleryFile == null
                    ? const Center(child: Text('Sorry, nothing selected!!'))
                    : Center(child: Image.file(galleryFile!)),
              ),
              ElevatedButton(
                onPressed: isProcessing ? null : () => _processImage(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(34, 96, 255, 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
