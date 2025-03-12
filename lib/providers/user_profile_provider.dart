import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../models/user_profile.dart';
import '../config/app_config.dart';

class UserProfileProvider with ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  Map<String, dynamic>? _latestHealthMetrics;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get latestHealthMetrics => _latestHealthMetrics;

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
      db = await mongo.Db.create(AppConfig.mongoUri);
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
      db = await mongo.Db.create(AppConfig.mongoUri);
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

  Future<void> updateMLModelData(Map<String, dynamic> mlModelData) async {
    mongo.Db? db;
    try {
      print("Updating ML model data for user: ${mlModelData['user_id']}");
      print("ML model data to update: $mlModelData");
      db = await mongo.Db.create(AppConfig.mongoUri);
      await db.open();

      final mlModelCollection = db.collection('ml_model_data');

      await _loadLatestHealthMetrics(mlModelData['user_id']);

      if (_latestHealthMetrics != null) {
        mlModelData['ap_hi'] = _latestHealthMetrics!['ap_hi'] ?? 120.0;
        mlModelData['ap_lo'] = _latestHealthMetrics!['ap_lo'] ?? 80.0;
        mlModelData['cholesterol'] = _latestHealthMetrics!['cholesterol'] ?? 1;
        mlModelData['gluc'] = _latestHealthMetrics!['gluc'] ?? 1;
      }

      print("Final ML model data to save: $mlModelData");

      final result = await mlModelCollection.updateOne(
          mongo.where.eq('user_id', mlModelData['user_id']),
          {'\$set': mlModelData},
          upsert: true);

      print('ML model data update result: $result');

      final updatedDoc = await mlModelCollection
          .findOne(mongo.where.eq('user_id', mlModelData['user_id']));
      print('Updated document in ml_model_data: $updatedDoc');

      print('ML model data updated successfully');
    } catch (e) {
      print('Error updating ML model data: $e');
      throw Exception('Failed to update ML model data');
    } finally {
      if (db != null && db.isConnected) {
        await db.close();
      }
    }
  }

  Future<void> _loadLatestHealthMetrics(String userId) async {
    mongo.Db? db;
    try {
      db = await mongo.Db.create(AppConfig.mongoUri);
      await db.open();

      final healthCollection = db.collection('health_metrics');
      final healthData = await healthCollection
          .find(mongo.where
              .eq('user_id', userId)
              .sortBy('timestamp', descending: true)
              .limit(1))
          .toList();

      if (healthData.isNotEmpty) {
        _latestHealthMetrics = healthData.first;
      }
    } catch (e) {
      print('Error loading health metrics: $e');
    } finally {
      if (db != null && db.isConnected) {
        await db.close();
      }
    }
  }
}
