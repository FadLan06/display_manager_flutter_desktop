import 'package:screen_retriever/screen_retriever.dart';

class DisplayService {
  Future<List<Display>> getDisplays() async {
    return await screenRetriever.getAllDisplays();
  }
}
