import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDetailsPage extends StatefulWidget {
  final String userEmail;

  const UserDetailsPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  late final String apiUrl;
  final String profileImageUrl = 'https://picsum.photos/150/150';
  final String maleProfileImage = 'https://randomuser.me/api/portraits/men/1.jpg';
  final String femaleProfileImage = 'https://randomuser.me/api/portraits/women/1.jpg';
  final String defaultProfileImage = 'https://randomuser.me/api/portraits/lego/1.jpg';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isImageLoading = true;
  bool _showPassword = false; // Add this for password visibility toggle
  String _errorMessage = '';
  String _userId = '';
  String _actualPassword = ''; // Store the actual password
String _displayedPassword = '••••••••';
String get _profileImage {
    switch (_genderController.text.toLowerCase()) {
      case 'male':
        return maleProfileImage;
      case 'female':
        return femaleProfileImage;
      default:
        return defaultProfileImage;
    }
  }
  @override
  void initState() {
    super.initState();
    apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:5002';
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('$apiUrl/api/users/email/${widget.userEmail}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _genderController.text = userData['gender']?.toLowerCase() ?? 'other';
          _addressController.text = userData['address'] ?? '';
          _emailController.text = userData['email'] ?? widget.userEmail;
          _actualPassword = userData['password'] ?? '';
          _displayedPassword = '••••••••';
          _userId = userData['_id'] ?? '';
          _isLoading = false;
          _showPassword = false;
          _isImageLoading = false;
        });
      } else {
        throw Exception('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data. Please try again later.';
        _isLoading = false;
      });
      debugPrint('Error fetching user details: $e');
    }
  }
  Future<void> _saveUserDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await http.put(
        Uri.parse('$apiUrl/api/users/$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'gender': _genderController.text,
          'address': _addressController.text,
        }),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() => _isEditing = false);
        await _fetchUserDetails();
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile. Please try again.';
      });
      debugPrint('Error updating user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Do you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: TextEditingController(text: _showPassword ? _actualPassword : '••••••••'),
        obscureText: !_showPassword,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.deepPurple,
            ),
            onPressed: _togglePasswordVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        enabled: false,
        style: GoogleFonts.montserrat(),
      ),
    );
  }
void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
      _passwordController.text = _showPassword ? _actualPassword : '••••••••';
    });
  }
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isEditable = true,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        obscureText: obscureText,
        enabled: isEditable && _isEditing,
        style: GoogleFonts.montserrat(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.9),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'web/logo1.png',
                          height: 50,
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: _showLogoutDialog,
                        ),
                      ],
                    ),
                  ),
                  
                  // Profile Section with gender-specific image
                  Container(
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFb993d6), Color(0xFF8ca6db)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(_profileImage),
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint('Error loading profile image: $exception');
                          setState(() {
                            _isImageLoading = false;
                          });
                        },
                        child: _isImageLoading
                            ? const CircularProgressIndicator()
                            : (_isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                                    onPressed: () {
                                      // TODO: Implement image picker
                                    },
                                  )
                                : null),
                      ),
                    ),
                  ),
                  
                  // Form Section
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              _errorMessage,
                              style: GoogleFonts.montserrat(color: Colors.red),
                            ),
                          ),
                        
                        _buildEditableField(
                          label: 'Name',
                          controller: _nameController,
                          icon: Icons.person,
                        ),
                        
                        _buildEditableField(
                          label: 'Gender',
                          controller: _genderController,
                          icon: Icons.transgender,
                        ),
                        
                        _buildEditableField(
                          label: 'Address',
                          controller: _addressController,
                          icon: Icons.home,
                        ),
                        
                        _buildEditableField(
                          label: 'Email',
                          controller: _emailController,
                          icon: Icons.email,
                          isEditable: false,
                        ),
                        
                        _buildPasswordField(),
                        
                        const SizedBox(height: 20),
                        if (_isEditing)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _showPassword = false;
                                  });
                                  _fetchUserDetails();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                ),
                                child: Text('Cancel', style: GoogleFonts.montserrat()),
                              ),
                              ElevatedButton(
                                onPressed: _saveUserDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 238, 237, 240),
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                ),
                                child: Text('Save', style: GoogleFonts.montserrat()),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            onPressed: () => setState(() => _isEditing = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 240, 238, 242),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            ),
                            child: Text('Edit Profile', style: GoogleFonts.montserrat()),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}