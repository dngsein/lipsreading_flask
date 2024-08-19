import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';

class VideoSelectionPage extends StatefulWidget {
  const VideoSelectionPage({super.key});

  @override
  VideoSelectionPageState createState() => VideoSelectionPageState();
}

class VideoSelectionPageState extends State<VideoSelectionPage> {
  File? _video;
  String? _predictionResult;
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoPlayerController;

  // Function to select a video from the gallery
  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() {
        _video = File(video.path);
        _predictionResult =
            null; // Reset prediction result when a new video is selected
        _initializeVideoPlayer();
      });
    }
  }

  // Initialize the video player
  void _initializeVideoPlayer() {
    if (_video != null) {
      _videoPlayerController = VideoPlayerController.file(_video!)
        ..initialize().then((_) {
          setState(() {}); // Ensure the first frame is shown
          _videoPlayerController!.play();
        });
    }
  }

  // Function to upload the selected video to the Flask server and get the prediction result
  Future<void> _processVideo() async {
    if (_video == null) {
      // Show a dialog or a snackbar if no video is selected
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Video Selected'),
            content: const Text('Please select a video first.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final Uri uri = Uri.parse('http://192.168.0.104:5000/upload');
    final http.MultipartRequest request = http.MultipartRequest('POST', uri);

    final http.MultipartFile video = await http.MultipartFile.fromPath(
      'video',
      _video!.path,
      contentType: MediaType('video', 'mp4'),
    );

    request.files.add(video);

    final http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final http.Response res = await http.Response.fromStream(response);
      final Map<String, dynamic> responseData = json.decode(res.body);
      setState(() {
        _predictionResult = responseData['predicted_text'];
      });
    } else {
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select and Process Video'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickVideo,
              child: const Text('Choose Video'),
            ),
            if (_videoPlayerController != null &&
                _videoPlayerController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _processVideo,
              child: const Text('Process Video'),
            ),
            const SizedBox(height: 20),
            _predictionResult != null
                ? Text('Prediction: $_predictionResult')
                : const Text('No prediction yet'),
          ],
        ),
      ),
    );
  }
}
