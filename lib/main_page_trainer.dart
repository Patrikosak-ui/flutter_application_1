import 'package:find_trainer_v2/progress_client_trainer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_trainer.dart';
import 'requests_trainer.dart';
import 'trainer_stats.dart';
import 'food_trainer.dart'; // Import food_trainer.dart


class MainPageTrainer extends StatefulWidget {
  const MainPageTrainer({super.key});

  @override
  _MainPageTrainerState createState() => _MainPageTrainerState();
}

class _MainPageTrainerState extends State<MainPageTrainer> {
  // Funkce pro získání UID aktuálně přihlášeného trenéra
  String get trainerUid {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  // Funkce pro kontrolu žádostí se statusem 'pending' pro trenéra
  Stream<bool> _hasPendingRequests() {
    return FirebaseFirestore.instance
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .where('trainer_uid', isEqualTo: trainerUid) // Filtr pro konkrétního trenéra
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  // Funkce pro odstranění klienta
  Future<void> _deleteClient(String clientUid) async {
    try {
      await FirebaseFirestore.instance.collection('clients').doc(clientUid).delete();
      var requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('client_uid', isEqualTo: clientUid)
          .get();
      for (var doc in requestsSnapshot.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klient byl úspěšně odstraněn')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chyba při odstraňování klienta')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hlavní stránka trenéra',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade700, // Changed to a more prominent color
        elevation: 4, // Added elevation for better visibility
        automaticallyImplyLeading: false,
        actions: [
          StreamBuilder<bool>(
            stream: _hasPendingRequests(),
            builder: (context, snapshot) {
              bool hasPendingRequests = snapshot.data ?? false;
              return IconButton(
                icon: Stack(
                  children: [
                    Icon(Icons.mail, color: Colors.white),
                    if (hasPendingRequests)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestsTrainer(),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileTrainer(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 0, 0, 0), Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .where('trainer_uid', isEqualTo: trainerUid)
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Žádní přijatí klienti.'));
            }

            List<DocumentSnapshot> requests = snapshot.data!.docs;

            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                var request = requests[index];
                var clientUid = request['client_uid'];
                var clientName = request['client_name'] ?? 'Neznámé jméno';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(clientUid).get(),
                  builder: (context, clientSnapshot) {
                    if (clientSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!clientSnapshot.hasData || !clientSnapshot.data!.exists) {
                      return const Center(child: Text('Klient nenalezen.'));
                    }

                    var clientData = clientSnapshot.data!.data() as Map<String, dynamic>;
                    String name = clientData['name'] ?? 'Neznámé jméno';
                    String surname = clientData['surname'] ?? 'Neznámé příjmení';

                    return Card(
                      color: Colors.grey.shade900,
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(
                          '$name $surname',
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restaurant_menu, color: Colors.teal),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FoodTrainer(
                                      clientUid: clientUid,
                                      clientName: '$name $surname',
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'Jídelníček',
                            ),
                            IconButton(
                              icon: const Icon(Icons.fitness_center, color: Colors.teal),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrainerStats(
                                      clientUid: clientUid,
                                      clientName: '$name $surname',
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'Přidat trénink',
                            ),
                            IconButton(
                              icon: const Icon(Icons.show_chart, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrainerOverview(
                                      clientUid: clientUid,
                                      clientName: '$name $surname',
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'Progres',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Potvrzení odstranění'),
                                      content: const Text('Opravdu chcete odstranit tohoto klienta?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Zrušit'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _deleteClient(clientUid);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Odstranit'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
