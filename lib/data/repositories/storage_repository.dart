import 'package:firebase_storage/firebase_storage.dart';
import 'package:profit_grocery_application/utils/cart_logger.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<String>> listImageUrls(String folderPath) async {
    try {
      final listResult = await _storage.ref(folderPath).listAll();
      final urls = <String>[];
      for (final item in listResult.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      return urls;
    } catch (e) {
      CartLogger.error('STORAGE_REPO', 'Error listing images from $folderPath: $e');
      rethrow;
    }
  }
} 