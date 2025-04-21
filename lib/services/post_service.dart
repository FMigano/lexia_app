import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Toggle like function
  Future<void> toggleLike(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get references
    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(currentUser.uid);

    // Use a transaction for safe update
    return _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        // User already liked this post - unlike it
        transaction.delete(likeRef);
        transaction.update(postRef, {'likeCount': FieldValue.increment(-1)});
      } else {
        // User hasn't liked this post yet - add like
        transaction.set(likeRef, {
          'userId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }

  // Add comment function
  Future<void> addComment(String postId, String comment) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get references
    final postRef = _firestore.collection('posts').doc(postId);
    final commentsRef = postRef.collection('comments');

    // Use a transaction to update comment count atomically
    return _firestore.runTransaction((transaction) async {
      // Step 1: Add the comment
      final commentDoc = commentsRef.doc(); // Generate a new document ID
      transaction.set(commentDoc, {
        'text': comment,
        'authorId': currentUser.uid,
        'authorName': currentUser.displayName ?? 'User',
        'authorPhotoUrl': currentUser.photoURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Step 2: Increment comment count on the post
      transaction.update(postRef, {'commentCount': FieldValue.increment(1)});

      return;
    });
  }
}
