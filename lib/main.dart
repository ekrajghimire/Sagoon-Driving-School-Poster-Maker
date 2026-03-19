import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

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
  static const _templateAssetPath = 'assets/images/poster_template.png';

  // Template is 1024x1024 (your uploaded PNG).
  static const double _posterW = 1024;
  static const double _posterH = 1024;

  // Tuned for this specific template.
  static const Rect _photoRect = Rect.fromLTWH(332, 150, 360, 360);
  static const double _photoCornerRadius = 180;

  static const Rect _nameRect = Rect.fromLTWH(120, 560, 784, 80);

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
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      setState(() {
        _pickedXFile = xfile;
        _pickedBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sharePoster() async {
    try {
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share is not supported on Web build.')),
        );
        return;
      }

      final pngBytes = await _capturePosterPng();
      final file = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'sagoon_poster_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await SharePlus.instance.share(
        ShareParams(
          text: 'Sagoon Poster',
          files: [file],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
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
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _savePoster,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: const Text('Save Poster'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _sharePoster,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sagoon Poster Maker'),
      ),
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
                        width: _posterW,
                        height: _posterH,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(_templateAssetPath, fit: BoxFit.cover),
                            Positioned.fromRect(
                              rect: _photoRect,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  _photoCornerRadius,
                                ),
                                child: ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  child: _pickedXFile == null
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
                              rect: _nameRect,
                              child: Center(
                                child: Text(
                                  _nameController.text.trim().isEmpty
                                      ? 'YOUR NAME'
                                      : _nameController.text.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 8,
                                        color: Color(0xAA000000),
                                      ),
                                    ],
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
