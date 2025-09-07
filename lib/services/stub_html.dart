// Stub file for non-web platforms where dart:html is not available
// This provides placeholder implementations for web-only functionality

class _MockStorage {
  final Map<String, String?> _storage = <String, String?>{};
  
  String? operator [](String key) => _storage[key];
  void operator []=(String key, String? value) => _storage[key] = value;
  void remove(String key) => _storage.remove(key);
  Iterable<String> get keys => _storage.keys;
}

class _MockWindow {
  final localStorage = _MockStorage();
  final sessionStorage = _MockStorage();
}

// Export mock window to match dart:html interface
final window = _MockWindow();
