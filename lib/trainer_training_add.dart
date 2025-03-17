import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerTrainingAdd extends StatefulWidget {
  final String clientUid;
  final String clientName;

  const TrainerTrainingAdd({super.key, required this.clientUid, required this.clientName});

  @override
  _TrainerTrainingAddState createState() => _TrainerTrainingAddState();
}

class _TrainerTrainingAddState extends State<TrainerTrainingAdd> {
  final _formKey = GlobalKey<FormState>();
  final _trainingDescriptionController = TextEditingController();
  DateTime trainingDate = DateTime.now();

  Future<void> _submitNewTrainingPlan() async {
    User? trainer = FirebaseAuth.instance.currentUser;
    if (trainer == null) return;
    // Retrieve trainer's full name from "users" collection
    DocumentSnapshot trainerDoc = await FirebaseFirestore.instance.collection('users').doc(trainer.uid).get();
    String trainerName = 'Neznámý trenér';
    if (trainerDoc.exists) {
      var data = trainerDoc.data() as Map<String, dynamic>;
      trainerName = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
      if (trainerName.isEmpty) trainerName = 'Neznámý trenér';
    }

    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('training_plans').add({
        'client_uid': widget.clientUid,
        'trainerUid': trainer.uid,
        'name_trainer': trainerName, // Save trainer's name in column name_trainer
        'scheduled_date_time': Timestamp.fromDate(trainingDate),
        'description': _trainingDescriptionController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trénink byl úspěšně přidán')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Přidat trénink pro ${widget.clientName}'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _trainingDescriptionController,
                decoration: const InputDecoration(labelText: 'Popis tréninku'),
                validator: (value) => (value == null || value.isEmpty) ? 'Zadejte popis' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitNewTrainingPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                ),
                child: const Text(
                  'Přidat trénink',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
