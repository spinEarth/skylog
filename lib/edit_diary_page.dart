import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'l10n.dart';

class EditDiaryPage extends StatefulWidget {
  final DateTime selectedDate;
  final String? initialContent;
  final List<String>? initialImagePaths;

  const EditDiaryPage({
    Key? key,
    required this.selectedDate,
    this.initialContent,
    this.initialImagePaths,
  }) : super(key: key);

  @override
  State<EditDiaryPage> createState() => _EditDiaryPageState();
}

class _EditDiaryPageState extends State<EditDiaryPage> {
  late final TextEditingController _textController;
  List<String> _imagePaths = [];
  bool _isLoading = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialContent);
    _textController.selection = TextSelection.fromPosition(const TextPosition(offset: 0));
    _initImagePaths();

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  Future<void> _initImagePaths() async {
    if (widget.initialImagePaths == null) return;
    final docDir = await getApplicationDocumentsDirectory();
    setState(() {
      _imagePaths = widget.initialImagePaths!
          .map((relativePath) => p.join(docDir.path, relativePath))
          .toList();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isLoading) return;

    // ⭐️ 수정 1: 이미지 피커를 열기 전에 키보드를 명시적으로 내립니다.
    FocusScope.of(context).unfocus();

    try {
      setState(() {
        _isLoading = true;
      });

      final ImagePicker picker = ImagePicker();
      final List<XFile>? images = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images != null && images.isNotEmpty) {
        final Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();
        final String imagesDirPath = p.join(appDocumentsDir.path, 'images');
        final Directory imagesDir = Directory(imagesDirPath);

        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        List<String> newImagePaths = [];
        for (var image in images) {
          final String fileName = p.basename(image.path);
          final String savedImagePath = p.join(imagesDirPath, fileName);

          await image.saveTo(savedImagePath);
          newImagePaths.add(savedImagePath);
        }

        if (mounted) {
          setState(() {
            _imagePaths.addAll(newImagePaths);
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // ⭐️ 수정 2: 로딩(이미지 처리)이 끝나면 텍스트 필드에 포커스를 주어 키보드를 다시 올립니다.
        FocusScope.of(context).requestFocus(_focusNode);
      }
    }
  }

  void _deleteImage(int index) {
    final fileToDelete = File(_imagePaths[index]);
    if (fileToDelete.existsSync()) {
      fileToDelete.delete();
    }
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          DateFormat('yyyy.MM.dd').format(widget.selectedDate),
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final docDir = await getApplicationDocumentsDirectory();
              final relativePaths = _imagePaths.map((fullPath) {
                return p.relative(fullPath, from: docDir.path);
              }).toList();

              final result = {
                'content': _textController.text,
                'imagePaths': relativePaths,
              };
              Navigator.of(context).pop(result);
            },
          )
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.black54),
                onPressed: _pickImage,
              ),
              if (_imagePaths.isNotEmpty)
                Text(
                  '${_imagePaths.length}${S.of(context).photoCount}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: S.of(context).writeDiary,
                      border: InputBorder.none,
                    ),
                  ),
                  if (_imagePaths.isNotEmpty)
                    Column(
                      children: _imagePaths.asMap().entries.map((entry) {
                        int index = entry.key;
                        String path = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(path),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _deleteImage(index),
                                  child: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}