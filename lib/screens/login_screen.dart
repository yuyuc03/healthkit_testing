import 'package:flutter/material.dart';
import 'package:healthkit_integration_testing/models/user_profile.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import 'package:healthkit_integration_testing/services/health_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/register_screen.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../screens/home_screen.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  final HealthService healthService;
  const LoginScreen({Key? key, required this.healthService}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        final bool isAuthenticated =
            await verifyUserCredentials(email, password);

        if (isAuthenticated) {
          final userData = await getUserDataFromLogin(email);
          final userId = userData['userId'];
          final fullName = userData['fullName'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user_id', userId);
          await prefs.setString('user_full_name', fullName);

          print('Stored user ID in preferences: $userId');
          print('Stored user full name in preferences: $fullName');

          final UserProfile = await getUserProfile(userId);
          widget.healthService.startPeriodSync(userId, UserProfile);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          setState(() {
            _errorMessage = 'Invalid email or password';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Login failed: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final userProfileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);
      await userProfileProvider.loadUserProfile(userId);

      if (userProfileProvider.userProfile != null) {
        return userProfileProvider.userProfile!;
      }

      final UserProfile profile = await UserProfile.fromHealthKit(userId);

      await userProfileProvider.saveUserProfile(profile);

      return profile;
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Cannot get user profile: $e');
    }
  }

  Future<bool> verifyUserCredentials(String email, String password) async {
    mongo.Db? db;
    try {
      db = await mongo.Db.create(AppConfig.mongoUri);
      await db.open();

      final userCollection = db.collection('users');

      final user = await userCollection.findOne(mongo.where.eq('email', email));

      if (user == null) {
        return false;
      }

      final String hashedEnteredPassword = await _hashPassword(password);

      final String storedHashedPassword = user['password'];

      return storedHashedPassword == hashedEnteredPassword;
    } catch (e) {
      print('Error verifying credentials: $e');
      throw Exception('Failed to verify vredentials: $e');
    } finally {
      if (db != null && db.isConnected) {
        await db.close();
      }
    }
  }

  Future<Map<String, dynamic>> getUserDataFromLogin(String email) async {
    mongo.Db? db;
    try {
      db = await mongo.Db.create(AppConfig.mongoUri);
      await db.open();

      final userCollection = db.collection('users');
      final user = await userCollection.findOne(mongo.where.eq('email', email));

      if (user != null) {
        return {
          'userId': user['_id'].toString(),
          'fullName': user['fullName'] ?? 'User'
        };
      }
      throw Exception('User data not found');
    } catch (e) {
      print('Error getting user data: $e');
      throw Exception('Cannot get user data: $e');
    } finally {
      if (db != null && db.isConnected) {
        await db.close();
      }
    }
  }

  Future<String> _hashPassword(String password) async {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.health_and_safety_outlined,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Welcome Back!!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email address here";
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(
                        onPressed: () {},
                        icon: Icons.facebook,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildSocialButton(
                        onPressed: () {},
                        icon: Icons.g_mobiledata,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 16),
                      _buildSocialButton(
                        onPressed: () {},
                        icon: Icons.apple,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
