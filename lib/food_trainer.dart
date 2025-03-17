import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'trainer_food_add.dart';

class FoodTrainer extends StatelessWidget {
  final String clientUid;
  final String clientName;

  const FoodTrainer({
    super.key,
    required this.clientUid,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String trainerUid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Jídelníček pro $clientName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // updated style
        ),
        backgroundColor: Colors.teal.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainerFoodAdd(clientUid: clientUid, clientName: clientName),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
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

              // Sort the documents by day of the week
              List<QueryDocumentSnapshot> sortedDocs = snapshot.data!.docs;
              sortedDocs.sort((a, b) {
                List<String> daysOfWeek = ['Pondělí', 'Úterý', 'Středa', 'Čtvrtek', 'Pátek', 'Sobota', 'Neděle'];
                return daysOfWeek.indexOf(a['day']).compareTo(daysOfWeek.indexOf(b['day']));
              });

              return SingleChildScrollView(
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  children: sortedDocs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.grey.shade700,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Den: ${data['day']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildFoodText('Snídaně', data['breakfast']),
                            const SizedBox(height: 10),
                            _buildFoodText('Svačina dopoledne', data['morningSnack']),
                            const SizedBox(height: 10),
                            _buildFoodText('Oběd', data['lunch']),
                            const SizedBox(height: 10),
                            _buildFoodText('Svačina odpoledne', data['afternoonSnack']),
                            const SizedBox(height: 10),
                            _buildFoodText('Večeře', data['dinner']),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
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
