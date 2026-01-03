import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/animated_gradient_button.dart';

class AddStudentScreen extends StatefulWidget {
  final String classId;

  const AddStudentScreen({super.key, required this.classId});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _addMultiple = false; // ⬅️ toggle to stay on screen

  CollectionReference get _students =>
      FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students');

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final roll = int.parse(_rollController.text.trim());

    setState(() => _saving = true);

    // Check for duplicate roll number
    final existing = await _students.where('rollNo', isEqualTo: roll).get();
    if (existing.docs.isNotEmpty) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Roll number already exists")),
      );
      return;
    }

    try {
      await _students.add({
        'name': name,
        'rollNo': roll,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Update totalStudents in class doc
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({'totalStudents': FieldValue.increment(1)});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _addMultiple
                ? "Student added! Add next student."
                : "Student added successfully",
          ),
        ),
      );

      if (_addMultiple) {
        // Clear the fields for next student
        _nameController.clear();
        _rollController.clear();
      } else {
        Navigator.pop(context, true); // close screen
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Student")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Student Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Student Name",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter student name" : null,
              ),
              const SizedBox(height: 12),

              // Roll Number
              TextFormField(
                controller: _rollController,
                decoration: const InputDecoration(
                  labelText: "Roll Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter roll number";
                  if (int.tryParse(val) == null) return "Enter valid number";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Toggle for adding multiple students
              // Toggle for adding multiple students (Right aligned)
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "Add multiple students",
      style: TextStyle(fontSize: 16),
    ),
    Switch(
      value: _addMultiple,
      onChanged: (v) => setState(() => _addMultiple = v),
    ),
  ],
),


              const SizedBox(height: 20),

              // Add Student Button
              AnimatedGradientButton(
                text: "Add Student",
                loading: _saving,
                onPressed: _saving ? null : _addStudent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
