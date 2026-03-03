import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'l10n.dart'; // Todo 클래스를 사용하기 위해 import

// HomePage에서만 사용되므로 private으로 선언합니다.

// 이 위젯들은 HomePage의 상태와 함수를 직접 전달받아 UI만 그립니다.

/// To-Do 목록을 표시하는 SliverList 위젯을 생성합니다.

Widget buildTodoSliver({
  required BuildContext context,
  required List<Todo> todos,
  required Function(Todo) onTodoToggle,
  required Function(int) onTodoDelete,
}) {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
          (context, index) {
        final todo = todos[index];

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: ListTile(
            leading: Checkbox(
              value: todo.isDone,
              onChanged: (bool? value) {
// HomePage의 로직을 그대로 호출

                onTodoToggle(todo..isDone = value!);
              },
              activeColor: Colors.grey.shade700,
              shape: const CircleBorder(),
            ),
            title: Text(
              todo.task,
              style: TextStyle(
                fontSize: 16,
                decoration: todo.isDone ? TextDecoration.lineThrough : null,
                color: todo.isDone ? Colors.grey : Colors.black87,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {
// HomePage의 로직을 그대로 호출

                onTodoDelete(todo.id!);
              },
            ),
          ),
        );
      },
      childCount: todos.length,
    ),
  );
}

/// '할 일 추가' 입력 필드를 표시하는 SliverToBoxAdapter 위젯을 생성합니다.

// todolist_view.dart (또는 home_page.dart 안의 buildTodoFooterSliver 함수)

Widget buildTodoFooterSliver({
  required BuildContext context,
  required TextEditingController controller,
  required VoidCallback onAddTodo,
}) {
  return SliverToBoxAdapter(
// Card와 ListTile 대신 Padding과 Container를 사용해 유연성을 높입니다.

    child: Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.circle_outlined, color: Colors.grey),

            const SizedBox(width: 12),

// Expanded를 사용해 TextField가 남은 공간을 모두 차지하도록 합니다.

            Expanded(
              child: TextField(
                controller: controller,

// ✅ 이 부분이 핵심입니다.

// maxLines를 null로 설정해 여러 줄 입력이 가능하게 합니다.

                maxLines: null,

                keyboardType: TextInputType.multiline,

                decoration: InputDecoration(
                  hintText: S.of(context).todoHint,
                  border: InputBorder.none,
                ),

// 엔터 키(줄바꿈) 대신 '완료' 버튼을 누를 때만 추가되도록 합니다.

                onSubmitted: (_) => onAddTodo(),
              ),
            ),

            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.grey.shade600),
              onPressed: onAddTodo,
            ),
          ],
        ),
      ),
    ),
  );
}