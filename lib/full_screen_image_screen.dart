import 'package:flutter/material.dart';

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
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain, // Assegura que la imatge es vegi completa inicialment
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 50),
                    SizedBox(height: 8),
                    Text(
                      'Error al carregar la imatge.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
