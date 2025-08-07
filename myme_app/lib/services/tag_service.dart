// lib/services/tag_service.dart

import 'package:myme_app/models/tag.dart';

class TagService {
  static final TagService _instance = TagService._internal();

  factory TagService() {
    return _instance;
  }

  TagService._internal();

  final List<Tag> _tags = []; // 임시 인메모리 저장소

  Future<List<Tag>> getAllTags() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_tags);
  }

  Future<Tag?> getTagById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _tags.firstWhere((tag) => tag.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addTag(Tag tag) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _tags.add(tag);
  }

  Future<void> updateTag(Tag tag) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      _tags[index] = tag;
    }
  }

  Future<void> deleteTag(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _tags.removeWhere((tag) => tag.id == id);
  }
}