import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:healthkit_integration_testing/providers/user_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileEditScreen extends StatefulWidget {
  @override
  _UserProfileEditScreenState createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  int _gender = 1;
  bool _smoke = false;
  bool _alco = false;
  bool _active = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: '30');
    _heightController = TextEditingController(text: '170');
    _weightController = TextEditingController(text: '70');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id') ?? '';

      if (userId.isEmpty) {
        print('Warning: No user ID found when loading profile data');
        return;
      }

      if (userProfileProvider.userProfile == null) {
        await userProfileProvider.loadUserProfile(userId);
      }

      if (userProfileProvider.userProfile != null) {
        setState(() {
          _ageController.text = userProfileProvider.userProfile!.age.toString();
          _gender = userProfileProvider.userProfile!.gender;
          _heightController.text =
              userProfileProvider.userProfile!.height.toString();
          _weightController.text =
              userProfileProvider.userProfile!.weight.toString();
          _smoke = userProfileProvider.userProfile!.smoke;
          _alco = userProfileProvider.userProfile!.alco;
          _active = userProfileProvider.userProfile!.active;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personal Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  TextField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  Text('Gender'),
                  Row(
                    children: [
                      Radio(
                        value: 1,
                        groupValue: _gender,
                        onChanged: (value) {
                          setState(() {
                            _gender = value as int;
                          });
                        },
                      ),
                      Text('Male'),
                      SizedBox(width: 16),
                      Radio(
                        value: 2,
                        groupValue: _gender,
                        onChanged: (value) {
                          setState(() {
                            _gender = value as int;
                          });
                        },
                      ),
                      Text('Female'),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _heightController,
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 24),
                  Text('Lifestyle',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: Text('Do you smoke?'),
                    value: _smoke,
                    onChanged: (value) {
                      setState(() {
                        _smoke = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('Do you consume alcohol?'),
                    value: _alco,
                    onChanged: (value) {
                      setState(() {
                        _alco = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('Are you physically active?'),
                    subtitle:
                        Text('Override automatic detection from HealthKit'),
                    value: _active,
                    onChanged: (value) {
                      setState(() {
                        _active = value;
                      });
                    },
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: Text('Save Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id') ?? '';

      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: User not logged in')),
        );
        return;
      }

      final age = int.tryParse(_ageController.text) ?? 30;
      final height = double.tryParse(_heightController.text) ?? 170.0;
      final weight = double.tryParse(_weightController.text) ?? 70.0;

      if (userProfileProvider.userProfile == null) {
        final newProfile = UserProfile(
          userId: userId,
          age: age,
          gender: _gender,
          height: height,
          weight: weight,
          smoke: _smoke,
          alco: _alco,
          active: _active,
        );
        await userProfileProvider.saveUserProfile(newProfile);
      } else {
        await userProfileProvider.updateUserProfile(
          age: age,
          gender: _gender,
          height: height,
          weight: weight,
          smoke: _smoke,
          alco: _alco,
          active: _active,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
