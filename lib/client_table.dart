import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Import intl package for DateFormat
import 'main_page_client.dart'; // Import main_page_client.dart for navigation

class ClientTable extends StatefulWidget {
  final String clientUid; // Add clientUid parameter

  const ClientTable({ // Add constructor with clientUid
    super.key,
    required this.clientUid,
  });

  @override
  _ClientTableState createState() => _ClientTableState();
}

class _ClientTableState extends State<ClientTable> {
  // ...existing state variables...
  Map<DateTime, List<Map<String, dynamic>>> _trainingPlans = {};
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _fetchTrainingPlans(); // Fetch trainings on initialization
  }

  Future<void> _fetchTrainingPlans() async {
    String currentClientUid = widget.clientUid; // Use widget.clientUid
    final trainingsSnapshot = await FirebaseFirestore.instance
        .collection('training_plans')
        .where('client_uid', isEqualTo: currentClientUid)
        .get();

    Map<DateTime, List<Map<String, dynamic>>> trainings = {};

    for (var doc in trainingsSnapshot.docs) {
      Timestamp timestamp = doc['scheduled_date_time'];
      DateTime date = timestamp.toDate();
      DateTime day = DateTime(date.year, date.month, date.day);
      if (!trainings.containsKey(day)) {
        trainings[day] = [];
      }
      trainings[day]?.add(doc.data());
    }

    setState(() {
      _trainingPlans = trainings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal.shade700, // Match AppBar color with client_progress.dart
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPageClient()),
            );
          },
        ),
        title: const Text(
          'Kalendář Klienta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // ...existing code...
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 0, 0, 0), // Match gradient start color
              Colors.grey.shade800
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20), // Added border radius
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[850]!.withOpacity(0.85), // Match container color
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20.0),
              child: TableCalendar(
                locale: 'cs_CZ', // added locale for Czech language
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _selectedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                eventLoader: (day) {
                  return _trainingPlans[DateTime(day.year, day.month, day.day)] ?? [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                  });
                  // Details are shown below; no dialog is presented.
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.orangeAccent, // Consistent today color
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.transparent, // transparent fill
                    border: Border.fromBorderSide(const BorderSide(color: Colors.tealAccent, width: 2)),
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.tealAccent),
                  defaultTextStyle: TextStyle(color: Colors.white),
                  holidayTextStyle: TextStyle(color: Colors.redAccent),
                ),
                headerStyle: const HeaderStyle(
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.white70),
                  weekendStyle: TextStyle(color: Colors.orangeAccent),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox();
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Training Information Container
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.grey[850], // Match container color
                borderRadius: BorderRadius.circular(10),
              ),
              child: _trainingPlans[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tréninky na tento den:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: _trainingPlans[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]!.map((training) {
                            Timestamp? timestamp = training['scheduled_date_time'];
                            if (timestamp == null) {
                              return const SizedBox.shrink(); // Skip if no timestamp
                            }
                            DateTime scheduledTime = timestamp.toDate();

                            String clientName = training['client_name'] ?? 'Neznámý klient';

                            return ExpansionTile(
                              title: Text(
                                clientName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Description Row
                                      Row(
                                        children: [
                                          const Icon(Icons.description, color: Colors.tealAccent, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Popis: ${training['description'] ?? 'Bez popisu'}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Exercise Type Row
                                      Row(
                                        children: [
                                          const Icon(Icons.fitness_center, color: Colors.tealAccent, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Typ cvičení: ${training['exercise_type'] ?? 'N/A'}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  : const Text(
                      'Žádné tréninky pro tento den.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
            ),

            const SizedBox(height: 20),

            // ...existing code...
          ],
        ),
      ),
    );
  }

  // ...existing methods...
}
