import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../models/user_profile.dart';

class UserProfileProvider with ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  Future<void> loadUserProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dbProfile = await _loadFromDatabase(userId);

      if (dbProfile != null) {
        _userProfile = dbProfile;
      } else {
        _userProfile = await UserProfile.fromHealthKit(userId);

        await saveUserProfile(_userProfile!);
      }
    } catch (e) {
      print("Cannot loading user profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserProfile?> _loadFromDatabase(String userId) async {
    mongo.Db? db;
    try {
      final String connectionString =
          'mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics';
      db = await mongo.Db.create(connectionString);
      await db.open();

      final userCollection = db.collection('user_profiles');
      final userData =
          await userCollection.findOne(mongo.where.eq('user_id', userId));

      if (userData != null) {
        return UserProfile.fromMap(userData);
      }
      return null;
    } catch (e) {
      print("Error loading profile from database: $e");
      return null;
    } finally {
      if (db != null && db.isConnected) {
        await db.close();
      }
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    mongo.Db? db;
    try {
      print("Trying to save profile for user: ${profile.userId}");
      final String connectionString =
          'mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics';
      db = await mongo.Db.create(connectionString);
      await db.open();

      final userCollection = db.collection('user_profiles');
      print(
          "Connected to MongoDB, updating profile with data: ${profile.toMap()}");
      await userCollection.update(
          mongo.where.eq('user_id', profile.userId), profile.toMap(),
          upsert: true);

      _userProfile = profile;
      print("Profile saved successfully");
      notifyListeners();
    } catch (e) {
      print("Cannot save profile to database: $e");
      throw e; 
    } finally {
      if (db != null && db.isConnected) {
        await db.close();
        print("MongoDB connection closed");
      }
    }
  }

  Future<void> updateUserProfile({
    int? age,
    int? gender,
    double? height,
    double? weight,
    bool? smoke,
    bool? alco,
    bool? active,
  }) async {
    if (_userProfile == null) {
      print("Cannot update profile: No user profile loaded");
      return;
    }

    print("Updating profile for user: ${_userProfile!.userId}");
    final updatedProfile = UserProfile(
      userId: _userProfile!.userId,
      age: age ?? _userProfile!.age,
      gender: gender ?? _userProfile!.gender,
      height: height ?? _userProfile!.height,
      weight: weight ?? _userProfile!.weight,
      smoke: smoke ?? _userProfile!.smoke,
      alco: alco ?? _userProfile!.alco,
      active: active ?? _userProfile!.active,
    );

    await saveUserProfile(updatedProfile);
  }
}
