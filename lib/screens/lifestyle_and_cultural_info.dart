import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';

class LifestyleAndCulturalInfo extends StatefulWidget {
  @override
  State<LifestyleAndCulturalInfo> createState() =>
      _LifestyleAndCulturalInfoState();
}

class _LifestyleAndCulturalInfoState extends State<LifestyleAndCulturalInfo> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _userId = '';

  TextEditingController ethnicityController = TextEditingController();
  TextEditingController countryOfOriginController = TextEditingController();
  TextEditingController religiousIdentityController = TextEditingController();
  TextEditingController dietaryHabitsController = TextEditingController();
  TextEditingController currentMedicationsController = TextEditingController();
  TextEditingController culturalIdentityController = TextEditingController();
  bool _familyHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserId();
    });
  }

  void _initializeUserId() {
    final userProfile = Provider.of<UserProfileProvider>(context, listen: false).userProfile;
    if (userProfile != null) {
      setState(() {
        _userId = userProfile.userId;
      });
    } else {
      print('Warning: User profile is null');
    }
  }

  Future<void> insertGptData() async {
    final db = await mongo.Db.create(
        "mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics");
    try {
      await db.open();
      final collection = db.collection('gpt_data');

      final data = {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'user_id': _userId, 
        'ethnicity': ethnicityController.text,
        'country_of_origin': countryOfOriginController.text,
        'religious_identity': religiousIdentityController.text,
        'dietary_habits': dietaryHabitsController.text,
        'current_medications': currentMedicationsController.text,
        'cultural_identity': culturalIdentityController.text,
        'family_history': _familyHistory,
      };

      await collection.insert(data);
    } catch (e) {
      print('Error inserting data: $e');
      throw e;
    } finally {
      await db.close();
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await insertGptData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data submitted successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting data: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lifestyle and Cultural Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTextField('Ethnicity', ethnicityController),
                _buildTextField('Country of Origin', countryOfOriginController),
                _buildTextField(
                    'Religious Identity', religiousIdentityController),
                _buildTextField('Dietary Habits', dietaryHabitsController),
                _buildTextField(
                    'Current Medications', currentMedicationsController),
                _buildTextField('Cultural Identity', culturalIdentityController,
                    maxLines: 3),
                SwitchListTile(
                  title:
                      Text("Do you have any family history of heart disease?"),
                  value: _familyHistory,
                  onChanged: (value) {
                    setState(() {
                      _familyHistory = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Enter your $label here',
            hintStyle: TextStyle(fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding:
                EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
