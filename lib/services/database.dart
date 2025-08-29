import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseMethods {
  final _db = FirebaseFirestore.instance;

  Future addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    return await _db.collection("users").doc(id).set(userInfoMap);
  }

  Future<QuerySnapshot> getUserbyEmail(String email) async {
    return await _db.collection("users").where("Email", isEqualTo: email).get();
  }

  Future addPost(Map<String, dynamic> postMap, String id) async {
    return await _db.collection("Posts").doc(id).set(postMap);
  }

  Future<Stream<QuerySnapshot>> getPosts() async {
    return _db
        .collection("Posts")
        .orderBy('CreatedAt', descending: true)
        .snapshots();
  }

  Future addLike(String postId, String userUid) async {
    return await _db.collection("Posts").doc(postId).update({
      'Like': FieldValue.arrayUnion([userUid]),
    });
  }

  Future addComment(Map<String, dynamic> userInfoMap, String postId) async {
    // ne pregazi ako je već postavljen (npr. iz UI-a)
    userInfoMap.putIfAbsent('CreatedAt', () => FieldValue.serverTimestamp());
    return FirebaseFirestore.instance
        .collection("Posts")
        .doc(postId)
        .collection("Comment")
        .add(userInfoMap);
  }

  Future<Stream<QuerySnapshot>> getComments(String postId) async {
    return FirebaseFirestore.instance
        .collection("Posts")
        .doc(postId)
        .collection("Comment")
        .orderBy('CreatedAt', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> search(String updatedname) async {
    return await _db
        .collection("Location")
        .where(
          "SearchKey",
          isEqualTo: updatedname.substring(0, 1).toUpperCase(),
        )
        .get();
  }

  Future<Map<String, int>> propagateUserProfileUpdates({
    required String userId,
    required String newName,
    required String? newImage,
  }) async {
    final Set<DocumentReference> postRefs = {};
    final Set<DocumentReference> commentRefs = {};

    final postsByOwner =
        await _db
            .collection('Posts')
            .where('OwnerUid', isEqualTo: userId)
            .get();
    postRefs.addAll(postsByOwner.docs.map((d) => d.reference));

    final commentsByOwner =
        await _db
            .collectionGroup('Comment')
            .where('OwnerUid', isEqualTo: userId)
            .get();
    commentRefs.addAll(commentsByOwner.docs.map((d) => d.reference));

    final payload = <String, dynamic>{
      'UserName': newName,
      if (newImage != null && newImage.isNotEmpty) 'UserImage': newImage,
    };

    Future<int> _updateInBatches(
      Set<DocumentReference> refs,
      Map<String, dynamic> data,
    ) async {
      const int limit = 400;
      int total = 0;
      final list = refs.toList();
      for (int i = 0; i < list.length; i += limit) {
        final batch = _db.batch();
        final slice = list.sublist(
          i,
          (i + limit > list.length) ? list.length : i + limit,
        );
        for (final ref in slice) {
          batch.update(ref, data);
        }
        await batch.commit();
        total += slice.length;
      }
      return total;
    }

    final postsUpdated = await _updateInBatches(postRefs, payload);
    final commentsUpdated = await _updateInBatches(commentRefs, payload);

    return {"postsUpdated": postsUpdated, "commentsUpdated": commentsUpdated};
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await _db
        .collection("Posts")
        .doc(postId)
        .collection("Comment")
        .doc(commentId)
        .delete();
  }
}

Future<Stream<QuerySnapshot>> getPostsByUser(String ownerUid) async {
  return FirebaseFirestore.instance
      .collection("Posts")
      .where("OwnerUid", isEqualTo: ownerUid)
      .orderBy('CreatedAt', descending: true)
      .snapshots();
}

Future<void> deletePostWithComments(String postId) async {
  final db = FirebaseFirestore.instance;

  final comments =
      await db.collection('Posts').doc(postId).collection('Comment').get();
  for (final d in comments.docs) {
    await d.reference.delete();
  }
  await db.collection('Posts').doc(postId).delete();

  try {
    await FirebaseStorage.instance
        .ref()
        .child('blogImage')
        .child(postId)
        .delete();
  } catch (_) {}
}

Future<void> updatePost(String postId, Map<String, dynamic> data) async {
  await FirebaseFirestore.instance.collection('Posts').doc(postId).update(data);
}
