import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        print('Notification payload: ${response.payload}');
      }
    },
  );

  // Initialize timezone
  tz.initializeTimeZones();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TaskListPage(),
    );
  }
}

const Color primaryColor = Color.fromARGB(255, 20, 26, 199);
const Color taskColor = Color.fromRGBO(239, 192, 39, 1);
const Color defaultTaskColor = Colors.blue;

class TaskListPage extends StatefulWidget {
  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final List<Map<String, dynamic>> tasks = [
    {
      "title": "Learn Flutter",
      "description": "We must follow learn flutter to improve ourselves",
      "startTime": TimeOfDay(hour: 9, minute: 7),
      "endTime": TimeOfDay(hour: 9, minute: 59),
      "color": defaultTaskColor,
      "date": DateTime.now(),
    },
  ];

  DateTime selectedDate = DateTime.now();

  void addOrUpdateTask(Map<String, dynamic> newTask, [int? index]) {
    setState(() {
      if (index != null) {
        tasks[index] = newTask;
      } else {
        tasks.add(newTask);
      }
    });
    scheduleNotification(newTask); // Schedule notification for the task
  }

  void scheduleNotification(Map<String, dynamic> task) async {
    final scheduledDate = DateTime(
      task['date'].year,
      task['date'].month,
      task['date'].day,
      task['startTime'].hour,
      task['startTime'].minute,
    );

    final tz.TZDateTime tzScheduledDate =
        tz.TZDateTime.from(scheduledDate, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Notification channel for tasks',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        'Description: ${task["description"]}',
        contentTitle: task["title"],
        summaryText: 'Task Reminder',
      ),
      color: Colors.blue,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Task Reminder',
      'Title: ${task["title"]}\nDescription: ${task["description"]}\nDate: ${DateFormat.jm().format(scheduledDate)}',
      tzScheduledDate,
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exact,
    );
  }

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Icon(Icons.menu, color: Colors.black),
        actions: [
          CircleAvatar(
            backgroundImage:
                AssetImage('assets/profile.jpg'), // Replace with valid asset
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(),
          _buildDateSelector(),
          _buildTodayHeader(context),
          Expanded(
            child: ListView.separated(
              itemCount: tasks
                  .where((task) => isSameDate(task["date"], selectedDate))
                  .length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final filteredTasks = tasks
                    .where((task) => isSameDate(task["date"], selectedDate))
                    .toList();
                final task = filteredTasks[index];
                return _buildTaskCard(task, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        DateFormat.yMMMMd().format(DateTime.now()),
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 90,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final currentDate = DateTime.now().add(Duration(days: index - 2));
          final isToday = isSameDate(currentDate, DateTime.now());
          final isSelected = isSameDate(currentDate, selectedDate);

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = currentDate;
              });
            },
            child: Container(
              width: 70,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : isToday
                        ? const Color.fromARGB(255, 234, 23, 142)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(currentDate),
                    style: TextStyle(
                      color:
                          isSelected || isToday ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "${currentDate.day}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected || isToday ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Tasks for ${DateFormat.MMMd().format(selectedDate)}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTaskPage(
                    onTaskAdded: addOrUpdateTask,
                    selectedDate: selectedDate,
                    existingTask: {},
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 229, 202, 30)),
            child: Text("+ Add Task"),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: task["color"],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task["title"],
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 5),
          Text(task["description"],
              style: TextStyle(fontSize: 14, color: Colors.white70)),
          SizedBox(height: 5),
          Text(
              "Time: ${task["startTime"].format(context)} - ${task["endTime"].format(context)}",
              style: TextStyle(fontSize: 14, color: Colors.white70)),
          SizedBox(height: 5),
          Text("Date: ${DateFormat.yMMMd().format(task["date"])}",
              style: TextStyle(fontSize: 14, color: Colors.white70)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white70),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTaskPage(
                        onTaskAdded: (updatedTask) {
                          addOrUpdateTask(updatedTask, index);
                        },
                        selectedDate: task["date"],
                        existingTask: task,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteTask(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onTaskAdded;
  final DateTime selectedDate;
  final Map<String, dynamic> existingTask;

  AddTaskPage({
    required this.onTaskAdded,
    required this.selectedDate,
    required this.existingTask,
  });

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late DateTime _selectedDate;
  Color _taskColor = defaultTaskColor;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingTask["title"] ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingTask["description"] ?? '');
    _startTime =
        widget.existingTask["startTime"] ?? TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.existingTask["endTime"] ?? TimeOfDay(hour: 10, minute: 0);
    _selectedDate = widget.existingTask["date"] ?? widget.selectedDate;
    _taskColor = widget.existingTask["color"] ?? defaultTaskColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask.isEmpty ? "Add Task" : "Edit Task"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Task Title"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a task title.";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Task Description",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimePicker(
                      context: context,
                      label: "Start Time",
                      initialTime: _startTime,
                      onTimePicked: (time) => setState(() {
                            _startTime = time;
                          })),
                  _buildTimePicker(
                      context: context,
                      label: "End Time",
                      initialTime: _endTime,
                      onTimePicked: (time) => setState(() {
                            _endTime = time;
                          })),
                ],
              ),
              SizedBox(height: 20),
              Text(
                "Select Task Date:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              TextButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                child: Text(DateFormat.yMMMd().format(_selectedDate)),
              ),
              SizedBox(height: 20),
              Text(
                "Select Task Color:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  _buildColorOption(Colors.blue),
                  _buildColorOption(Colors.orange),
                  _buildColorOption(Colors.green),
                  _buildColorOption(Colors.red),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newTask = {
                      "title": _titleController.text,
                      "description": _descriptionController.text,
                      "startTime": _startTime,
                      "endTime": _endTime,
                      "color": _taskColor,
                      "date": _selectedDate,
                    };
                    widget.onTaskAdded(newTask);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(243, 200, 45, 1)),
                child: Text("Save Task"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required BuildContext context,
    required String label,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onTimePicked,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            if (pickedTime != null) {
              onTimePicked(pickedTime);
            }
          },
          child: Text(initialTime.format(context)),
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _taskColor = color;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _taskColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
