import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'dart:io';
import '../tricolor_background.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

// You should have this widget in your project, or define it as below
class TricolorBackground extends StatelessWidget {
  final Widget child;
  const TricolorBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.white, Colors.green],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _showLogin = false;
  
  String? imagePath1;
  String? imagePath2;

  @override
  void initState() {
    super.initState();
    _loadLoginImages();
    _checkEmailInPrefs();
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

Future<void> _loadLoginImages() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    imagePath1 = prefs.getString('login_image1');
    imagePath2 = prefs.getString('login_image2');
  });
}


  Future<void> _checkEmailInPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email == null || email.isEmpty) {
      // No email, show signup dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSignUpDialog();
      });
    } else {
      setState(() {
        _showLogin = true;
        _emailController.text = email;
      });
    }
  }

  Future<void> _showSignUpDialog() async {
    final signupEmailController = TextEditingController();
    final signupPasswordController = TextEditingController();
    bool signingUp = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('New Install, pls Sign Up'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const SizedBox(height: 40),
               TextFormField(
                  controller: signupEmailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter username';
                  },
                ),
                  TextFormField(
                  controller: signupPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter password';
                    return null;
                  },
                ),
            ],
          ),
          actions: [
            signingUp
                ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircularProgressIndicator(),
            )
                : TextButton(
              onPressed: () async {
                setStateDialog(() => signingUp = true);
                try {
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: signupEmailController.text.trim(),
                    password: signupPasswordController.text.trim(),
                  );
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('email', signupEmailController.text.trim());
                  await prefs.setString('password', signupPasswordController.text.trim());
                  Navigator.of(context).pop();
                  setState(() {
                    _showLogin = true;
                    _emailController.text = signupEmailController.text.trim();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign up successful! Please log in.')),
                  );
                } on FirebaseAuthException catch (e) {
                  setStateDialog(() => signingUp = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Sign up failed')),
                  );
                }
            }, // on pressed async
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _signIn() async {
    setState(() => _loading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      await prefs.setString('password', password);

      // Navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);
      if (e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        _showPasswordResetDialog(email);
      } else if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The email address is not valid.')),
        );
      } else if (e.code == 'user-disabled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This user account has been disabled.')),
        );
      } else if (e.code == 'too-many-requests') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Too many requests. Try again later.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }

  void _showPasswordResetDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: Text('Login failed. Would you like to reset your password?'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password reset email sent')),
                );
              } on FirebaseAuthException catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message ?? 'Error sending reset email')),
                );
              }
            },
            child: Text('Send Reset Email'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
//////////////////////new widget
    const ashokaBlue = Color(0xFF0D47A1);
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.25; // 25% of screen height per image

    return TricolorBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Login'),
          backgroundColor: ashokaBlue,
        ),
        body: _showLogin 
            ? Center (
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 420, // Optional: for web/large screens
                      minHeight: screenHeight * 0.3,
                    ),
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // IMAGES (large, stacked vertically or side-by-side)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Expanded( 
                              child: Container(
                                height: imageHeight,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: imagePath1 != null &&
                                        imagePath1!.isNotEmpty &&
                                        File(imagePath1!).existsSync()
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(imagePath1!),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: imageHeight,
                                        ),
                                      )
                                    : const Icon(Icons.image, size: 64, color: Colors.grey),
                              ),
                            ), //expanded
                             Expanded( 
                              child: Container(
                                height: imageHeight,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: imagePath2 != null &&
                                        imagePath2!.isNotEmpty &&
                                        File(imagePath2!).existsSync()
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(imagePath2!),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: imageHeight,
                                        ),
                                      )
                                    : const Icon(Icons.image, size: 64, color: Colors.grey),
                              ),
                             ), // expanded
                          ],
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 32),
                        _loading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    //backgroundColor: ashokaBlue,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _signIn,
                                  child: const Text('Login', style: TextStyle(fontSize: 18)),
                                ),
                              ),

                     ///////////////anand
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                       onPressed: _exportData,
                       icon: const Icon(Icons.archive),
                       label: const Text('Export Data (DB + Images)'),
                     ),
                     ////////////////////
                      ],
                    ),
                  ),
                ),
      ) // body center, 263
     : const Center(child: CircularProgressIndicator()),
    )
   );
////////////////widget end
  } //login widget end
}
