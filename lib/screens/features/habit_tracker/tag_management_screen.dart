import 'package:flutter/material.dart';
import 'package:myme_app/database_helper.dart';
import 'package:myme_app/models/tag_model.dart';
import 'package:uuid/uuid.dart';

class TagManagementScreen extends StatefulWidget {
  final int userId;
  const TagManagementScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _TagManagementScreenState createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();
  List<Tag> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  Tag? _editingTag;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    final tags = await dbHelper.getAllTags(widget.userId);
    setState(() {
      _tags = tags;
    });
  }

  Future<void> _saveTag() async {
    final tagName = _tagController.text.trim();
    if (tagName.isEmpty) return;

    if (_editingTag != null) {
      // Update existing tag
      _editingTag!.name = tagName;
      _editingTag!.updatedAt = DateTime.now();
      await dbHelper.updateTag(_editingTag!);
      setState(() {
        _editingTag = null;
      });
    } else {
      // Add new tag
      final newTag = Tag(
        id: uuid.v4(),
        name: tagName,
        ownerId: widget.userId,
        createdBy: widget.userId,
        updatedBy: widget.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbHelper.insertTag(newTag);
    }
    _tagController.clear();
    _loadTags();
  }

  void _editTag(Tag tag) {
    setState(() {
      _editingTag = tag;
      _tagController.text = tag.name;
    });
  }

  Future<void> _deleteTag(String tagId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('태그 삭제'),
          content: const Text('이 태그를 정말 삭제하시겠습니까? 이 태그는 습관과의 연결에서만 제거되며, 습관 자체는 삭제되지 않습니다.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await dbHelper.deleteTag(tagId);
      _loadTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('태그 관리'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: _editingTag != null ? '태그 수정' : '새 태그 추가',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveTag,
                  child: Text(_editingTag != null ? '수정' : '추가'),
                ),
                if (_editingTag != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editingTag = null;
                        _tagController.clear();
                      });
                    },
                    child: const Text('취소'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _tags.isEmpty
                ? const Center(
                    child: Text('등록된 태그가 없습니다.'),
                  )
                : ListView.builder(
                    itemCount: _tags.length,
                    itemBuilder: (context, index) {
                      final tag = _tags[index];
                      return ListTile(
                        title: Text(tag.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editTag(tag),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteTag(tag.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
