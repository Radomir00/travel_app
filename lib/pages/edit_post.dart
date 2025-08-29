import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditPostPage extends StatefulWidget {
  final String postId;
  const EditPostPage({super.key, required this.postId});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _placeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();

  String? _imageUrl;
  bool _loading = true;
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    _cityCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('Posts')
              .doc(widget.postId)
              .get();
      final data = snap.data() ?? {};
      _placeCtrl.text = (data['PlaceName'] ?? '').toString();
      _cityCtrl.text = (data['CityName'] ?? '').toString();
      _captionCtrl.text = (data['Caption'] ?? '').toString();
      _imageUrl = (data['Image'] ?? '').toString();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      _pickedImage = File(x.path);
      if (mounted) setState(() {});
    }
  }

  void _showSnack(Color bg, String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final place = _placeCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final caption = _captionCtrl.text.trim();

    if (place.isEmpty || city.isEmpty || caption.isEmpty) {
      _showSnack(Colors.red, "Sva polja su obavezna");
      return;
    }

    setState(() => _saving = true);
    try {
      String? newUrl = _imageUrl;
      if (_pickedImage != null) {
        // overwrite na istu putanju blogImage/{postId}
        final ref = FirebaseStorage.instance
            .ref()
            .child('blogImage')
            .child(widget.postId);
        final snap = await ref.putFile(_pickedImage!).whenComplete(() {});
        newUrl = await snap.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(widget.postId)
          .update({
            "PlaceName": place,
            "CityName": city,
            "Caption": caption,
            if (newUrl != null) "Image": newUrl,
          });

      _showSnack(Colors.green, "Objava ažurirana");
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showSnack(Colors.red, "Neuspjelo ažuriranje");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, top: 40.0),
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
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 4.5,
                        ),
                        const Text(
                          "Edit Post",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tijelo
                  Expanded(
                    child: Material(
                      elevation: 3.0,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          right: 10.0,
                          top: 30.0,
                        ),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(186, 250, 247, 247),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        width: MediaQuery.of(context).size.width,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 180,
                                    width: 180,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black45,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child:
                                        _pickedImage != null
                                            ? Image.file(
                                              _pickedImage!,
                                              fit: BoxFit.cover,
                                            )
                                            : (_imageUrl != null &&
                                                    _imageUrl!.isNotEmpty
                                                ? Image.network(
                                                  _imageUrl!,
                                                  fit: BoxFit.cover,
                                                )
                                                : const Icon(
                                                  Icons.camera_alt_outlined,
                                                )),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Place Name",
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
                                  controller: _placeCtrl,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Enter Place Name",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "City Name",
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
                                  controller: _cityCtrl,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Enter City Name",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Caption",
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
                                  controller: _captionCtrl,
                                  maxLines: 6,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Enter Caption....",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: _saving ? null : _save,
                                child: Center(
                                  child: Container(
                                    height: 50,
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child:
                                          _saving
                                              ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
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
