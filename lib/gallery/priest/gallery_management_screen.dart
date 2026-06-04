import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../auth/auth_service.dart';
import '../gallery_model.dart';
import '../gallery_service.dart';

class GalleryManagementScreen extends StatefulWidget {
  const GalleryManagementScreen({super.key});

  @override
  State<GalleryManagementScreen> createState() => _GalleryManagementScreenState();
}

class _GalleryManagementScreenState extends State<GalleryManagementScreen> {
  final GalleryService _galleryService = GalleryService();
  final ScrollController _scrollController = ScrollController();

  List<GalleryImage> _images = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 18;

  bool _isUploading = false;
  bool _isDeleting = false;

  final Set<String> _selectedImageIds = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialGallery();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchMoreGallery();
      }
    }
  }

  Future<void> _fetchInitialGallery() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _offset = 0;
      _images = [];
      _selectedImageIds.clear();
      _isMultiSelectMode = false;
    });

    try {
      final res = await _galleryService.fetchGallery(limit: _limit, offset: _offset);
      if (mounted) {
        setState(() {
          _images = res.images;
          _hasMore = res.hasMore;
          _offset += res.images.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Failed to load gallery images", isError: true);
      }
    }
  }

  Future<void> _fetchMoreGallery() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final res = await _galleryService.fetchGallery(limit: _limit, offset: _offset);
      if (mounted) {
        setState(() {
          _images.addAll(res.images);
          _hasMore = res.hasMore;
          _offset += res.images.length;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      await _galleryService.uploadImages(result.files);

      _showSnackBar("${result.files.length} images uploaded successfully!");
      _fetchInitialGallery();
    } catch (e) {
      _showSnackBar("Failed to upload images: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteSelectedImages() async {
    if (_selectedImageIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Selected Images?"),
        content: Text("Are you sure you want to permanently delete ${_selectedImageIds.length} images from the gallery?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _galleryService.deleteImages(_selectedImageIds.toList());
      _showSnackBar("Successfully deleted ${_selectedImageIds.length} images.");
      _fetchInitialGallery();
    } catch (e) {
      _showSnackBar("Failed to delete images: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _toggleImageSelection(String id) {
    setState(() {
      if (_selectedImageIds.contains(id)) {
        _selectedImageIds.remove(id);
        if (_selectedImageIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedImageIds.add(id);
        _isMultiSelectMode = true;
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user?.role.toLowerCase() != 'priest') {
      return const Scaffold(body: Center(child: Text("Access Denied")));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isMultiSelectMode ? "${_selectedImageIds.length} Selected" : "Gallery Management",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        actions: [
          if (_isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: "Select All",
              onPressed: () {
                setState(() {
                  _selectedImageIds.addAll(_images.map((img) => img.id));
                });
              },
            ),
          if (_isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: "Cancel Selection",
              onPressed: () {
                setState(() {
                  _selectedImageIds.clear();
                  _isMultiSelectMode = false;
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D3A99),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isUploading || _isDeleting ? null : _pickAndUploadImages,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(_isUploading ? "Uploading..." : "Upload Photos"),
                      ),
                    ),
                    if (_isMultiSelectMode) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red[100],
                          foregroundColor: Colors.red[700],
                          minimumSize: const Size(50, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isDeleting ? null : _deleteSelectedImages,
                        icon: const Icon(Icons.delete),
                        tooltip: "Delete Selected",
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _images.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _fetchInitialGallery,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                                  const Center(
                                    child: Text(
                                      "No photos in the gallery.",
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchInitialGallery,
                              child: GridView.builder(
                                controller: _scrollController,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _images.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _images.length) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final img = _images[index];
                                  final isSelected = _selectedImageIds.contains(img.id);

                                  return GestureDetector(
                                    onLongPress: () => _toggleImageSelection(img.id),
                                    onTap: () {
                                      if (_isMultiSelectMode) {
                                        _toggleImageSelection(img.id);
                                      } else {
                                        _showImagePreview(context, img);
                                      }
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            img.url,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, progress) {
                                              if (progress == null) return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              );
                                            },
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5D3A99).withOpacity(0.4),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF5D3A99), width: 3),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.check_circle, color: Colors.white, size: 28),
                                            ),
                                          )
                                        else if (_isMultiSelectMode)
                                          Positioned(
                                            top: 4,
                                            left: 4,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.4),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                            ),
                                          ),
                                        if (!_isMultiSelectMode)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedImageIds.clear();
                                                  _selectedImageIds.add(img.id);
                                                });
                                                _deleteSelectedImages();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Deleting images...",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, GalleryImage image) {
    final dateStr = image.createdAt.isNotEmpty ? image.createdAt.split('T')[0] : "";
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(image.url, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Uploaded by: ${image.uploadedBy}",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Date: $dateStr",
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}