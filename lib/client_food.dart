import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientFood extends StatelessWidget {
  final String clientUid;
  final String trainerUid;

  const ClientFood({super.key, required this.clientUid, required this.trainerUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Jídelníček',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 0, 0, 0),
                  Colors.grey.shade800
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('foodPlans')
                  .where('clientUid', isEqualTo: clientUid)
                  .where('trainerUid', isEqualTo: trainerUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Žádný plán jídel nenalezen'));
                }
                var daysOfWeek = ['Pondělí', 'Úterý', 'Středa', 'Čtvrtek', 'Pátek', 'Sobota', 'Neděle'];
                var foodPlans = snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return {
                    'day': data['day'] ?? '',
                    'breakfast': data['breakfast'] ?? '',
                    'morningSnack': data['morningSnack'] ?? '',
                    'lunch': data['lunch'] ?? '',
                    'afternoonSnack': data['afternoonSnack'] ?? '',
                    'dinner': data['dinner'] ?? ''
                  };
                }).toList();

                foodPlans.sort((a, b) => daysOfWeek.indexOf(a['day']).compareTo(daysOfWeek.indexOf(b['day'])));

                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16.0),
                  children: foodPlans.map((plan) {
                    return Card(
                      color: Colors.grey.shade700,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Den: ${plan['day']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildFoodText('Snídaně', plan['breakfast']),
                            const SizedBox(height: 10),
                            _buildFoodText('Svačina dopoledne', plan['morningSnack']),
                            const SizedBox(height: 10),
                            _buildFoodText('Oběd', plan['lunch']),
                            const SizedBox(height: 10),
                            _buildFoodText('Svačina odpoledne', plan['afternoonSnack']),
                            const SizedBox(height: 10),
                            _buildFoodText('Večeře', plan['dinner']),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodText(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.tealAccent,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
