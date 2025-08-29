// lib/services/database.dart
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
    // Za ovo će trebati indeks ako kombiniraš where + orderBy negdje drugdje,
    // ali ovdje je samo orderBy CreatedAt.
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

  Future<Stream<QuerySnapshot>> getPostsPlace(String place) async {
    return _db
        .collection("Posts")
        .where("CityName", isEqualTo: place)
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

  // =========================
  // PROPAGACIJA PROFILA (OwnerUid)
  // =========================

  Future<Map<String, int>> propagateUserProfileUpdates({
    required String userId, // Firebase UID
    required String newName,
    required String? newImage,
  }) async {
    final Set<DocumentReference> postRefs = {};
    final Set<DocumentReference> commentRefs = {};

    // POSTS: svi postovi gdje je autor = OwnerUid
    final postsByOwner =
        await _db
            .collection('Posts')
            .where('OwnerUid', isEqualTo: userId)
            .get();
    postRefs.addAll(postsByOwner.docs.map((d) => d.reference));

    // COMMENTS: svi komentari (collectionGroup) gdje je autor = OwnerUid
    final commentsByOwner =
        await _db
            .collectionGroup('Comment')
            .where('OwnerUid', isEqualTo: userId)
            .get();
    commentRefs.addAll(commentsByOwner.docs.map((d) => d.reference));

    // payload (MIJENJAMO samo prikazna polja)
    final payload = <String, dynamic>{
      'UserName': newName,
      if (newImage != null && newImage.isNotEmpty) 'UserImage': newImage,
    };

    // batch u chunkovima
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

// ====== Helper funkcije (ako ih koristiš negdje) ======

Future<Stream<QuerySnapshot>> getPostsByUser(String ownerUid) async {
  return FirebaseFirestore.instance
      .collection("Posts")
      .where("OwnerUid", isEqualTo: ownerUid)
      .orderBy('CreatedAt', descending: true)
      .snapshots();
}

Future<void> deletePostWithComments(String postId) async {
  final db = FirebaseFirestore.instance;

  // obriši komentare
  final comments =
      await db.collection('Posts').doc(postId).collection('Comment').get();
  for (final d in comments.docs) {
    await d.reference.delete();
  }
  // obriši post
  await db.collection('Posts').doc(postId).delete();

  // obriši sliku iz storage-a (ako postoji)
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
