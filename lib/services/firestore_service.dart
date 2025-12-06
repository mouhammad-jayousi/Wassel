import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ==================== RIDES ====================
  
  /// Create a new ride request
  Future<String> createRide({
    required String riderId,
    required LatLng pickupLocation,
    required LatLng dropoffLocation,
    required String pickupAddress,
    required String dropoffAddress,
    required double estimatedFare,
    String? rideType,
    String? promoCode,
  }) async {
    try {
      DocumentReference rideRef = await _firestore.collection('rides').add({
        'riderId': riderId,
        'pickupLocation': GeoPoint(pickupLocation.latitude, pickupLocation.longitude),
        'dropoffLocation': GeoPoint(dropoffLocation.latitude, dropoffLocation.longitude),
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'estimatedFare': estimatedFare,
        'rideType': rideType ?? 'standard',
        'promoCode': promoCode,
        'status': 'searching', // searching, driverAssigned, driverArriving, inProgress, completed, cancelled
        'createdAt': FieldValue.serverTimestamp(),
        'driverId': null,
        'actualFare': null,
        'rating': null,
      });
      
      return rideRef.id;
    } catch (e) {
      print('Error creating ride: $e');
      rethrow;
    }
  }
  
  /// Update ride status
  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating ride status: $e');
      rethrow;
    }
  }
  
  /// Assign driver to ride
  Future<void> assignDriverToRide(String rideId, String driverId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'driverId': driverId,
        'status': 'driverAssigned',
        'assignedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error assigning driver: $e');
      rethrow;
    }
  }
  
  /// Complete ride
  Future<void> completeRide(String rideId, double actualFare) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': 'completed',
        'actualFare': actualFare,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error completing ride: $e');
      rethrow;
    }
  }
  
  /// Cancel ride
  Future<void> cancelRide(String rideId, String cancelledBy) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': 'cancelled',
        'cancelledBy': cancelledBy,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error cancelling ride: $e');
      rethrow;
    }
  }
  
  /// Rate ride
  Future<void> rateRide(String rideId, double rating, String? review) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'rating': rating,
        'review': review,
        'ratedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rating ride: $e');
      rethrow;
    }
  }
  
  /// Get ride by ID
  Future<Map<String, dynamic>?> getRide(String rideId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('rides').doc(rideId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('Error getting ride: $e');
      return null;
    }
  }
  
  /// Stream ride updates
  Stream<DocumentSnapshot> streamRide(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots();
  }
  
  /// Get user's ride history
  Future<List<Map<String, dynamic>>> getRideHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      print('Error getting ride history: $e');
      return [];
    }
  }
  
  // ==================== DRIVERS ====================
  
  /// Get nearby available drivers
  Future<List<Map<String, dynamic>>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // Note: For production, use GeoFlutterFire or similar for proper geoqueries
      QuerySnapshot snapshot = await _firestore
          .collection('drivers')
          .where('isAvailable', isEqualTo: true)
          .where('isOnline', isEqualTo: true)
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      print('Error getting nearby drivers: $e');
      return [];
    }
  }
  
  /// Stream driver location
  Stream<DocumentSnapshot> streamDriverLocation(String driverId) {
    return _firestore.collection('drivers').doc(driverId).snapshots();
  }
  
  // ==================== MESSAGES ====================
  
  /// Send message in ride chat
  Future<void> sendMessage({
    required String rideId,
    required String senderId,
    required String senderType, // 'rider' or 'driver'
    required String message,
  }) async {
    try {
      await _firestore
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'senderType': senderType,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
  
  /// Stream messages for a ride
  Stream<QuerySnapshot> streamMessages(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
  
  /// Mark messages as read
  Future<void> markMessagesAsRead(String rideId, String userId) async {
    try {
      QuerySnapshot unreadMessages = await _firestore
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
  
  // ==================== FAVORITES ====================
  
  /// Add favorite location
  Future<void> addFavoriteLocation({
    required String userId,
    required String name,
    required String address,
    required LatLng location,
    String? type, // 'home', 'work', 'other'
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('favorites').add({
        'name': name,
        'address': address,
        'location': GeoPoint(location.latitude, location.longitude),
        'type': type ?? 'other',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding favorite location: $e');
      rethrow;
    }
  }
  
  /// Get favorite locations
  Future<List<Map<String, dynamic>>> getFavoriteLocations(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      print('Error getting favorite locations: $e');
      return [];
    }
  }
  
  /// Delete favorite location
  Future<void> deleteFavoriteLocation(String userId, String favoriteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(favoriteId)
          .delete();
    } catch (e) {
      print('Error deleting favorite location: $e');
      rethrow;
    }
  }
}
