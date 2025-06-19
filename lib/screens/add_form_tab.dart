import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import '../db/database_helper.dart';
import '../tricolor_background.dart';

class AddFormTab extends StatefulWidget {
  final VoidCallback? onRecordAdded;
  const AddFormTab({Key? key, this.onRecordAdded}) : super(key: key);

  @override
  State<AddFormTab> createState() => _AddFormTabState();
}

class _AddFormTabState extends State<AddFormTab> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'Complaint';
  String _uniqueId = '';

  final TextEditingController _recdDateController = TextEditingController();
  final TextEditingController _requestorNameController = TextEditingController();
  final TextEditingController _requestorLocationController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _forwardedDeptController = TextEditingController();
  final TextEditingController _forwardedPersonController = TextEditingController();
  final TextEditingController _expectedClosureDateController = TextEditingController();
  final TextEditingController _responseSentDateController = TextEditingController();
  final TextEditingController _actualClosureDateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _followupDateController = TextEditingController();

  List<File> _incomingImages = [];
  List<File> _responseImages = [];

  final ImagePicker _picker = ImagePicker();

  String _status = 'New';
  bool _incomingImageError = false;

  @override
  void initState() {
    super.initState();
    _recdDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _generateUniqueId();
  }

  Future<void> _generateUniqueId() async {
    int count = await DatabaseHelper.instance.getCountByType(_type);
    setState(() {
      _uniqueId = (_type == 'Complaint' ? 'COMP-' : 'REQ-') + (count + 1).toString();
    });
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        if (required)
          const Text(' *', style: TextStyle(color: Colors.red)),
      ],
    );
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

  Future<void> _pickImages(bool isIncoming) async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      final copiedFiles = await _copyImagesToAppDir(images);
      setState(() {
        if (isIncoming) {
          _incomingImages.addAll(copiedFiles);
        } else {
          _responseImages.addAll(copiedFiles);
        }
      });
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _incomingImageError = _incomingImages.isEmpty;
    });
    if (_formKey.currentState!.validate() && !_incomingImageError) {
      // Store only relative paths (filenames) in the DB
      List<String> incomingPaths = _incomingImages.map((f) => p.basename(f.path)).toList();
      List<String> responsePaths = _responseImages.map((f) => p.basename(f.path)).toList();

      Map<String, dynamic> row = {
        'unique_id': _uniqueId,
        'type': _type,
        'recd_date': _recdDateController.text,
        'requestor_name': _requestorNameController.text,
        'requestor_location': _requestorLocationController.text,
        'subject': _subjectController.text,
        'incoming_images': incomingPaths.join(';'),
        'response_images': responsePaths.join(';'),
        'forwarded_dept': _forwardedDeptController.text,
        'forwarded_person': _forwardedPersonController.text,
        'expected_closure_date': _expectedClosureDateController.text,
        'response_sent_date': _responseSentDateController.text,
        'actual_closure_date': _actualClosureDateController.text,
        'status': _status,
        'remarks': _remarksController.text,
        'followup_date': _followupDateController.text,
      };

      await DatabaseHelper.instance.insertRecord(row);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record saved')));

      // Clear all fields and reset state
      setState(() {
        _recdDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _requestorNameController.clear();
        _requestorLocationController.clear();
        _subjectController.clear();
        _forwardedDeptController.clear();
        _forwardedPersonController.clear();
        _expectedClosureDateController.clear();
        _responseSentDateController.clear();
        _actualClosureDateController.clear();
        _remarksController.clear();
        _followupDateController.clear();
        _type = 'Complaint';
        _status = 'New';
        _incomingImages.clear();
        _responseImages.clear();
        _incomingImageError = false;
      });

      // Notify parent (HomeScreen) to refresh the badge
      if (widget.onRecordAdded != null) {
        widget.onRecordAdded!();
      }

      await _generateUniqueId();
    }
  }

  Widget _buildImageThumbnails(List<File> images, void Function(int) onDelete) {
    return Wrap(
      children: List.generate(images.length, (index) {
        final file = images[index];
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
                onTap: () => onDelete(index),
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

  @override
  Widget build(BuildContext context) {
    return TricolorBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Complaint', style: TextStyle(color: Colors.black)),
                        value: 'Complaint',
                        groupValue: _type,
                        onChanged: (val) {
                          setState(() {
                            _type = val!;
                            _generateUniqueId();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Request', style: TextStyle(color: Colors.black)),
                        value: 'Request',
                        groupValue: _type,
                        onChanged: (val) {
                          setState(() {
                            _type = val!;
                            _generateUniqueId();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Text('Unique ID: $_uniqueId', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 10),

                // Received Date
                TextFormField(
                  controller: _recdDateController,
                  decoration: InputDecoration(
                    label: _buildLabel('Received Date', required: true),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(_recdDateController),
                    ),
                  ),
                  readOnly: true,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),

                // Requestor Name
                TextFormField(
                  controller: _requestorNameController,
                  decoration: InputDecoration(
                    label: _buildLabel('Requestor Name', required: true),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),

                // Requestor Location
                TextFormField(
                  controller: _requestorLocationController,
                  decoration: InputDecoration(
                    label: _buildLabel('Requestor Location', required: true),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),

                // Subject
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    label: _buildLabel('Subject', required: true),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),

                // Incoming Scan Images
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: _buildLabel('Incoming Scan Images', required: true),
                ),
                Row(
                  children: [
                    _buildImageThumbnails(_incomingImages, (idx) {
                      setState(() {
                        _incomingImages.removeAt(idx);
                      });
                    }),
                    IconButton(
                      icon: const Icon(Icons.add_a_photo),
                      onPressed: () => _pickImages(true),
                    ),
                  ],
                ),
                if (_incomingImageError)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Text('At least one image required', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),

                // Response Scan Images
                const Padding(
                  padding: EdgeInsets.only(top: 12.0, bottom: 4.0),
                  child: Text('Response Scan Images', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                Row(
                  children: [
                    _buildImageThumbnails(_responseImages, (idx) {
                      setState(() {
                        _responseImages.removeAt(idx);
                      });
                    }),
                    IconButton(
                      icon: const Icon(Icons.add_a_photo),
                      onPressed: () => _pickImages(false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Forwarded Dept
                TextFormField(
                  controller: _forwardedDeptController,
                  decoration: const InputDecoration(labelText: 'Forwarded Dept'),
                ),
                const SizedBox(height: 10),

                // Forwarded Person
                TextFormField(
                  controller: _forwardedPersonController,
                  decoration: const InputDecoration(labelText: 'Forwarded Person'),
                ),
                const SizedBox(height: 10),

                // Expected Closure Date
                TextFormField(
                  controller: _expectedClosureDateController,
                  decoration: InputDecoration(
                    labelText: 'Expected Closure Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(_expectedClosureDateController),
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 10),

                // Response Sent Date
                TextFormField(
                  controller: _responseSentDateController,
                  decoration: InputDecoration(
                    labelText: 'Response Sent Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(_responseSentDateController),
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 10),

                // Actual Closure Date
                TextFormField(
                  controller: _actualClosureDateController,
                  decoration: InputDecoration(
                    labelText: 'Actual Closure Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(_actualClosureDateController),
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 10),

                // Status
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'New', child: Text('New')),
                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Pending External', child: Text('Pending External')),
                    DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _status = val!;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Remarks
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: 'Remarks'),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                // Followup Date
                TextFormField(
                  controller: _followupDateController,
                  decoration: InputDecoration(
                    labelText: 'Followup Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(_followupDateController),
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

