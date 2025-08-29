import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_app/services/shared_pref.dart';
import 'package:travel_app/services/database.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  String? id, email, imageUrl;

  // stare vrijednosti za propagaciju
  String _oldName = '';
  String? _oldImageUrl;

  bool _isSaving = false;
  File? _pickedImage;

  bool _showCurrentPw = false;
  bool _showNewPw = false;
  bool _showConfirmPw = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sp = SharedpreferenceHelper();
    _nameCtrl.text = (await sp.getUserDisplayName()) ?? '';
    _oldName = _nameCtrl.text;

    id = await sp.getUserId();
    email = await sp.getUserEmail() ?? FirebaseAuth.instance.currentUser?.email;
    imageUrl = await sp.getUserImage();
    _oldImageUrl = imageUrl;

    debugPrint('[EditProfile] loaded id=$id email=$email oldName=$_oldName');

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      _pickedImage = File(x.path);
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<String?> _uploadAvatarIfNeeded() async {
    if (_pickedImage == null || id == null || id!.isEmpty) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('userImages')
        .child('${id!}.jpg');
    final snap = await ref.putFile(_pickedImage!).whenComplete(() {});
    final url = await snap.ref.getDownloadURL();
    return url;
  }

  Future<void> _changePasswordIfNeeded() async {
    final current = _currentPwCtrl.text;
    final newPw = _newPwCtrl.text;
    final confirm = _confirmPwCtrl.text;

    if (current.isEmpty && newPw.isEmpty && confirm.isEmpty) return;

    if (newPw.length < 6) {
      _showSnack(Colors.red, "New password must be at least 6 characters");
      throw Exception("weak password");
    }
    if (newPw != confirm) {
      _showSnack(Colors.red, "Passwords do not match");
      throw Exception("pw mismatch");
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || (email ?? '').isEmpty) {
      _showSnack(Colors.red, "Not authenticated");
      throw Exception("no user");
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: email!,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPw);
      _showSnack(Colors.green, "Password updated");
    } on FirebaseAuthException catch (e) {
      String m = "Password update failed";
      if (e.code == 'wrong-password') m = "Current password is incorrect";
      if (e.code == 'requires-recent-login') {
        m = "Please login again to change password";
      }
      _showSnack(Colors.red, m);
      rethrow;
    }
  }

  Future<void> _save() async {
    final newName = _nameCtrl.text.trim();

    if (newName.isEmpty) {
      _showSnack(Colors.red, "Name cannot be empty");
      return;
    }
    if (id == null || id!.isEmpty) {
      _showSnack(Colors.red, "No user id found — login again");
      return;
    }

    setState(() => _isSaving = true);
    try {
      debugPrint(
        '[EditProfile] SAVING for id=$id (oldName=$_oldName oldImage=$_oldImageUrl)',
      );

      final newImageUrl = await _uploadAvatarIfNeeded();
      if (newImageUrl != null) imageUrl = newImageUrl;

      await FirebaseFirestore.instance.collection('users').doc(id).set({
        "Name": newName,
        if (imageUrl != null) "Image": imageUrl,
        "Id": id,
        if (email != null) "Email": email,
      }, SetOptions(merge: true));

      final sp = SharedpreferenceHelper();
      await sp.saveUserDisplayName(newName);
      if (imageUrl != null) await sp.saveUserImage(imageUrl!);

      await _changePasswordIfNeeded();

      final result = await DatabaseMethods().propagateUserProfileUpdates(
        userId: id!,
        newName: newName,
        newImage: imageUrl,
      );

      _showSnack(
        Colors.green,
        "Profile updated (${result['postsUpdated']} posts, ${result['commentsUpdated']} comments)",
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('[EditProfile] ERROR: $e');
      _showSnack(Colors.red, "Update failed. Check console for details.");
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(Color bg, String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 40.0, right: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Material(
                    elevation: 3.0,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  "Edit Profile",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 44),
              ],
            ),
          ),
          const SizedBox(height: 30.0),
          Expanded(
            child: Material(
              elevation: 3.0,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(186, 250, 247, 247),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child:
                                _pickedImage != null
                                    ? Image.file(
                                      _pickedImage!,
                                      fit: BoxFit.cover,
                                    )
                                    : (imageUrl != null && imageUrl!.isNotEmpty
                                        ? Image.network(
                                          imageUrl!,
                                          fit: BoxFit.cover,
                                        )
                                        : Image.asset(
                                          "images/boy.jpg",
                                          fit: BoxFit.cover,
                                        )),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          "Tap image to change",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        "Name",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFececf8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter your name",
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        "Change Password (optional)",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFececf8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _currentPwCtrl,
                          obscureText: !_showCurrentPw,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Current password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showCurrentPw
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _showCurrentPw = !_showCurrentPw,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFececf8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _newPwCtrl,
                          obscureText: !_showNewPw,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "New password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showNewPw
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed:
                                  () =>
                                      setState(() => _showNewPw = !_showNewPw),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFececf8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _confirmPwCtrl,
                          obscureText: !_showConfirmPw,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Confirm new password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPw
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _showConfirmPw = !_showConfirmPw,
                                  ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: _isSaving ? null : _save,
                        child: Center(
                          child: Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width / 2,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        "Save",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
