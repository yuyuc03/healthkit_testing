import 'package:flutter/material.dart';
import 'package:healthkit_integration_testing/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../providers/healthkit_provider.dart';
import './profile_edit_screen.dart';
import './privacy_policy_screen.dart';
import 'lifestyle_and_cultural_info.dart';
import '../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = 'User';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id') ?? '';

      if (userId.isEmpty) {
        print('We did not found an user ID when loading profile data');
        return;
      }

      final userData = await _fetchUserFromDatabase(userId);

      if (userData != null) {
        setState(() {
          _fullName = userData['fullName'] ?? 'User';
          _email = userData['email'] ?? '';
          _isLoading = false;
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

  Future<Map<String, dynamic>?> _fetchUserFromDatabase(String userId) async {
    mongo.Db? db;
    try {
      db = await mongo.Db.create(AppConfig.mongoUri);
      await db.open();

      final userCollection = db.collection('users');
      final userData =
          await userCollection.findOne(mongo.where.eq('_id', userId));

      return userData;
    } catch (e) {
      print('Error fetching user from database: $e');
      return null;
    } finally {
      if (db != null && db.isConnected) {
        await db.close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthKitProvider = Provider.of<HealthKitProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 24),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB3C7B6FF),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0.3, 0.9],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 1),
                      image: DecorationImage(
                        image: AssetImage('assets/images/profile_pic.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Hello, $_fullName!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(_email,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Account'),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Edit Profile'),
                    subtitle: Text('Change your personal information'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfileEditScreen())),
                  ),
                  ListTile(
                    leading: Icon(Icons.language),
                    title: Text('Lifestyle and Cultural Info'),
                    subtitle:
                        Text('Update your personal and cultural information'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LifestyleAndCulturalInfo()),
                    ),
                  ),
                  Divider(),
                  _buildSectionHeader('Health Data'),
                  healthKitProvider.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SwitchListTile(
                          secondary: Icon(Icons.favorite),
                          title: Text('Connect to HealthKit'),
                          subtitle: Text(healthKitProvider.healthKitConnected
                              ? 'Connected and syncing data'
                              : 'Connect to sync your health data'),
                          value: healthKitProvider.healthKitConnected,
                          onChanged: (value) async {
                            if (value) {
                              await healthKitProvider.connectHealthKit();
                            } else {
                              try {
                                final bool shouldDisconnect = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title:
                                            Text("Disconnect from HealthKit"),
                                        content: Text(
                                            "Are you sure you want to disconnect from HealthKit? Your health data will no longer sync."),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              "Disconnect",
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;

                                if (shouldDisconnect) {
                                  await healthKitProvider.disconnectHealthKit();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Successfully disconnected from HealthKit'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to disconnect from HealthKit: $e'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                  Divider(),
                  _buildSectionHeader('Notifications'),
                  SwitchListTile(
                      secondary: Icon(Icons.notifications),
                      title: Text('Enable Notifications'),
                      subtitle: Text('Receive health alerts and reminders'),
                      value: false,
                      onChanged: (value) {
                        // Logic haven't add hereeeee!!!!!
                      }),
                  Divider(),
                  _buildSectionHeader('Legal'),
                  ListTile(
                    leading: Icon(Icons.privacy_tip),
                    title: Text('Privacy Policy'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PrivacyPolicyScreen())),
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Log Out', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Log Out'),
                          content: Text('Do you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginScreen(
                                          healthService:
                                              healthKitProvider.healthService)),
                                  (route) => false,
                                );
                              },
                              child: Text(
                                'Log Out',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
