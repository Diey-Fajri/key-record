import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class SetupAccountScreen extends StatefulWidget {
  const SetupAccountScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<SetupAccountScreen> createState() => _SetupAccountScreenState();
}

class _SetupAccountScreenState extends State<SetupAccountScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _isExistingAccount = false;
  String? _existingUsername;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail.isNotEmpty) {
      _emailController.text = widget.initialEmail;
      _loadExistingAccount(widget.initialEmail);
    }
  }

  Future<void> _loadExistingAccount(String email) async {
    final profile = await AuthService.getUserProfileByEmail(email);
    if (!mounted) return;

    final username = (profile?['username'] as String?)?.trim();
    setState(() {
      _isExistingAccount = username != null && username.isNotEmpty;
      _existingUsername = username;
      if (_isExistingAccount && username != null) {
        _usernameController.text = username;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Account Setup'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Icon(Icons.person_add_alt_1_outlined, size: 92, color: Color(0xFF263238)),
                  const SizedBox(height: 16),
                  Text(
                    _isExistingAccount
                        ? 'Welcome Back, ${_existingUsername ?? 'Member'}!'
                        : 'Set Your Admin Account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isExistingAccount
                        ? 'Please enter your 6-digit password to continue.'
                        : 'If your account already exists, enter your 6-digit password to sign in. New accounts are only allowed for approved member emails.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 28),
                  if (!_isExistingAccount)
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Member username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: !_isExistingAccount,
                    decoration: InputDecoration(
                      labelText: 'Approved member email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      labelText: '6-digit password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() {
                          _passwordVisible = !_passwordVisible;
                        }),
                      ),
                    ),
                    textInputAction: _isExistingAccount ? TextInputAction.done : TextInputAction.next,
                    onSubmitted: _isExistingAccount ? (_) => _createAccount() : null,
                  ),
                  if (!_isExistingAccount) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmController,
                      obscureText: !_confirmVisible,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Confirm 6-digit password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_confirmVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() {
                            _confirmVisible = !_confirmVisible;
                          }),
                        ),
                      ),
                      onSubmitted: (_) => _createAccount(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  if (_errorMessage != null) const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isLoading ? null : _createAccount,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF263238),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = _isExistingAccount
            ? 'Please enter your 6-digit password.'
            : 'Username, approved email, and a password are required.';
      });
      return;
    }

    if (!AuthService.isPasswordStrong(password)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a 6-digit numeric password.';
      });
      return;
    }

    if (!_isExistingAccount) {
      if (username.isEmpty || confirmPassword.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Username, approved email, and a password are required.';
        });
        return;
      }

      if (password != confirmPassword) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Passwords do not match.';
        });
        return;
      }
    }

    final accountUsername = _isExistingAccount ? (_existingUsername ?? username) : username;
    await AuthService.createUser(username: accountUsername, password: password, email: email);
    if (!mounted) return;

    if (AuthService.lastErrorMessage != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = AuthService.lastErrorMessage;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Welcome back! Your account is ready.')),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }
}
