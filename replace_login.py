import sys

with open('lib/main.dart', 'r') as f:
    content = f.read()

start_str = """class LoginPage extends StatefulWidget {"""
end_str = """}

/* =========================
   REGISTER – STEP 1
   ========================= */"""


if start_str not in content:
    print("Start string not found")
    sys.exit(1)

start_idx = content.find(start_str)
end_idx = content.find(end_str, start_idx)

if end_idx == -1:
    print("End string not found")
    sys.exit(1)

# Include the closing brace of the class
end_idx += 1

new_content = """class LoginUsernamePage extends StatefulWidget {
  const LoginUsernamePage({super.key});

  @override
  State<LoginUsernamePage> createState() => _LoginUsernamePageState();
}

class _LoginUsernamePageState extends State<LoginUsernamePage> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();

  bool _loading = false;
  String _error = '';

  Future<void> _next() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();

      if (username.isEmpty) {
        throw Exception('Please enter your username');
      }

      final salt = await _authService.getAuthSalt(username);
      if (salt == null) {
        throw Exception('User not found. Please check your username.');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPasswordPage(username: username),
        ),
      );
    } catch (e) {
      if (e is RateLimitException) {
        if (!mounted) return;
        _showSecurityAlert(e.message);
      } else {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showSecurityAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.gpp_bad_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Security Alert'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () => settings.toggleTheme(),
                tooltip: settings.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            const AppHeroTitle(
              title: 'Welcome Back',
              subtitle: 'Enter your username',
              icon: Icons.person_rounded,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 200),
              child: Semantics(
                label: 'Username input field',
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _loading ? null : _next(),
                  enabled: !_loading,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 330),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _next,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Next'),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _error.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FadeIn(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   LOGIN – STEP 2
   ========================= */

class LoginPasswordPage extends StatefulWidget {
  final String username;
  const LoginPasswordPage({super.key, required this.username});

  @override
  State<LoginPasswordPage> createState() => _LoginPasswordPageState();
}

class _LoginPasswordPageState extends State<LoginPasswordPage> {
  final _localAuthService = LocalAuthService();
  final _authService = AuthService();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String _error = '';
  bool _hasCredentials = false;
  Map<String, String>? _storedCredentials;

  @override
  void initState() {
    super.initState();
    _checkCredentials();
  }

  Future<void> _checkCredentials() async {
    final creds = await _localAuthService.getCredentials(widget.username);
    if (creds != null && creds['username'] == widget.username && mounted) {
      setState(() {
        _hasCredentials = true;
        _storedCredentials = creds;
      });
    }
  }

  Future<void> _loginWithPasskey() async {
    if (_storedCredentials == null) return;
    
    final authenticated = await _localAuthService.authenticate(
      reason: 'Please authenticate to log in with passkey',
    );
    
    if (authenticated) {
      _passwordController.text = _storedCredentials!['password']!;
      await _login();
    }
  }

  void _showSecurityAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.gpp_bad_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Security Alert'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final password = _passwordController.text;

      if (password.isEmpty) {
        throw Exception('Please enter your password');
      }

      final token = await _authService.login(widget.username, password);
      if (token == null) {
        throw Exception('Incorrect password. Please try again.');
      }

      final mfaEnabled = await _authService.checkMfaStatus(widget.username);

      if (!mounted) return;

      if (mfaEnabled) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MfaVerifyPage(
              username: widget.username,
              password: password,
            ),
          ),
        );
      } else {
        final vault = await _authService.getVault(token);
        await _localAuthService.saveCredentials(widget.username, password);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => VaultPage(
              username: widget.username,
              token: token,
              password: password,
              vaultResponse: vault,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (e is RateLimitException) {
        if (!mounted) return;
        _showSecurityAlert(e.message);
      } else {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () => settings.toggleTheme(),
                tooltip: settings.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            AppHeroTitle(
              title: 'Master Password',
              subtitle: 'Welcome back, ${widget.username}',
              icon: Icons.lock_outline_rounded,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 200),
              child: Semantics(
                label: 'Password input field',
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _login(),
                  enabled: !_loading,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.035),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 330),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Login'),
                ),
              ),
            ),
            if (_hasCredentials) ...[
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 460),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Login with Passkey'),
                    onPressed: _loading ? null : _loginWithPasskey,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _error.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FadeIn(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}"""

final_content = content[:start_idx] + new_content + content[end_idx:]

with open('lib/main.dart', 'w') as f:
    f.write(final_content)

print(f"Replaced {end_idx - start_idx} chars.")
