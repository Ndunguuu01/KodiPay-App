import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../providers/marketplace_provider.dart';
import '../models/marketplace_ad.dart';
import '../utils/constants.dart';

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key});

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  XFile? _mediaFile;
  Uint8List? _webMediaBytes;
  String _mediaType = 'image'; // 'image' or 'video'
  final _picker = ImagePicker();
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Request permissions
      if (kIsWeb) {
        // Web permissions are handled by browser
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.photos.status;
        if (!status.isGranted) {
          await Permission.photos.request();
        }
        // Also check storage for older Android
        final storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }
      }

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _mediaFile = pickedFile;
          _webMediaBytes = bytes;
          _mediaType = 'image';
          _videoController?.dispose();
          _videoController = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
       // Request permissions
      if (kIsWeb) {
        // Web permissions are handled by browser
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.videos.status;
        if (!status.isGranted) {
          await Permission.videos.request();
        }
         // Also check storage for older Android
        final storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }
      }

      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        VideoPlayerController controller;
        if (kIsWeb) {
           controller = VideoPlayerController.networkUrl(Uri.parse(pickedFile.path));
        } else {
           // On mobile we can't use File class if we removed dart:io? 
           // Wait, we can't use File class. 
           // But VideoPlayerController.file requires File.
           // So we must use networkUrl with file:// URI?
           // Or contentUri?
           controller = VideoPlayerController.networkUrl(Uri.parse(pickedFile.path)); // Try this for now
           // Actually, pickedFile.path on mobile is a file path.
           // We can use VideoPlayerController.file(File(pickedFile.path)) BUT we removed dart:io.
           // So we have to use networkUrl(Uri.file(pickedFile.path)).
           controller = VideoPlayerController.networkUrl(Uri.file(pickedFile.path));
        }
        
        await controller.initialize();

        if (controller.value.duration.inSeconds > 30) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video too long. Please select a video under 30 seconds.')),
            );
          }
          return;
        }
        
        setState(() {
          _mediaFile = pickedFile;
          _mediaType = 'video';
          _videoController = controller;
        });
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId == null) return;

    final ad = MarketplaceAd(
      title: _titleController.text,
      description: _descriptionController.text,
      contactInfo: _contactController.text,
      imageUrl: null, // Image handled separately
      type: _mediaType,
      userId: userId,
    );

    final success = await Provider.of<MarketplaceProvider>(context, listen: false).postAd(ad, _mediaFile);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad posted successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Provider.of<MarketplaceProvider>(context, listen: false).errorMessage ?? 'Failed to post ad')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post an Ad'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Add Image'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Add Video'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_mediaFile != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                    image: _mediaType == 'image' && _webMediaBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_webMediaBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _mediaType == 'video' && _videoController != null && _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : _mediaType == 'image' 
                          ? null 
                          : const Center(child: CircularProgressIndicator()),
                )
              else
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.perm_media, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No media selected', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Ad Title (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Info (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.contact_phone),
                ),
              ),
              const SizedBox(height: 32),
              Consumer<MarketplaceProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Post Ad', style: TextStyle(fontSize: 18)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
