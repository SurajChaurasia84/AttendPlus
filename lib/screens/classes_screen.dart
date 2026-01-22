import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'class_detail_screen.dart';
import 'attendance_screen.dart';
import 'add_class_screen.dart';

class ClassesScreen extends StatefulWidget {
  final bool fromAttendance;

  const ClassesScreen({super.key, this.fromAttendance = false});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final CollectionReference _classesCollection =
      FirebaseFirestore.instance.collection('classes');

  final User? _user = FirebaseAuth.instance.currentUser;

  /// helper to sort favorites on top
  List<QueryDocumentSnapshot> _sortDocs(List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      bool aFav = a.data() is Map<String, dynamic> &&
              (a.data() as Map<String, dynamic>).containsKey('isFavorite')
          ? (a.data() as Map<String, dynamic>)['isFavorite'] as bool
          : false;
      bool bFav = b.data() is Map<String, dynamic> &&
              (b.data() as Map<String, dynamic>).containsKey('isFavorite')
          ? (b.data() as Map<String, dynamic>)['isFavorite'] as bool
          : false;

      if (aFav && !bFav) return -1;
      if (!aFav && bFav) return 1;

      Timestamp aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
      Timestamp bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
      return bTime.compareTo(aTime);
    });
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fromAttendance ? 'Select Class' : 'Classes'),
      ),

      /// 📋 CLASSES LIST (AUTO UPDATE)
      body: StreamBuilder<QuerySnapshot>(
        stream: _classesCollection
            .where('userId', isEqualTo: _user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = _sortDocs(snapshot.data!.docs);

          if (docs.isEmpty) {
            return const Center(child: Text('No classes yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final classId = doc.id;
              final className = data['name'] ?? '';
              final subjectName = data['subjectName'] ?? '';
              final isFav = data['isFavorite'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 16, right: 4),
                  leading: const Icon(Icons.class_),
                  title: Text(
                    className,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  subtitle: StreamBuilder<QuerySnapshot>(
                    stream: _classesCollection
                        .doc(classId)
                        .collection('students')
                        .snapshots(),
                    builder: (_, snap) {
                      if (!snap.hasData) return const SizedBox();
                      final totalStudents = snap.data!.docs.length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subjectName.isNotEmpty)
                            Text(
                              subjectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.group, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '$totalStudents Students',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  trailing: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () async {
                      await _classesCollection.doc(classId).update({
                        'isFavorite': !isFav,
                      });
                    },
                  ),
                  onTap: () {
                    if (widget.fromAttendance) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceScreen(
                            classId: classId,
                            className: className,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassDetailScreen(
                            classId: classId,
                            subjectName: subjectName,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),

      /// ➕ ADD CLASS
      floatingActionButton: widget.fromAttendance
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddClassScreen()),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
