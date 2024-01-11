import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TimetablePage(),
      title: 'CU-Manger',
    );
  }
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class _TimetablePageState extends State<TimetablePage> {
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();

    var initializationSettingsAndroid =
    const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    readJson();
  }

  Future<void> readJson() async {
    final String response = await rootBundle.loadString('courses.json');
    final data = await json.decode(response);
    setState(() {
      for (var courseData in data['courses']) {
        _courses.add(Course(
          courseName: courseData['course_name'],
          courseCode: courseData['course_code'],
          instructorName: courseData['instructor'],
          roomNumber: courseData['location'],
          time: courseData['time'],
          days: List<String>.from(courseData['days']),
        ));
      }
    });
  }

  List<String> instructors = [
    'All',
    'Dr. Firuz',
    'Dr. Tamer',
    'Dr. Leila',
  ];

  List<String> days = [
    'All',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  void _showCourseDetails(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(course.courseName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Course Code: ${course.courseCode}'),
                const SizedBox(height: 10),
                Text('Instructor: ${course.instructorName}'),
                const SizedBox(height: 10),
                Text('Room Number: ${course.roomNumber}'),
                const SizedBox(height: 10),
                Text('Time: ${course.time}'),
                const SizedBox(height: 10),
                Text('Days: ${course.days.join(", ")}'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(

                shadowColor: Colors.yellow,
                primary: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                var timeParts = course.time.split(':');
                var hour = int.parse(timeParts[0]);
                var minute = int.parse(timeParts[1].substring(0, 2));
                var amOrPm = timeParts[1].substring(2);

                if (amOrPm == 'pm') {
                  hour += 12;
                }

                var startDateTime = DateTime.now()
                    .add(Duration(days: course.days.indexOf(selectedDay)))
                    .add(Duration(hours: hour, minutes: minute))
                    .subtract(Duration(minutes: 15));

                var androidPlatformChannelSpecifics =
                const AndroidNotificationDetails(
                  'channel id',
                  'channel name',
                  'channel description',
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'ticker',
                );
                var iOSPlatformChannelSpecifics = IOSNotificationDetails();
                var platformChannelSpecifics = NotificationDetails(
                    android: androidPlatformChannelSpecifics,
                    iOS: iOSPlatformChannelSpecifics);

                await flutterLocalNotificationsPlugin.zonedSchedule(
                    0,
                    'Class Reminder',
                    'Your ${course.courseName} class starts in 15 minutes!',
                    tz.TZDateTime.from(startDateTime, tz.local),
                    platformChannelSpecifics,
                    androidAllowWhileIdle: true,
                    uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime);

                Navigator.of(context).pop();
              },
              child: const Text('Set Notification'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    TextEditingController courseNameController = TextEditingController();
    TextEditingController courseCodeController = TextEditingController();
    TextEditingController instructorNameController = TextEditingController();
    TextEditingController roomNumberController = TextEditingController();
    TextEditingController timeController = TextEditingController();
    List<String> days = ['M', 'T', 'W', 'Th', 'F'];
    List<String> selectedDays = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                ),
              ),
              TextField(
                controller: courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                ),
              ),
              TextField(
                controller: instructorNameController,
                decoration: const InputDecoration(
                  labelText: 'Instructor Name',
                ),
              ),
              TextField(
                controller: roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                ),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                ),
              ),
              const SizedBox(height: 20),
              const Text('Days'),
              Wrap(
                spacing: 10,
                children: days.map((String day) {
                  return FilterChip(
                    label: Text(day),
                    selected: selectedDays.contains(day),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Course newCourse = Course(
                  courseName: courseNameController.text,
                  courseCode: courseCodeController.text,
                  instructorName: instructorNameController.text,
                  roomNumber: roomNumberController.text,
                  time: timeController.text,
                  days: selectedDays,
                );

                setState(() {
                  _courses.add(newCourse);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String selectedInstructor = 'All';
  String selectedDay = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('CU-Manger'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildTimetable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCourseDialog(context);
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text('Instructor: '),
          DropdownButton<String>(
            value: selectedInstructor,
            onChanged: (value) {
              setState(() {
                selectedInstructor = value!;
              });
            },
            items: instructors
                .map((instructor) => DropdownMenuItem<String>(
              value: instructor,
              child: Text(instructor),
            ))
                .toList(),
          ),
          const SizedBox(width: 10),
          const Text('Day: '),
          DropdownButton<String>(
            value: selectedDay,
            onChanged: (value) {
              setState(() {
                selectedDay = value!;
              });
            },
            items: days
                .map((day) => DropdownMenuItem<String>(
              value: day,
              child: Text(day),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  final Map<String, String> _notesMap = {};

  Widget _buildTimetable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Course')),
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Instructor')),
            DataColumn(label: Text('Room')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Days')),
          ],
          rows: _courses
              .where((course) =>
          selectedInstructor == 'All' ||
              course.instructorName == selectedInstructor)
              .where((course) =>
          selectedDay == 'All' || course.days.contains(selectedDay))
              .map((course) => DataRow(
            onLongPress: () {
              final notesController = TextEditingController(
                  text: _notesMap[course
                      .courseName]); // set the text controller to the notes value
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Note'),
                  content: TextField(
                    controller: notesController,
                    obscureText: false,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Notes',
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        String notes = notesController.text;
                        _notesMap[course.courseName] = notes;
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            cells: [
              DataCell(GestureDetector(
                child: Text(course.courseName),
                onTap: () {
                  _showCourseDetails(context, course);
                },
              )),
              DataCell(
                GestureDetector(
                  child: Text(course.courseCode),
                  onTap: () {
                    _showCourseDetails(context, course);
                  },
                ),
              ),
              DataCell(
                GestureDetector(
                  child: Text(course.instructorName),
                  onTap: () {
                    _showCourseDetails(context, course);
                  },
                ),
              ),
              DataCell(
                GestureDetector(
                  child: Text(course.roomNumber),
                  onTap: () {
                    _showCourseDetails(context, course);
                  },
                ),
              ),
              DataCell(
                GestureDetector(
                  child: Text(course.time),
                  onTap: () {
                    _showCourseDetails(context, course);
                  },
                ),
              ),
              DataCell(
                GestureDetector(
                  child: Text(course.days.join(', ')),
                  onTap: () {
                    _showCourseDetails(context, course);
                  },
                ),
              ),
            ],
          ))
              .toList(),
        ),
      ),
    );
  }
}

class Course {
  final String courseName;
  final String courseCode;
  final String instructorName;
  final String roomNumber;
  final String time;
  final List<String> days;

  Course({
    required this.courseName,
    required this.courseCode,
    required this.instructorName,
    required this.roomNumber,
    required this.time,
    required this.days,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseName: json['courseName'],
      courseCode: json['courseCode'],
      instructorName: json['instructorName'],
      roomNumber: json['roomNumber'],
      time: json['time'],
      days: List<String>.from(json['days']),
    );
  }
}