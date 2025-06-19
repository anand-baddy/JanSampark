import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import '../tricolor_background.dart';
import 'package:file_picker/file_picker.dart';

class SetupTab extends StatefulWidget {
  const SetupTab({super.key});

  @override
  State<SetupTab> createState() => _SetupTabState();
}

class _SetupTabState extends State<SetupTab> {
  String? imagePath1;
  String? imagePath2;
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      imagePath1 = prefs.getString('login_image1');
      imagePath2 = prefs.getString('login_image2');
      _ownerController.text = prefs.getString('owner_name') ?? '';
      _userController.text = prefs.getString('login_username') ?? 'user';
      _passController.text = prefs.getString('login_password') ?? '1234';
    });
  }

  Future<void> _pickImage(int imageNumber) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('login_image$imageNumber', picked.path);
      setState(() {
        if (imageNumber == 1) imagePath1 = picked.path;
        if (imageNumber == 2) imagePath2 = picked.path;
      });
    }
  }

  Future<void> _saveOwner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('owner_name', _ownerController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Owner name saved!')),
    );
    setState(() {});
  }

  Future<void> _saveUserPass() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('login_username', _userController.text.trim());
    await prefs.setString('login_password', _passController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User and password updated!')),
    );
  }

  Future<void> _exportData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(appDir.path, 'app.db')); // Adjust DB filename if different
      final imagesDir = Directory(p.join(appDir.path, 'images'));

      final archive = Archive();

      // Add DB file to archive
      if (await dbFile.exists()) {
        archive.addFile(ArchiveFile('app.db', await dbFile.length(), await dbFile.readAsBytes()));
      }

      // Add images recursively to archive
      if (await imagesDir.exists()) {
        for (var entity in imagesDir.listSync(recursive: true)) {
          if (entity is File) {
            final relPath = p.relative(entity.path, from: appDir.path);
            archive.addFile(ArchiveFile(relPath, await entity.length(), await entity.readAsBytes()));
          }
        }
      }

      final zipBytes = ZipEncoder().encode(archive)!;

      // Generate filename with timestamp
      final now = DateTime.now();
      final formatted = DateFormat('ddMMyy-HHmm').format(now);
      final zipFileName = 'jansampark_backup-$formatted.zip';

      String zipPath;

      if (Platform.isAndroid) {
        // Standard Downloads path for Android
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          throw Exception('Downloads folder not found');
        }
        zipPath = p.join(downloadsDir.path, zipFileName);
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) throw Exception('Downloads folder not found');
        zipPath = p.join(downloadsDir.path, zipFileName);
      } else {
        // iOS and fallback: use app directory
        zipPath = p.join(appDir.path, zipFileName);
      }

      final outFile = File(zipPath);
      await outFile.writeAsBytes(zipBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to $zipPath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importData() async {
    try {
      // Use file_picker for user to select zip file
      File? zipFile;
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (result != null && result.files.single.path != null) {
          zipFile = File(result.files.single.path!);
        }
      } catch (_) {}

      if (zipFile == null || !await zipFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No zip file selected.')),
        );
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(appDir.path, 'app.db')); // Adjust DB filename if different
      final imagesDir = Directory(p.join(appDir.path, 'images'));

      // Read and decode zip archive
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Clear existing data
      if (await dbFile.exists()) await dbFile.delete();
      if (await imagesDir.exists()) await imagesDir.delete(recursive: true);

      // Extract files
      for (final file in archive) {
        final filename = file.name;
        final outPath = p.join(appDir.path, filename);
        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(outPath).create(recursive: true);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import complete! Please restart the app.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TricolorBackground(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Set Login Page Images:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (imagePath1 != null && imagePath1!.isNotEmpty)
                      Image.file(File(imagePath1!), height: 100)
                    else
                      Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      ),
                    TextButton(
                      onPressed: () => _pickImage(1),
                      child: const Text('Set Image 1'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (imagePath2 != null && imagePath2!.isNotEmpty)
                      Image.file(File(imagePath2!), height: 100)
                    else
                      Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      ),
                    TextButton(
                      onPressed: () => _pickImage(2),
                      child: const Text('Set Image 2'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Set Owner Name:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _ownerController,
            decoration: const InputDecoration(labelText: 'Owner Name'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveOwner,
            child: const Text('Save Owner Name'),
          ),
          /*const SizedBox(height: 24),  //remove usr/pwd from setup page
          const Text('Set Login Username & Password:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _userController,
            decoration: const InputDecoration(labelText: 'Login Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passController,
            decoration: const InputDecoration(labelText: 'Login Password'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveUserPass,
            child: const Text('Save User & Password'),
          ), */ // remove usr/pwd from setup page
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _exportData,
            icon: const Icon(Icons.archive),
            label: const Text('Export Data (DB + Images)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _importData,
            icon: const Icon(Icons.unarchive),
            label: const Text('Import Data (DB + Images)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              SystemNavigator.pop();
            },
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Close App'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

