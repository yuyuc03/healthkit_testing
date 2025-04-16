import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B4B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Last updated: February 28, 2025',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1),
            _buildSection(
              'Overview',
              'This Privacy Policy describes how our app collects, uses, and discloses your personal information when you use our application. We are committed to protecting your privacy and handling your data with transparency.',
              Icons.info_outline,
            ),
            _buildSection(
              'Information We Collect',
              'We collect health data from HealthKit including steps, heart rate, blood pressure, blood glucose, blood oxygen, respiratory rate, exercise time, and other metrics you authorize. We also collect profile information you provide such as age, height, weight, lifestyle habits, and cultural information to provide personalized health insights.',
              Icons.data_usage,
            ),
            _buildSection(
              'How We Use Your Information',
              'Your health data is used only to provide the core functionality of our app, including health analysis and cardiovascular risk assessment. We process this data to generate health suggestions and provide personalized health guidance through our AI assistant.',
              Icons.psychology,
            ),
            _buildSection(
              'Data Storage and Security',
              'Your health data is stored securely in our database with appropriate safeguards. We implement technical and organizational measures to protect your personal information against unauthorized access, loss, or alteration.',
              Icons.security,
            ),
            _buildSection(
              'Data Sharing',
              'We do not sell your personal data to third parties. Your health information is only used within our application to provide services to you. We may share anonymized, aggregated data for research purposes, but this will never contain identifying information.',
              Icons.share,
            ),
            _buildSection(
              'Your Rights',
              'You have the right to access, modify, or delete your personal data. You can manage HealthKit connections through your profile settings, and you may request a copy of your data or deletion of your account at any time.',
              Icons.person_outline,
            ),
            _buildSection(
              'Children\'s Privacy',
              'Our service is not directed to children under 13, and we do not knowingly collect personal information from children under 13. If you are a parent and believe your child has provided us with personal information, please contact us.',
              Icons.child_care,
            ),
            _buildSection(
              'Changes to This Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
              Icons.update,
            ),
            _buildSection(
              'Contact Us',
              'If you have questions about this Privacy Policy or our practices, please contact us at privacy@smartcare.com.',
              Icons.mail_outline,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFF6F6FE),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.deepPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B4B),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
