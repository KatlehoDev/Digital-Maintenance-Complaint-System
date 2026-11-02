import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  
  bool _loading = false;
  bool _obscure = true;
  String _selectedRole = 'hcm'; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedRole = _tabController.index == 0 ? 'hcm' : 'maintenance';
      });
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim().toLowerCase();
    
    if (_selectedRole == 'hcm' && !email.startsWith('hc')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('HCM email must start with "hc" (e.g., hcjohndoe@cut.ac.za)')));
      return;
    }
    if (_selectedRole == 'maintenance' && !email.startsWith('worker')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Worker email must start with "worker" (e.g., workerjohndoe@cut.ac.za)')));
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: _passCtrl.text,
        data: {
          'full_name': _nameCtrl.text.trim(),
          'role': _selectedRole, 
        },
      );

      if (response.user != null) {
        await Supabase.instance.client.auth.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // VERTICAL GRADIENT BACKGROUND
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A2665), // Dark Blue
              Color(0xFF4B5EAA), // Mid Blue
              Colors.white,      // White
            ],
            stops: [0.0, 0.4, 0.9],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // CUT Logo
                          Image.asset('assets/cut_logo.png', height: 60),
                          const SizedBox(height: 16),
                          const Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2A2665))),
                          const SizedBox(height: 24),
                          
                          // Custom Tabs
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey,
                              indicator: BoxDecoration(
                                color: const Color(0xFF2A2665),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'House Committee'),
                                Tab(text: 'Worker'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: _inputStyle('Full Name'),
                                  validator: (v) => v!.isEmpty ? 'Name required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputStyle(_selectedRole == 'hcm' ? 'Email (e.g. hcjohndoe@cut.ac.za)' : 'Email (e.g. workerjohndoe@cut.ac.za)'),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Email required';
                                    if (!v.contains('@cut.ac.za')) return 'Must be a @cut.ac.za email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) => v!.length < 6 ? 'Password must be 6+ characters' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPassCtrl,
                                  obscureText: _obscure,
                                  decoration: _inputStyle('Confirm Password'),
                                  validator: (v) => v!.isEmpty ? 'Please confirm password' : null,
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  height: 55,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2A2665), // Dark Blue
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _loading ? null : _register,
                                    child: _loading 
                                        ? const CircularProgressIndicator(color: Colors.white) 
                                        : const Text('Register Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Already have an account? Log In', style: TextStyle(color: Color(0xFF2A2665), fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      labelText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}