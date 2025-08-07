// lib/screens/all_tags_screen.dart

import 'package:flutter/material.dart';
import 'package:myme_app/models/tag.dart';
import 'package:myme_app/services/tag_service.dart';
import 'package:myme_app/services/habit_service.dart'; // HabitService 추가
import 'package:uuid/uuid.dart';

class AllTagsScreen extends StatefulWidget {
  const AllTagsScreen({super.key});

  @override
  State<AllTagsScreen> createState() => _AllTagsScreenState();
}

class _AllTagsScreenState extends State<AllTagsScreen> {
  final TagService _tagService = TagService();
  final HabitService _habitService = HabitService(); // HabitService 인스턴스
  List<Tag> _allTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final tags = await _tagService.getAllTags();
      setState(() {
        _allTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tags: \$e')),
      );
    }
  }

  Future<void> _showTagDialog({Tag? tagToEdit}) async {
    final isEditing = tagToEdit != null;
    final TextEditingController nameController = TextEditingController(text: isEditing ? tagToEdit.name : '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Tag' : 'Add New Tag'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Tag Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final tagName = nameController.text.trim();
                if (tagName.isNotEmpty) {
                  if (isEditing) {
                    final updatedTag = tagToEdit!.copyWith(name: tagName);
                    await _tagService.updateTag(updatedTag);
                  } else {
                    final newTag = Tag(id: const Uuid().v4(), name: tagName);
                    await _tagService.addTag(newTag);
                  }
                  _loadTags(); // 목록 새로고침
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTag(String tagId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: const Text('Are you sure you want to delete this tag? This will also remove it from all habits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await _tagService.deleteTag(tagId);
        // 태그가 삭제되면 해당 태그 ID를 사용하는 모든 습관에서 제거
        await _habitService.removeTagFromAllHabits(tagId);
        _loadTags(); // 목록 새로고침
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete tag: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tags'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTags.isEmpty
              ? const Center(
                  child: Text(
                    'No tags found. Tap "+" to add one!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _allTags.length,
                  itemBuilder: (context, index) {
                    final tag = _allTags[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(tag.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showTagDialog(tagToEdit: tag), // 태그 수정
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteTag(tag.id), // 태그 삭제
                            ),
                          ],
                        ),
                        onTap: () => _showTagDialog(tagToEdit: tag), // 탭하여 수정
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTagDialog(), // 새 태그 추가
        child: const Icon(Icons.add),
      ),
    );
  }
}