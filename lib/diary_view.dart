import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'l10n.dart'; // path 패키지 import

class DiaryView extends StatelessWidget {
  final String content;
  final List<String> imagePaths; // DB에서 가져온 상대 경로
  final String appDocPath;       // 앱의 문서 디렉토리 절대 경로
  final VoidCallback onTap;

  const DiaryView({
    Key? key,
    required this.content,
    required this.imagePaths,
    required this.appDocPath,   // 생성자에 appDocPath 추가
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        child: (content.isEmpty && imagePaths.isEmpty)
            ? Center(
          child: Text(
            S.of(context).noDiary,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (content.isNotEmpty)
                Text(
                  content,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              if (content.isNotEmpty && imagePaths.isNotEmpty)
                const SizedBox(height: 24),
              if (imagePaths.isNotEmpty)
                Column(
                  children: imagePaths.map((relativePath) {
                    // ✅ 상대 경로를 절대 경로로 조합
                    final fullPath = p.join(appDocPath, relativePath);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(fullPath), // ✅ 조합된 전체 경로 사용
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // 이미지 로드 에러 발생 시 대체 위젯
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 150,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: Text(S.of(context).imageLoadError),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}