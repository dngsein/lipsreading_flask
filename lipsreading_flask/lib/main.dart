import 'package:flutter/material.dart';
import './pages/video_selection_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to the VideoSelectionPage when the button is pressed
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const VideoSelectionPage()),
            );
          },
          child: const Text('Select Video for Lip Reading'),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: HomePage(),
  ));
}
