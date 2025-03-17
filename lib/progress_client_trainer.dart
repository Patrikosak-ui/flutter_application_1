import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TrainerOverview extends StatefulWidget {
  final String clientUid;
  final String clientName;

  const TrainerOverview({super.key, required this.clientUid, required this.clientName});

  @override
  _TrainerOverviewState createState() => _TrainerOverviewState();
}

class _TrainerOverviewState extends State<TrainerOverview> {
  String selectedMuscleGroup = 'Vše';

  Stream<List<RecordData>> _streamProgress() {
    return FirebaseFirestore.instance
        .collection('progress')
        .where('clientUid', isEqualTo: widget.clientUid)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              // Use .data() safely
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return RecordData.fromMap(data);
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), // added iconTheme
        title: const Text(
          'Progres klienta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildMuscleGroupDropdown(),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<RecordData>>(
                  stream: _streamProgress(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Chyba: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Žádná data o progresu.'));
                    }
                    final data = snapshot.data!;
                    return Column(
                      children: [
                        _buildProgressChart(data),
                        const SizedBox(height: 16),
                        Expanded(child: _buildProgressList(data)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleGroupDropdown() {
    return StreamBuilder<List<RecordData>>(
      stream: _streamProgress(),
      builder: (context, snapshot) {
        final groups = snapshot.hasData
            ? snapshot.data!
                .map((r) => r.muscleGroup)
                .toSet()
                .toList()
            : <String>[];
        groups.insert(0, 'Vše');
        return DropdownButton<String>(
          value: selectedMuscleGroup,
          items: groups
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g, style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() {
              selectedMuscleGroup = val!;
            });
          },
          dropdownColor: Colors.grey.shade800,
        );
      },
    );
  }

// BEGIN GREEN HIGHLIGHT: Čárový graf zobrazující celkovou váhu cvičení podle data.
  Widget _buildProgressChart(List<RecordData> records) {
    final filtered = selectedMuscleGroup == 'Vše'
        ? records
        : records.where((r) => r.muscleGroup == selectedMuscleGroup).toList();
    final spots = filtered.map((record) {
      double totalWeight = record.exercises.fold(0.0, (prev, exercise) {
        return prev + exercise.series.fold(0.0, (prevSeries, series) => prevSeries + series.weight);
      });
      return FlSpot(record.date.millisecondsSinceEpoch.toDouble(), totalWeight);
    }).toList();
    double interval = 1;
    if (spots.length > 1) {
      interval = (spots.last.x - spots.first.x) / 4;
      if (interval == 0) interval = 1;
    }
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()} kg',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('dd.MM').format(date),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.white)),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: Colors.tealAccent,
              barWidth: 2,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
// END GREEN HIGHLIGHT.

  Widget _buildProgressList(List<RecordData> records) {
    final filtered = selectedMuscleGroup == 'Vše'
        ? records
        : records.where((r) => r.muscleGroup == selectedMuscleGroup).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final record = filtered[index];
        return ExpansionTile(
          title: Text(
            DateFormat('dd.MM.yyyy').format(record.date),
            style: const TextStyle(color: Colors.white),
          ),
          children: [
            ListTile(
              title: Text('Svalová skupina: ${record.muscleGroup}', style: const TextStyle(color: Colors.white)),
            ),
            ...record.exercises.map((exercise) {
              return ExpansionTile(
                title: Text('Cvičení: ${exercise.name}', style: const TextStyle(color: Colors.white)),
                children: exercise.series.map((s) {
                  return ListTile(
                    title: Text('Váha: ${s.weight} kg, Opak.: ${s.reps}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Pocit: ${s.feeling}', style: const TextStyle(color: Colors.white70)),
                  );
                }).toList(),
              );
            }).toList()
          ],
        );
      },
    );
  }
}

class RecordData {
  final DateTime date;
  final String muscleGroup;
  final List<Exercise> exercises;

  RecordData({
    required this.date,
    required this.muscleGroup,
    required this.exercises,
  });

  factory RecordData.fromMap(Map<String, dynamic> data) {
    try {
      return RecordData(
        date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
        muscleGroup: data['muscleGroup'] ?? 'Unknown',
        exercises: data['exercises'] != null
            ? (data['exercises'] as List<dynamic>)
                .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
                .toList()
            : [],
      );
    } catch (e) {
      throw Exception('Error parsing RecordData: $e');
    }
  }
}

class Exercise {
  final String name;
  final List<Series> series;

  Exercise({required this.name, required this.series});

  factory Exercise.fromMap(Map<String, dynamic> data) {
    return Exercise(
      name: data['exercise'] ?? 'Unnamed',
      series: data['series'] != null
          ? (data['series'] as List<dynamic>)
              .map((s) => Series.fromMap(s as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class Series {
  final double weight;
  final int reps;
  final double feeling;

  Series({required this.weight, required this.reps, required this.feeling});

  factory Series.fromMap(Map<String, dynamic> data) {
    return Series(
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      reps: data['reps'] ?? 0,
      feeling: (data['feeling'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


