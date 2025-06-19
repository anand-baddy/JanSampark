import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../db/database_helper.dart';
import 'edit_record_screen.dart';
import '../tricolor_background.dart'; // Import if you use this for theme

class TodayFollowupsPage extends StatefulWidget {
  final VoidCallback? onClose;
  const TodayFollowupsPage({Key? key, this.onClose}) : super(key: key);

  @override
  State<TodayFollowupsPage> createState() => _TodayFollowupsPageState();
}

class _TodayFollowupsPageState extends State<TodayFollowupsPage> {
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;

  String? _selectedStatus;
  String? _requestorName;
  String? _requestedLocation;
  DateTime? _selectedFollowupDate;

  List<String> _statusList = ['New', 'In Progress', 'Pending External', 'Closed'];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    // Pass required argument if needed, e.g., DateTime.now()
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final records = await DatabaseHelper.instance.getTodayOpenFollowups(today);
    setState(() {
      _records = records;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _records.where((rec) {
        final matchesStatus = _selectedStatus == null || rec['status'] == _selectedStatus;
        final matchesRequestor = _requestorName == null || _requestorName!.isEmpty
            || (rec['requestor_name'] ?? '').toLowerCase().contains(_requestorName!.toLowerCase());
        final matchesLocation = _requestedLocation == null || _requestedLocation!.isEmpty
            || (rec['requestor_location'] ?? '').toLowerCase().contains(_requestedLocation!.toLowerCase());
        final matchesDate = _selectedFollowupDate == null
            || (rec['followup_date'] ?? '') == DateFormat('yyyy-MM-dd').format(_selectedFollowupDate!);
        return matchesStatus && matchesRequestor && matchesLocation && matchesDate;
      }).toList();
    });
  }

  Future<List<File>> _getImageFiles(String imagesStr) async {
    if (imagesStr.isEmpty) return [];
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'images'));
    final filenames = imagesStr.split(';').where((e) => e.isNotEmpty).toList();
    return filenames.map((name) => File(p.join(imagesDir.path, name))).toList();
  }

  Future<void> _deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record deleted')),
    );
    _loadRecords();
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            DropdownButton<String>(
              value: _selectedStatus,
              hint: const Text('Status'),
              items: [null, ..._statusList].map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status ?? 'All'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                  _applyFilters();
                });
              },
            ),
            SizedBox(
              width: 150,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Req Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  _requestorName = value;
                  _applyFilters();
                },
              ),
            ),
            SizedBox(
              width: 150,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Req Location',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  _requestedLocation = value;
                  _applyFilters();
                },
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedFollowupDate == null
                      ? 'Followup Date'
                      : DateFormat('yyyy-MM-dd').format(_selectedFollowupDate!),
                  style: const TextStyle(fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedFollowupDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedFollowupDate = picked;
                        _applyFilters();
                      });
                    }
                  },
                ),
                if (_selectedFollowupDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedFollowupDate = null;
                        _applyFilters();
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use TricolorBackground for consistent theme if used in your app
    return TricolorBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // For TricolorBackground
        appBar: AppBar(
          title: const Text("Today's Open Follow-ups"),
          //backgroundColor: const Color(0xFF0081FF), // Match your theme
          backgroundColor: const Color(0xFF0D47A1), // Match your theme
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              // anand onPressed: () => Navigator.of(context).pop(),
             onPressed: () {
               if (widget.onClose != null) widget.onClose!();
                 Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildFilters(),
                  Expanded(
                    child: _filteredRecords.isEmpty
                        ? const Center(child: Text('No records found.'))
                        : ListView.builder(
                            itemCount: _filteredRecords.length,
                            itemBuilder: (context, index) {
                              final rec = _filteredRecords[index];
                              // ... (rest of your record card/expansion logic as in RecordListTab)
                              // Copy your ExpansionTile code here
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: ExpansionTile(
                                  title: Text(
                                    '${rec['unique_id']} - ${rec['subject'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('Status: ${rec['status']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'Edit',
                                        onPressed: () async {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditRecordScreen(
                                                record: rec,
                                              ),
                                            ),
                                          ).then((result) {
                                            if (result == true) {
                                              _loadRecords();
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Delete',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Record'),
                                              content: const Text('Are you sure you want to delete this record?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text('Cancel')),
                                                TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text('Delete')),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await _deleteRecord(rec['id']);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Type: ${rec['type']}'),
                                          Text('Received Date: ${rec['recd_date']}'),
                                          Text('Requestor Name: ${rec['requestor_name']}'),
                                          Text('Requestor Location: ${rec['requestor_location']}'),
                                          Text('Forwarded Dept: ${rec['forwarded_dept'] ?? ''}'),
                                          Text('Forwarded Person: ${rec['forwarded_person'] ?? ''}'),
                                          Text('Expected Closure Date: ${rec['expected_closure_date'] ?? ''}'),
                                          Text('Response Sent Date: ${rec['response_sent_date'] ?? ''}'),
                                          Text('Actual Closure Date: ${rec['actual_closure_date'] ?? ''}'),
                                          Text('Remarks: ${rec['remarks'] ?? ''}'),
                                          Text('Followup Date: ${rec['followup_date'] ?? ''}'),
                                          const SizedBox(height: 8),
                                          const Text('Incoming Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          FutureBuilder<List<File>>(
                                            future: _getImageFiles(rec['incoming_images'] ?? ''),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                                              }
                                              final images = snapshot.data ?? [];
                                              if (images.isEmpty) return const Text('No images');
                                              return Wrap(
                                                children: images
                                                    .map((file) => GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (_) => Dialog(
                                                                child: Stack(
                                                                  children: [
                                                                    InteractiveViewer(
                                                                      child: Image.file(file),
                                                                    ),
                                                                    Positioned(
                                                                      top: 8,
                                                                      right: 8,
                                                                      child: IconButton(
                                                                        icon: const Icon(Icons.close, color: Colors.black),
                                                                        onPressed: () => Navigator.of(context).pop(),
                                                                        tooltip: 'Close',
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(4.0),
                                                            child: Image.file(file, width: 70, height: 70, fit: BoxFit.cover),
                                                          ),
                                                        ))
                                                    .toList(),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          const Text('Response Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          FutureBuilder<List<File>>(
                                            future: _getImageFiles(rec['response_images'] ?? ''),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                                              }
                                              final images = snapshot.data ?? [];
                                              if (images.isEmpty) return const Text('No images');
                                              return Wrap(
                                                children: images
                                                    .map((file) => GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (_) => Dialog(
                                                                child: Stack(
                                                                  children: [
                                                                    InteractiveViewer(
                                                                      child: Image.file(file),
                                                                    ),
                                                                    Positioned(
                                                                      top: 8,
                                                                      right: 8,
                                                                      child: IconButton(
                                                                        icon: const Icon(Icons.close, color: Colors.black),
                                                                        onPressed: () => Navigator.of(context).pop(),
                                                                        tooltip: 'Close',
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(4.0),
                                                            child: Image.file(file, width: 70, height: 70, fit: BoxFit.cover),
                                                          ),
                                                        ))
                                                    .toList(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

