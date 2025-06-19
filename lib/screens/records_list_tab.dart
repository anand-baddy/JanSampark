import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../db/database_helper.dart';
import 'edit_record_screen.dart';

class RecordListTab extends StatefulWidget {
  final VoidCallback? onRecordAdded;
  const RecordListTab({Key? key, this.onRecordAdded}) : super(key: key);

  @override
  State<RecordListTab> createState() => _RecordListTabState();
}

class _RecordListTabState extends State<RecordListTab> {
  late Future<List<Record>> _futureRecords; // anand

  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;

  // Filter state
  String? _selectedStatus;
  String? _requestorName;
  String? _requestedLocation;
  DateTime? _selectedFollowupDate;

  // For dropdown options
  List<String> _statusList = ['New', 'In Progress', 'Pending External','Closed'];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }


  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await DatabaseHelper.instance.getAllRecords();
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
    if (widget.onRecordAdded != null) {
      widget.onRecordAdded!();
    }
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
            // Status Dropdown
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
            // Requestor Name
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
            // Requested Location
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
            // Followup Date Picker
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildRefreshButton(), 
              _buildFilters(),
              Expanded(
                child: _filteredRecords.isEmpty
                    ? const Center(child: Text('No records found.'))
                    : ListView.builder(
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final rec = _filteredRecords[index];
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
                                            onRecordAdded: widget.onRecordAdded,
                                          ),
                                        ),
                                      ).then((result) {
                                        if (result == true) {
                                          if (widget.onRecordAdded != null) {
                                            widget.onRecordAdded!();
                                          }
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
                          icon: Icon(Icons.close, color: Colors.black),
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
                          icon: Icon(Icons.close, color: Colors.black),
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
          );
  }
Widget _buildRefreshButton() {
  return Align(
    alignment: Alignment.centerRight,
    child: IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      tooltip: 'Refresh Records',
      onPressed: _loadRecords,
    ),
  );
}

}

