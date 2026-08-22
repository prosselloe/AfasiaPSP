import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:logopeda/services/asset_loader_service.dart';

class HybridImage extends StatefulWidget {
  final String imagePath;
  final BoxFit? fit;

  const HybridImage({super.key, required this.imagePath, this.fit});

  @override
  State<HybridImage> createState() => _HybridImageState();
}

class _HybridImageState extends State<HybridImage> {
  Future<Uint8List>? _imageFuture;

  @override
  void initState() {
    super.initState();
    if (widget.imagePath.isNotEmpty) {
      _imageFuture = AssetLoaderService.instance.loadBytes(widget.imagePath);
    }
  }

  @override
  void didUpdateWidget(HybridImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imagePath != oldWidget.imagePath) {
      if (widget.imagePath.isNotEmpty) {
        setState(() {
           _imageFuture = AssetLoaderService.instance.loadBytes(widget.imagePath);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePath.isEmpty) {
      return const SizedBox.shrink(); 
    }

    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          developer.log('Failed to load image: ${widget.imagePath}', name: 'HybridImage.error', error: snapshot.error, stackTrace: snapshot.stackTrace);
          return const Icon(Icons.broken_image, color: Colors.grey, size: 40);
        } else if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: widget.fit ?? BoxFit.contain);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
