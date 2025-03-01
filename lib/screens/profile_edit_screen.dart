import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:healthkit_integration_testing/providers/user_profile_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: '30');
    _heightController = TextEditingController(text: '170');
    _weightController = TextEditingController(text: '70');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Load user data from database
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              subtitle: Text('Override automatic detection from HealthKit'),
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

  void _saveProfile() {
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);

    final age = int.tryParse(_ageController.text) ?? 30;
    final height = double.tryParse(_heightController.text) ?? 170.0;
    final weight = double.tryParse(_weightController.text) ?? 70.0;

    userProfileProvider.updateUserProfile(
      age: age,
      gender: _gender,
      height: height,
      weight: weight,
      smoke: _smoke,
      alco: _alco,
      active: _active,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
