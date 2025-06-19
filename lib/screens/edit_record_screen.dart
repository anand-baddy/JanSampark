import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../tricolor_background.dart';

class EditRecordScreen extends StatefulWidget {
  final Map<String, dynamic> record;
  final VoidCallback? onRecordAdded;

  const EditRecordScreen({
    Key? key,
    required this.record,
    this.onRecordAdded,
  }) : super(key: key);

  @override
  State<EditRecordScreen> createState() => _EditRecordScreenState();
}

class _EditRecordScreenState extends State<EditRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _forwardedDeptController;
  late TextEditingController _forwardedPersonController;
  late TextEditingController _expectedClosureDateController;
  late TextEditingController _responseSentDateController;
  late TextEditingController _actualClosureDateController;
  late TextEditingController _remarksController;
  late TextEditingController _followupDateController;
  String _status = '';
  List<String> _incomingImages = [];
  List<File> _responseImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final rec = widget.record;
    _forwardedDeptController = TextEditingController(text: rec['forwarded_dept'] ?? '');
    _forwardedPersonController = TextEditingController(text: rec['forwarded_person'] ?? '');
    _expectedClosureDateController = TextEditingController(text: rec['expected_closure_date'] ?? '');
    _responseSentDateController = TextEditingController(text: rec['response_sent_date'] ?? '');
    _actualClosureDateController = TextEditingController(text: rec['actual_closure_date'] ?? '');
    _remarksController = TextEditingController(text: rec['remarks'] ?? '');
    _followupDateController = TextEditingController(text: rec['followup_date'] ?? '');
    _status = rec['status'] ?? '';
    _incomingImages = (rec['incoming_images'] as String?)?.split(';').where((e) => e.isNotEmpty).toList() ?? [];
    _loadResponseImages();
  }

  Future<void> _loadResponseImages() async {
    final rec = widget.record;
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'images'));
    final filenames = (rec['response_images'] as String?)?.split(';').where((e) => e.isNotEmpty).toList() ?? [];
    setState(() {
      _responseImages = filenames.map((name) => File(p.join(imagesDir.path, name))).toList();
    });
  }

  Future<String> _getImageFullPath(String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'images', filename);
  }

  Future<List<File>> _copyImagesToAppDir(List<XFile> pickedFiles) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    List<File> copiedFiles = [];
    for (var xfile in pickedFiles) {
      final fileName = p.basename(xfile.path);
      final newPath = p.join(imagesDir.path, fileName);
      final copiedFile = await File(xfile.path).copy(newPath);
      copiedFiles.add(copiedFile);
    }
    return copiedFiles;
  }

  Future<void> _pickResponseImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      final copiedFiles = await _copyImagesToAppDir(images);
      setState(() {
        _responseImages.addAll(copiedFiles);
      });
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? initial = DateTime.tryParse(controller.text);
    initial ??= DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Widget _buildReadOnlyImages() {
    return FutureBuilder<List<Widget>>(
      future: () async {
        List<Widget> widgets = [];
        for (final img in _incomingImages) {
          final path = await _getImageFullPath(img);
          widgets.add(
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.8,
                            maxWidth: MediaQuery.of(context).size.width * 0.95,
                          ),
                          child: PhotoView(
                            imageProvider: FileImage(File(path)),
                            backgroundDecoration: const BoxDecoration(color: Colors.black),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 32),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Close',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        }
        return widgets;
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Wrap(children: snapshot.data!);
        }
        return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      },
    );
  }

  Widget _buildResponseImageThumbnails() {
    return Wrap(
      children: List.generate(_responseImages.length, (index) {
        final file = _responseImages[index];
        return Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.8,
                            maxWidth: MediaQuery.of(context).size.width * 0.95,
                          ),
                          child: PhotoView(
                            imageProvider: FileImage(file),
                            backgroundDecoration: const BoxDecoration(color: Colors.black),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 32),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Close',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _responseImages.removeAt(index);
                  });
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _pickDate(controller),
        ),
      ),
      readOnly: true,
      onTap: () => _pickDate(controller),
    );
  }
  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final rec = widget.record;
      List<String> responsePaths = _responseImages.map((f) => p.basename(f.path)).toList();
      final updated = {
        ...rec,
        'forwarded_dept': _forwardedDeptController.text,
        'forwarded_person': _forwardedPersonController.text,
        'expected_closure_date': _expectedClosureDateController.text,
        'response_sent_date': _responseSentDateController.text,
        'actual_closure_date': _actualClosureDateController.text,
        'status': _status,
        'remarks': _remarksController.text,
        'followup_date': _followupDateController.text,
        'response_images': responsePaths.join(';'),
      };
      await DatabaseHelper.instance.updateRecord(updated);
      // Update notification count via callback, just like add_form_tab
      if (widget.onRecordAdded != null) {
        widget.onRecordAdded!();
      }
        Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.record;
    return TricolorBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Cancel Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(height: 8),

                // Unique ID (label style, disabled TextFormField)
                TextFormField(
                  initialValue: rec['unique_id'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Unique ID',
                  ),
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 10),

                // Read-only fields (label style)
                TextFormField(
                  initialValue: rec['recd_date'] ?? '',
                  decoration: const InputDecoration(labelText: 'Received Date'),
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: rec['requestor_name'] ?? '',
                  decoration: const InputDecoration(labelText: 'Requestor Name'),
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: rec['requestor_location'] ?? '',
                  decoration: const InputDecoration(labelText: 'Requestor Location'),
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: rec['subject'] ?? '',
                  decoration: const InputDecoration(labelText: 'Subject'),
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 10),

                // Incoming Scan Images (label style, disabled TextFormField)
                TextFormField(
                  initialValue: '',
                  decoration: const InputDecoration(labelText: 'Incoming Scan Images'),
                  enabled: false,
                ),
                _buildReadOnlyImages(),
                const SizedBox(height: 10),

                // Response Scan Images (label style, disabled TextFormField)
                TextFormField(
                  initialValue: '',
                  decoration: const InputDecoration(labelText: 'Response Scan Images'),
                  enabled: false,
                ),
                Row(
                  children: [
                    _buildResponseImageThumbnails(),
                    IconButton(
                      icon: const Icon(Icons.add_a_photo),
                      onPressed: _pickResponseImages,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _forwardedDeptController,
                  decoration: const InputDecoration(labelText: 'Forwarded Dept'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _forwardedPersonController,
                  decoration: const InputDecoration(labelText: 'Forwarded Person'),
                ),
                const SizedBox(height: 10),

                _buildDateField(_expectedClosureDateController, 'Expected Closure Date'),
                const SizedBox(height: 10),
                _buildDateField(_responseSentDateController, 'Response Sent Date'),
                const SizedBox(height: 10),
                _buildDateField(_actualClosureDateController, 'Actual Closure Date'),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: _status.isEmpty ? null : _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    'New',
                    'In Progress',
                    'Pending External',
                    'Closed'
                  ].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _status = val!;
                    });
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: 'Remarks'),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _buildDateField(_followupDateController, 'Followup Date'),
                const SizedBox(height: 24),

                // Bottom Row: Cancel and Save Changes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

