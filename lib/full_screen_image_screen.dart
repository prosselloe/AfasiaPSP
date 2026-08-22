import 'package:flutter/material.dart';
import 'package:logopeda/widgets/hybrid_image.dart';

class FullScreenImageScreen extends StatelessWidget {
  final String imagePath;

  const FullScreenImageScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Assegura que la fletxa de tornar sigui blanca
      ),
      body: InteractiveViewer(
        panEnabled: true, // Permet arrossegar
        boundaryMargin: const EdgeInsets.all(20.0),
        minScale: 0.5, // Zoom mínim
        maxScale: 5.0, // Zoom màxim
        child: Center(
          child: HybridImage(imagePath: imagePath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
