import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel_app/pages/add_page.dart';
import 'package:travel_app/pages/comment.dart';
import 'package:travel_app/pages/profile.dart';
import 'package:travel_app/services/database.dart';
import 'package:travel_app/services/shared_pref.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.successMessage});
  final String? successMessage;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? name, image, id, email;
  final TextEditingController searchcontroller = TextEditingController();
  Stream<QuerySnapshot>? postStream;

  bool _snackShown = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchcontroller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _getSharedPref();
    postStream = await DatabaseMethods().getPosts();
    if (mounted) setState(() {});
  }

  Future<void> _getSharedPref() async {
    name = await SharedpreferenceHelper().getUserDisplayName();
    image = await SharedpreferenceHelper().getUserImage();
    id = await SharedpreferenceHelper().getUserId();
    email = await SharedpreferenceHelper().getUserEmail();
    email ??= FirebaseAuth.instance.currentUser?.email;
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_snackShown) {
      _snackShown = true;
      String? message = widget.successMessage;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (message == null && args is String && args.isNotEmpty) message = args;
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                message!,
                style: const TextStyle(fontSize: 18.0, color: Colors.white),
              ),
            ),
          );
        });
      }
    }
  }

  Widget _postsList() {
    if (postStream == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<QuerySnapshot>(
      stream: postStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Error loading posts.',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No posts yet.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        final q = searchcontroller.text.trim().toLowerCase();
        final docs =
            q.isEmpty
                ? snapshot.data!.docs
                : snapshot.data!.docs.where((d) {
                  final m = d.data() as Map<String, dynamic>;
                  final userName =
                      (m['UserName'] ?? '').toString().toLowerCase();
                  final cityName =
                      (m['CityName'] ?? '').toString().toLowerCase();
                  final placeName =
                      (m['PlaceName'] ?? '').toString().toLowerCase();
                  return userName.contains(q) ||
                      cityName.contains(q) ||
                      placeName.contains(q);
                }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No results for your query.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final ds = docs[index];
            final data = ds.data() as Map<String, dynamic>;

            final ownerImage = (data['UserImage'] ?? '') as String;
            final ownerName = (data['UserName'] ?? '') as String;
            final postImage = (data['Image'] ?? '') as String;
            final placeName = (data['PlaceName'] ?? '') as String;
            final cityName = (data['CityName'] ?? '') as String;
            final caption = (data['Caption'] ?? '') as String;
            final ownerUid = (data['OwnerUid'] ?? '') as String;

            final likes = (data['Like'] ?? []) as List;
            final isLiked = id != null ? likes.contains(id) : false;

            return Container(
              margin: const EdgeInsets.only(left: 30, right: 30, bottom: 30),
              child: Material(
                elevation: 3.0,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 20.0,
                          left: 10.0,
                          right: 10,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage:
                                  (ownerImage.isNotEmpty)
                                      ? NetworkImage(ownerImage)
                                      : null,
                              child:
                                  ownerImage.isEmpty
                                      ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ownerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          postImage,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 6),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "$placeName , $cityName",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (caption.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            caption,
                            style: const TextStyle(
                              color: Color.fromARGB(179, 0, 0, 0),
                              fontSize: 15.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          right: 10,
                          bottom: 14,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (id == null) return;
                                await DatabaseMethods().addLike(ds.id, id!);
                                if (mounted) setState(() {});
                              },
                              child: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_outline,
                                color: isLiked ? Colors.red : Colors.black54,
                                size: 30.0,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            const Text(
                              "Like",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 30.0),
                            GestureDetector(
                              onTap: () {
                                final currentUid =
                                    FirebaseAuth.instance.currentUser!.uid;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CommentPage(
                                          userimage: image ?? '',
                                          username: name ?? '',
                                          postid: ds.id,
                                          postOwnerUid: ownerUid,
                                          currentUserUid: currentUid,
                                        ),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.comment_outlined,
                                color: Colors.black54,
                                size: 28.0,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            const Text(
                              "Comment",
                              style: TextStyle(
                                color: Colors.black,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.asset(
                "images/home.png",
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2.5,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 12,
                  right: 20.0,
                  left: 20.0,
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPage(),
                          ),
                        );
                      },
                      child: Material(
                        elevation: 3.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.blue,
                            size: 30.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                        if (!mounted) return;
                        await _getSharedPref();
                      },
                      child: Material(
                        elevation: 3.0,
                        borderRadius: BorderRadius.circular(60),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child:
                                (image != null && image!.isNotEmpty)
                                    ? Image.network(
                                      image!,
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                    )
                                    : Container(
                                      height: 50,
                                      width: 50,
                                      color: Colors.blue.shade100,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 160.0, left: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Travelers",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lato',
                        fontSize: 60.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Travel Community App",
                      style: TextStyle(
                        color: Color.fromARGB(205, 255, 255, 255),
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // SEARCH BOX
              Container(
                margin: EdgeInsets.only(
                  left: 30.0,
                  right: 30.0,
                  top: MediaQuery.of(context).size.height / 2.7,
                ),
                child: Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.only(left: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: searchcontroller,
                      onChanged: (_) {
                        if (mounted) setState(() {});
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search by place, city or user",
                        suffixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20.0),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _postsList(),
            ),
          ),
        ],
      ),
    );
  }
}
