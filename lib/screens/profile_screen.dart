import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/healthkit_provider.dart';
import './profile_edit_screen.dart';
import './privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final healthKitProvider = Provider.of<HealthKitProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
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
                    'Hello, Yuyu!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('yuyu123456@gmail.com',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),

            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Section
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
                  Divider(),

                  // Health Data Section
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
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                      AlertDialog(
                                          title:
                                              Text("Disconnect from HealthKit"),
                                          content: Text(
                                              "To disconnect from HealthKit, go to system settings."),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text("OK"))
                                          ]));
                            }
                          }),

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
                                Navigator.pop(context);
                                // Logic haven't add hereeeeee
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
