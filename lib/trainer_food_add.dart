import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrainerFoodAdd extends StatefulWidget {
  final String clientUid;
  final String clientName;

  const TrainerFoodAdd({
    super.key,
    required this.clientUid,
    required this.clientName,
  });

  @override
  _TrainerFoodAddState createState() => _TrainerFoodAddState();
}

class _TrainerFoodAddState extends State<TrainerFoodAdd> {
  final _formKey = GlobalKey<FormState>();
  final _breakfastController = TextEditingController();
  final _morningSnackController = TextEditingController();
  final _lunchController = TextEditingController();
  final _afternoonSnackController = TextEditingController();
  final _dinnerController = TextEditingController();
  String _selectedDay = 'Pondělí';

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String trainerUid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Přidat Jídelníček',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // updated style
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
                  const Color.fromARGB(255, 45, 45, 45),
                  Colors.grey.shade800
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedDay,
                    items: ['Pondělí', 'Úterý', 'Středa', 'Čtvrtek', 'Pátek', 'Sobota', 'Neděle']
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text(day),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDay = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Den',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    dropdownColor: Colors.grey.shade800,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _buildTextFormField(_breakfastController, 'Snídaně'),
                  const SizedBox(height: 10),
                  _buildTextFormField(_morningSnackController, 'Svačina dopoledne'),
                  const SizedBox(height: 10),
                  _buildTextFormField(_lunchController, 'Oběd'),
                  const SizedBox(height: 10),
                  _buildTextFormField(_afternoonSnackController, 'Svačina odpoledne'),
                  const SizedBox(height: 10),
                  _buildTextFormField(_dinnerController, 'Večeře'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final querySnapshot = await FirebaseFirestore.instance
                            .collection('foodPlans')
                            .where('clientUid', isEqualTo: widget.clientUid)
                            .where('day', isEqualTo: _selectedDay)
                            .where('trainerUid', isEqualTo: trainerUid)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {
                          // Update existing document
                          final docId = querySnapshot.docs.first.id;
                          await FirebaseFirestore.instance
                              .collection('foodPlans')
                              .doc(docId)
                              .update({
                            'breakfast': _breakfastController.text,
                            'morningSnack': _morningSnackController.text,
                            'lunch': _lunchController.text,
                            'afternoonSnack': _afternoonSnackController.text,
                            'dinner': _dinnerController.text,
                          });
                        } else {
                          // Add new document
                          await FirebaseFirestore.instance
                              .collection('foodPlans')
                              .add({
                            'clientUid': widget.clientUid,
                            'trainerUid': trainerUid,
                            'day': _selectedDay,
                            'breakfast': _breakfastController.text,
                            'morningSnack': _morningSnackController.text,
                            'lunch': _lunchController.text,
                            'afternoonSnack': _afternoonSnackController.text,
                            'dinner': _dinnerController.text,
                          });
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plán jídel uložen')),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Uložit plán jídel',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Prosím zadejte $label';
        }
        return null;
      },
    );
  }
}
