// lib/pages/profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:travel_app/pages/edit_post.dart';
import 'package:travel_app/pages/edit_profile.dart';
import 'package:travel_app/pages/login.dart';
import 'package:travel_app/services/shared_pref.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? name, email, image, uid;
  Stream<QuerySnapshot>? myPostsStream;
  bool _fallbackNoOrder = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // IMPORTANT: use OwnerUid (not UserId)
  Query _buildPostsQuery({required bool withOrder}) {
    final base = FirebaseFirestore.instance
        .collection("Posts")
        .where("OwnerUid", isEqualTo: uid);
    return withOrder ? base.orderBy('CreatedAt', descending: true) : base;
  }

  Future<void> _load() async {
    uid = FirebaseAuth.instance.currentUser?.uid;
    name = await SharedpreferenceHelper().getUserDisplayName();
    email =
        await SharedpreferenceHelper().getUserEmail() ??
        FirebaseAuth.instance.currentUser?.email;
    image = await SharedpreferenceHelper().getUserImage();

    if (uid != null && uid!.isNotEmpty) {
      myPostsStream = _buildPostsQuery(withOrder: true).snapshots();
    }
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await SharedpreferenceHelper().saveUserDisplayName('');
    await SharedpreferenceHelper().saveUserEmail('');
    await SharedpreferenceHelper().saveUserId('');
    await SharedpreferenceHelper().saveUserImage('');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
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

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Delete post?"),
            content: const Text(
              "This action cannot be undone and will also delete all comments.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;

      // delete comments
      final comments =
          await db.collection('Posts').doc(postId).collection('Comment').get();
      for (final d in comments.docs) {
        await d.reference.delete();
      }

      // delete post
      await db.collection('Posts').doc(postId).delete();

      // try to delete image in Storage (blogImage/{postId})
      try {
        await FirebaseStorage.instance
            .ref()
            .child('blogImage')
            .child(postId)
            .delete();
      } catch (_) {}

      _showSnack(Colors.green, "Post deleted");
    } catch (_) {
      _showSnack(Colors.red, "Delete failed");
    }
  }

  Widget _avatarCircle({double radius = 45}) {
    final hasUrl = (image != null && image!.isNotEmpty);
    if (!hasUrl) {
      return CircleAvatar(
        radius: radius,
        child: const Icon(Icons.person, size: 32),
      );
    }
    return ClipOval(
      child: Image.network(
        image!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => CircleAvatar(
              radius: radius,
              child: const Icon(Icons.person, size: 32),
            ),
      ),
    );
  }

  // Responsive header card
  Widget _profileHeaderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        elevation: 3.0,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(186, 250, 247, 247),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 360;

              final infoRow = Row(
                children: [
                  _avatarCircle(radius: 45),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name ?? 'Traveler',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final buttonsColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: isCompact ? double.infinity : 140,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );
                        await _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: isCompact ? double.infinity : 140,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoRow,
                    const SizedBox(height: 12),
                    buttonsColumn,
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: infoRow),
                    const SizedBox(width: 12),
                    buttonsColumn,
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _myPostsList() {
    if (uid == null || uid!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "You are not signed in.",
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    if (myPostsStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: myPostsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Error loading your posts. A Firestore index may be required.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                if (!_fallbackNoOrder)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _fallbackNoOrder = true;
                        myPostsStream =
                            _buildPostsQuery(withOrder: false).snapshots();
                      });
                    },
                    child: const Text("Use fallback without sorting"),
                  ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "You don't have any posts yet.",
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final ds = snapshot.data!.docs[index];
            final data = ds.data() as Map<String, dynamic>;
            final postId = ds.id;

            final imgUrl = (data["Image"] ?? "") as String;
            final place = (data["PlaceName"] ?? "") as String;
            final city = (data["CityName"] ?? "") as String;
            final caption = (data["Caption"] ?? "") as String;

            return Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Material(
                elevation: 3.0,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // image
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          imgUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // location + actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "$place, $city",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: "Edit post",
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditPostPage(postId: postId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, color: Colors.blue),
                            ),
                            IconButton(
                              tooltip: "Delete post",
                              onPressed: () => _deletePost(postId),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (caption.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            caption,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                    "Profile",
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
            const SizedBox(height: 16),

            _profileHeaderCard(),

            const SizedBox(height: 24),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Your posts",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _myPostsList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
