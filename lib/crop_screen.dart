import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import 'poster_layout.dart';

/// Full-screen crop UI. Pops with [Uint8List] on done, or null on cancel.
class CropScreen extends StatefulWidget {
  const CropScreen({
    super.key,
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _controller = CropController();
  bool _isCropping = false;

  Future<void> _crop() async {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    _controller.crop();
  }

  void _onCropped(CropResult result) {
    setState(() => _isCropping = false);
    switch (result) {
      case CropSuccess(:final croppedImage):
        if (mounted) Navigator.of(context).pop(croppedImage);
      case CropFailure(:final cause):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Crop failed: $cause')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Photo'),
        actions: [
          TextButton(
            onPressed: _isCropping ? null : _crop,
            child: _isCropping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Done'),
          ),
        ],
      ),
      body: SafeArea(
        child: Crop(
          image: widget.imageBytes,
          controller: _controller,
          onCropped: _onCropped,
          aspectRatio: PosterLayout.cropAspectRatio,
          withCircleUi: false,
          interactive: true,
          baseColor: Colors.black,
          maskColor: Colors.black.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
