import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../auth/api_service.dart';
import 'gallery_model.dart';

class GalleryService {
  Future<GalleryResponse> fetchGallery({int limit = 10, int offset = 0}) async {
    try {
      final response = await apiService.get('/gallery', params: {
        'limit': limit,
        'offset': offset,
      });
      return GalleryResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadImages(List<PlatformFile> platformFiles) async {
    try {
      final formData = FormData();
      for (final file in platformFiles) {
        if (file.bytes != null) {
          formData.files.add(MapEntry(
            'images',
            MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
            ),
          ));
        } else if (file.path != null) {
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
            ),
          ));
        }
      }

      await apiService.post('/gallery', formData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteImages(List<String> imageIds) async {
    try {
      await apiService.delete('/gallery', data: {
        'imageIds': imageIds,
      });
    } catch (e) {
      rethrow;
    }
  }
}
