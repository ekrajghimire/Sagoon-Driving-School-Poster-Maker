import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'crop_screen.dart';
import 'poster_layout.dart';
import 'platform/save_png.dart';

void main() => runApp(const SagoonPosterMakerApp());

class SagoonPosterMakerApp extends StatelessWidget {
  const SagoonPosterMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sagoon Poster Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E6B73)),
        useMaterial3: true,
      ),
      home: const PosterMakerScreen(),
    );
  }
}

class PosterMakerScreen extends StatefulWidget {
  const PosterMakerScreen({super.key});

  @override
  State<PosterMakerScreen> createState() => _PosterMakerScreenState();
}

class _PosterMakerScreenState extends State<PosterMakerScreen> {
  final _boundaryKey = GlobalKey();
  final _nameController = TextEditingController(text: 'YOUR NAME');
  final _picker = ImagePicker();

  XFile? _pickedXFile;
  Uint8List? _pickedBytes;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2000,
      );
      if (xfile == null || !mounted) return;
      final bytes = await xfile.readAsBytes();
      if (!mounted) return;

      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          builder: (_) => CropScreen(imageBytes: bytes),
        ),
      );
      if (cropped != null && mounted) {
        setState(() {
          _pickedXFile = xfile;
          _pickedBytes = cropped;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  Future<bool> _ensureSavePermission() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.photosAddOnly.request();
      return status.isGranted || status.isLimited;
    }

    // Android: request Photos on 33+, Storage on older devices.
    final photos = await Permission.photos.request();
    if (photos.isGranted) return true;

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<Uint8List> _capturePosterPng() async {
    final context = _boundaryKey.currentContext;
    if (context == null) throw StateError('Poster not ready yet.');

    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('Poster boundary not found.');

    // 3.0 gives sharp results without huge memory.
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('Failed to encode PNG.');
    return byteData.buffer.asUint8List();
  }

  Future<void> _savePoster() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final pngBytes = await _capturePosterPng();
      final filename =
          'sagoon_poster_${DateTime.now().millisecondsSinceEpoch}.png';

      if (!kIsWeb) {
        final ok = await _ensureSavePermission();
        if (!ok) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied to save images.')),
          );
          return;
        }
      }

      final success = await savePngBytes(
        pngBytes: pngBytes,
        filename: filename,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (kIsWeb ? 'Poster downloaded.' : 'Poster saved to gallery.')
                : 'Failed to save.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controls = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Upload Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _savePoster,
              icon:
                  _saving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.download_rounded),
              label: const Text('Save Poster'),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Sagoon Poster Maker by Manish')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: PosterLayout.posterWidth,
                        height: PosterLayout.posterHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              PosterLayout.templateAssetPath,
                              fit: BoxFit.cover,
                            ),
                            Positioned.fromRect(
                              rect: PosterLayout.photoRect,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  PosterLayout.photoCornerRadius,
                                ),
                                child: ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  child:
                                      _pickedXFile == null
                                          ? const Center(
                                            child: Icon(
                                              Icons.person_rounded,
                                              size: 96,
                                              color: Colors.white70,
                                            ),
                                          )
                                          : Image.memory(
                                            _pickedBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                ),
                              ),
                            ),
                            Positioned.fromRect(
                              rect: PosterLayout.nameRect,
                              child: Center(
                                child: Text(
                                  _nameController.text.trim().isEmpty
                                      ? 'YOUR NAME'
                                      : _nameController.text.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: PosterLayout.nameFontSize,
                                    fontWeight: PosterLayout.nameFontWeight,
                                    color: PosterLayout.nameColor,
                                    shadows: PosterLayout.nameShadows,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            controls,
          ],
        ),
      ),
    );
  }
}
