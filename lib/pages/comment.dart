// lib/pages/comment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel_app/services/database.dart';

class CommentPage extends StatefulWidget {
  final String username, userimage, postid;

  // ⬇️ novo: koristimo UID-ove (Firebase)
  final String postOwnerUid;
  final String currentUserUid;

  const CommentPage({
    super.key,
    required this.userimage,
    required this.username,
    required this.postid,
    required this.postOwnerUid,
    required this.currentUserUid,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController commentcontroller = TextEditingController();
  Stream? commentStream;

  getontheload() async {
    commentStream = await DatabaseMethods().getComments(widget.postid);
    setState(() {});
  }

  @override
  void initState() {
    getontheload();
    super.initState();
  }

  Future<void> _deleteComment(String commentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete comments?"),
            content: const Text("This action cannot be undone!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );
    if (ok != true) return;

    try {
      await DatabaseMethods().deleteComment(
        postId: widget.postid,
        commentId: commentId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Comment deleted"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
      );
    }
  }

  Widget allComments() {
    return StreamBuilder(
      stream: commentStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot ds = snapshot.data.docs[index];
                final String commentId = ds.id;
                final String authorUid = (ds["OwnerUid"] ?? "") as String;

                final bool canDelete =
                    widget.currentUserUid == authorUid ||
                    widget.currentUserUid == widget.postOwnerUid;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20.0),
                  child: Material(
                    elevation: 3.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              ds["UserImage"],
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 20.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ds["UserName"],
                                        style: const TextStyle(
                                          color: Color.fromARGB(169, 0, 0, 0),
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (canDelete)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deleteComment(commentId),
                                        tooltip: "Delete comment",
                                      ),
                                  ],
                                ),
                                Text(
                                  ds["Comment"],
                                  style: const TextStyle(
                                    color: Color.fromARGB(230, 0, 0, 0),
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
            : const SizedBox();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                SizedBox(width: MediaQuery.of(context).size.width / 7),
                const Text(
                  "Add Comment",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 26.0,
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
                  children: [
                    Expanded(child: allComments()),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(left: 20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black45,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: commentcontroller,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Write a Comment...",
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        GestureDetector(
                          onTap: () async {
                            final uid = FirebaseAuth.instance.currentUser!.uid;
                            final addComment = {
                              "OwnerUid": uid,
                              "UserId": uid,
                              "UserName": widget.username,
                              "UserImage": widget.userimage,
                              "Comment": commentcontroller.text.trim(),
                              "CreatedAt": FieldValue.serverTimestamp(),
                            };

                            await DatabaseMethods().addComment(
                              addComment,
                              widget.postid,
                            );
                            commentcontroller.clear();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 30.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
