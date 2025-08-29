// lib/pages/add_page.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:travel_app/services/database.dart';
import 'package:travel_app/services/shared_pref.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  String? name, image;

  getthesharedpref() async {
    name = await SharedpreferenceHelper().getUserDisplayName();
    image = await SharedpreferenceHelper().getUserImage();
    setState(() {});
  }

  @override
  void initState() {
    getthesharedpref();
    super.initState();
  }

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  Future getImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      selectedImage = File(x.path);
      setState(() {});
    }
  }

  final TextEditingController placenamecontroller = TextEditingController();
  final TextEditingController citynamecontroller = TextEditingController();
  final TextEditingController captioncontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                SizedBox(width: MediaQuery.of(context).size.width / 4.5),
                const Text(
                  "Add Post",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    selectedImage != null
                        ? Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              selectedImage!,
                              height: 180,
                              width: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                        : Center(
                          child: GestureDetector(
                            onTap: getImage,
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
                              child: const Icon(Icons.camera_alt_outlined),
                            ),
                          ),
                        ),
                    const SizedBox(height: 20.0),
                    const Text(
                      "Place Name",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    Container(
                      padding: const EdgeInsets.only(left: 20.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFececf8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: placenamecontroller,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Place Name",
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      "City Name",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    Container(
                      padding: const EdgeInsets.only(left: 20.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFececf8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: citynamecontroller,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter City Name",
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      "Caption",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    Container(
                      padding: const EdgeInsets.only(left: 20.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFececf8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: captioncontroller,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter Caption....",
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    GestureDetector(
                      onTap: () async {
                        if (selectedImage != null &&
                            placenamecontroller.text.isNotEmpty &&
                            citynamecontroller.text.isNotEmpty &&
                            captioncontroller.text.isNotEmpty) {
                          final addId = randomAlphaNumeric(10);

                          final ref = FirebaseStorage.instance
                              .ref()
                              .child("blogImage")
                              .child(addId);
                          final task = ref.putFile(selectedImage!);
                          final downloadUrl =
                              await (await task).ref.getDownloadURL();

                          final uid = FirebaseAuth.instance.currentUser!.uid;

                          final Map<String, dynamic> addPost = {
                            "Image": downloadUrl,
                            "PlaceName": placenamecontroller.text,
                            "CityName": citynamecontroller.text,
                            "Caption": captioncontroller.text,
                            "UserName": name,
                            "UserImage": image,
                            "OwnerUid": uid,
                            "CreatedAt": FieldValue.serverTimestamp(),
                            "Like": <String>[],
                          };

                          await DatabaseMethods().addPost(addPost, addId);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.green,
                              content: Text(
                                "Post has been Uploaded Successfully!",
                                style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: Center(
                        child: Container(
                          height: 50,
                          width: MediaQuery.of(context).size.width / 2,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Post",
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
        ],
      ),
    );
  }
}
