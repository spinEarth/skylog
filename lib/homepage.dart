// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:skylog/weather_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';
import 'edit_diary_page.dart';
import 'diary_view.dart';
import 'l10n.dart';
import 'location_service.dart';
import 'todolist_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final dbHelper = DatabaseHelper.instance;
  String _appDocumentsDirectoryPath = '';
  String _currentAddress = ""; // 화면 표시용 (저장 X)
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  int _selectedIndex = 0;

  String _diaryContent = '';
  List<String> _diaryImagePaths = [];
  List<DateTime> _diaryDates = [];
  List<Todo> _todos = [];
  List<DateTime> _todoDates = [];

  double? _lat;
  double? _lng;
  bool _isLocationLoading = false;

  final TextEditingController _todoController = TextEditingController();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initAppDirectory();
    _loadDiaryDates();
    _loadTodoDates();


    _initializeLocation();
    _initNotification();
  }


  Future<void> _initNotification() async {
    await _notificationService.init();
  }



  Future<void> _initializeLocation() async {
    setState(() => _isLocationLoading = true);

    // 시나리오 1: GPS 권한이 있는 경우 실시간 좌표 획득
    LocationPermission permission = await Geolocator.checkPermission();

    // ⭐️ 추가된 로직: 권한이 없다면(denied) 한 번 물어봅니다.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }


    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        await _saveAndSetLocation(position.latitude, position.longitude);
        return;
      } catch (e) {
        print("GPS 획득 실패: $e");
      }
    }

    // 시나리오 2: 권한 없거나 실패 시 SharedPreferences에서 좌표 불러오기
    final prefs = await SharedPreferences.getInstance();
    double? savedLat = prefs.getDouble('last_lat');
    double? savedLng = prefs.getDouble('last_lng');

    if (savedLat != null && savedLng != null) {
      setState(() {
        _lat = savedLat;
        _lng = savedLng;
        _isLocationLoading = false;
      });
      print("기기 저장 좌표 로드 완료: $_lat, $_lng");
      _updateWeather();
      // TODO: 여기서 일출/일몰 데이터 갱신 API 호출
    } else {
      // 시나리오 3: 저장된 좌표도 없는 경우 검색 다이얼로그
      setState(() => _isLocationLoading = false);
      _showLocationSearchDialog();
    }
  }

  // 2. 좌표를 저장하고 상태를 업데이트하는 함수
  Future<void> _saveAndSetLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', lat);
    await prefs.setDouble('last_lng', lng);

    setState(() {
      _lat = lat;
      _lng = lng;
      _isLocationLoading = false;
    });

    print("좌표 저장 및 설정 완료: $lat, $lng");
    // TODO: 여기서 일출/일몰 데이터 갱신 API 호출

    _updateWeather();
  }

  Map<String, dynamic>? _weeklyWeatherData;

  Future<void> _updateWeather() async {
    if (_lat == null || _lng == null) return;

    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
            '?latitude=$_lat'
            '&longitude=$_lng'
            '&hourly=temperature_2m,cloudcover,precipitation_probability,precipitation,weathercode,visibility'
            '&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min'
            '&timezone=auto'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ 1. 단순 출력 (길면 잘릴 수 있음)
        // print(data);

        // ✅ 2. 들여쓰기 포함 전체 출력 (추천)
        JsonEncoder encoder = const JsonEncoder.withIndent('  ');
        String prettyJson = encoder.convert(data);

        // developer.log를 사용하면 아무리 길어도 잘리지 않고 콘솔에 다 나옵니다.
        //developer.log("========= [API FULL DATA START] =========");
        //developer.log(prettyJson);
        //developer.log("========= [API FULL DATA END] ===========");
        String lang = Localizations.localeOf(context).languageCode;
        await _notificationService.scheduleWeatherNotifications(data, lang);
        print("7일치 날씨 맞춤 알림 예약 완료");

        setState(() {
          _weeklyWeatherData = data;
        });
      }



    } catch (e) {
      print("API 호출 에러: $e");
    }
  }


  void _showLocationSearchDialog() {
    final TextEditingController cityController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          // ⭐️ 1. 배경을 완전한 흰색으로 만들고 Material 3의 보라빛 틴트 효과 제거
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          // ⭐️ 2. 앱 디자인에 맞게 모서리를 둥글게 처리 (16 픽셀)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 12),
          title: Text(
              S.of(context).locationTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            textAlign: TextAlign.center, // 제목 중앙 정렬로 깔끔하게
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⭐️ 3. To-Do 입력창과 비슷한 스타일의 검색 텍스트 필드
                TextField(
                  controller: cityController,
                  cursorColor: Colors.blueAccent,
                  decoration: InputDecoration(
                    hintText: S.of(context).locationHint,
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    // 평상시 테두리 (연한 회색)
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    // 포커스 되었을 때 테두리 (앱 포인트 컬러)
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: Colors.grey.shade600),
                      onPressed: () async {
                        try {
                          final currentLocale = Localizations.localeOf(context).toString();

                          List<Location> locations = await locationFromAddress(
                            cityController.text,
                            localeIdentifier: currentLocale,
                          );
                          List<Map<String, dynamic>> tempResults = [];
                          for (var loc in locations) {
                            List<Placemark> marks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
                            if (marks.isNotEmpty) {
                              tempResults.add({'location': loc, 'address': marks.first});
                            }
                          }
                          setDialogState(() => searchResults = tempResults);
                        } catch (e) {
                          _showSnackBar(S.of(context).noResult);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // ⭐️ 4. 검색 결과 리스트 디자인 깔끔하게 다듬기
                if (searchResults.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final item = searchResults[index];
                        final Placemark addr = item['address'];
                        final Location loc = item['location'];
                        String title = "${addr.locality ?? addr.subAdministrativeArea ?? ''}, ${addr.country ?? ''}".trim();

                        // 앞의 불필요한 쉼표나 공백 제거 방어 로직
                        if (title.startsWith(', ')) title = title.substring(2);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on, color: Colors.blueAccent, size: 20),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                          onTap: () async {
                            await _saveAndSetLocation(loc.latitude, loc.longitude);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _initAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      _appDocumentsDirectoryPath = directory.path;
    });
    _loadDataForSelectedDate(_selectedDay!);
  }

  void _loadDiaryDates() async {
    final dates = await dbHelper.getAllDiaryDates();
    setState(() {
      _diaryDates = dates.map((dateStr) {
        final parts = dateStr.split('-');
        return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }).toList();
    });
  }

  void _loadTodoDates() async {
    final dates = await dbHelper.getAllTodoDates();
    setState(() {
      _todoDates = dates.map((dateStr) {
        final parts = dateStr.split('-');
        return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }).toList();
    });
  }






// 스낵바 유틸리티
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _loadDataForSelectedDate(DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final diary = await dbHelper.getDiary(dateString);
    final todos = await dbHelper.getTodos(dateString);
    setState(() {
      _diaryContent = diary?.content ?? '';
      _diaryImagePaths = diary?.imagePaths ?? [];
      _todos = todos;
      _selectedDay = date;
      _focusedDay = date;
    });
  }

  void _navigateToEditPage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditDiaryPage(
          selectedDate: _selectedDay!,
          initialContent: _diaryContent,
          initialImagePaths: _diaryImagePaths,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      Diary newDiary = Diary(
        date: dateString,
        content: result['content'],
        imagePaths: result['imagePaths'] as List<String>,
      );
      await dbHelper.insertOrUpdateDiary(newDiary);
      _loadDataForSelectedDate(_selectedDay!);
      _loadDiaryDates();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addTodo() async {
    final String task = _todoController.text;
    if (task.isNotEmpty) {
      final newTodo = Todo(
        task: task,
        date: DateFormat('yyyy-MM-dd').format(_selectedDay!),
      );
      await dbHelper.insertTodo(newTodo);
      _todoController.clear();
      FocusScope.of(context).unfocus();
      _loadDataForSelectedDate(_selectedDay!);
      _loadTodoDates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        // ✅ Drawer 열 때 키보드 내리는 기능 복구
        onDrawerChanged: (isOpened) {
          if (isOpened) {
            Future.delayed(Duration.zero, () {
              FocusScope.of(context).unfocus();
            });
          }
        },
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.location_on_outlined), // 아이콘을 위치 모양으로 바꾸면 더 직관적입니다.
            onPressed: () {
              FocusScope.of(context).unfocus(); // 키보드가 열려있다면 닫기
              _showLocationSearchDialog();      // 👈 Drawer 대신 다이얼로그 호출
            },
            tooltip: S.of(context).locationTitle, // 툴팁도 위치 관련으로 변경
          ),
          iconTheme: const IconThemeData(color: Colors.black54),
          title: Text(
              _selectedDay != null
                  ? DateFormat('yyyy.MM.dd', 'ko_KR').format(_selectedDay!)
                  : '',
              style: const TextStyle(color: Colors.black, fontSize: 16)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
               DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(S.of(context).menu, style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(S.of(context).settings),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(S.of(context).appInfo),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildTableCalendar()),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              if (_selectedIndex == 0) ...[
                buildTodoSliver(
                  context: context,
                  todos: _todos,
                  onTodoToggle: (todo) async {
                    setState(() {
                      //todo.isDone = !todo.isDone;
                    });
                    await dbHelper.updateTodo(todo);
                  },
                  onTodoDelete: (id) async {
                    await dbHelper.deleteTodo(id);
                    _loadDataForSelectedDate(_selectedDay!);
                    _loadTodoDates();
                  },
                ),
                buildTodoFooterSliver(
                  context: context,
                  controller: _todoController,
                  onAddTodo: _addTodo,
                ),
              ] else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: DiaryView(
                    content: _diaryContent,
                    imagePaths: _diaryImagePaths,
                    appDocPath: _appDocumentsDirectoryPath,
                    onTap: _navigateToEditPage,
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,    // ⭐️ 터치할 때 퍼지는 물결 효과를 투명하게
            highlightColor: Colors.transparent, // ⭐️ 터치하고 있을 때의 배경색을 투명하게
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.white,
            // type: BottomNavigationBarType.fixed, // 💡 (선택) 탭할 때 아이콘이 위아래로 움직이는 애니메이션도 끄고 싶다면 이 줄의 주석을 해제하세요.
            items:  <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.check_box_outlined),
                label: S.of(context).todo,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit),
                label: S.of(context).diary,
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blueAccent,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerDot({required Color color}) {
    return Container(
      width: 5.0,
      height: 5.0,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTableCalendar() {
    final String currentLocale = Localizations.localeOf(context).languageCode;
    return Container(
      color: Colors.white,
      child: TableCalendar(
        locale: currentLocale,
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2050, 12, 31),
        daysOfWeekHeight: 40.0,
        focusedDay: _focusedDay,
        availableGestures: AvailableGestures.horizontalSwipe,
        eventLoader: (day) {
          final hasDiary = _diaryDates.any((diaryDate) => isSameDay(diaryDate, day));
          final hasTodo = _todoDates.any((todoDate) => isSameDay(todoDate, day));
          if (hasDiary || hasTodo) {
            return [' '];
          }
          return [];
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          leftChevronVisible: false,
          rightChevronVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          headerTitleBuilder: (context, day) => Container(),
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            final hasTodo = _todoDates.any((todoDate) => isSameDay(todoDate, date));
            final hasDiary = _diaryDates.any((diaryDate) => isSameDay(diaryDate, date));
            final todoColor = Colors.amberAccent;
            final diaryColor = Colors.greenAccent;
            return Positioned(
              bottom: 12,
              right: 0,
              left: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasTodo) _buildMarkerDot(color: todoColor),
                  if (hasTodo && hasDiary) const SizedBox(width: 3),
                  if (hasDiary) _buildMarkerDot(color: diaryColor),
                ],
              ),
            );
          },
          selectedBuilder: (context, date, events) {
            return Center(
              child: Container(
                width: 38.0, height: 38.0,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          FocusScope.of(context).unfocus();
          if (!isSameDay(_selectedDay, selectedDay)) {
            _loadDataForSelectedDate(selectedDay);
          }
        },
        onPageChanged: (focusedDay) {
          final int oldDay = _selectedDay!.day;
          final int year = focusedDay.year;
          final int month = focusedDay.month;
          final int daysInNewMonth = DateTime.utc(year, month + 1, 0).day;
          final int newDay = oldDay > daysInNewMonth ? daysInNewMonth : oldDay;
          final newSelectedDay = DateTime.utc(year, month, newDay);
          _loadDataForSelectedDate(newSelectedDay);
        },
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: Colors.deepOrangeAccent,
          ),
        ),
      ),
    );
  }
}