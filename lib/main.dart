import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

/* =========================
   APP ROOT
   ========================= */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1115),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1D24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),
      home: const StartPage(),
    );
  }
}

/* =========================
   START PAGE
   ========================= */

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Password Manager'), // or Register / Set Password
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 96,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Securely access your vault',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),

              // LOGIN BUTTON
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text(
                  'Login',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),

              const SizedBox(height: 16),

              // REGISTER BUTTON
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterUsernamePage(),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================
   LOGIN PAGE
   ========================= */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String _error = '';

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();
      final password = _passwordController.text;

      final salt = await _authService.getAuthSalt(username);
      if (salt == null) throw Exception('User does not exist');

      final token = await _authService.login(username, password);
      if (token == null) throw Exception('Invalid password');

      final vault = await _authService.getVault(token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VaultPage(
            token: token,
            password: password,
            vaultResponse: vault,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Login'), // or Register / Set Password
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: const Text('Login'),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

/* =========================
   REGISTER – STEP 1
   ========================= */

class RegisterUsernamePage extends StatefulWidget {
  const RegisterUsernamePage({super.key});

  @override
  State<RegisterUsernamePage> createState() => _RegisterUsernamePageState();
}

class _RegisterUsernamePageState extends State<RegisterUsernamePage> {
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
      final salt = await _authService.getAuthSalt(username);
      if (salt != null) throw Exception('Username already exists');

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterPasswordPage(username: username),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Register'), // or Register / Set Password
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Choose a username'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _next,
              child: const Text('Next'),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

/* =========================
   REGISTER – STEP 2
   ========================= */

class RegisterPasswordPage extends StatefulWidget {
  final String username;

  const RegisterPasswordPage({super.key, required this.username});

  @override
  State<RegisterPasswordPage> createState() => _RegisterPasswordPageState();
}

class _RegisterPasswordPageState extends State<RegisterPasswordPage> {
  final _authService = AuthService();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String _error = '';

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final password = _passwordController.text;

      await _authService.register(widget.username, password);
      final token = await _authService.login(widget.username, password);
      if (token == null) throw Exception('Login failed');

      final vault = await _authService.getVault(token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VaultPage(
            token: token,
            password: password,
            vaultResponse: vault,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Set Password'), // or Register / Set Password
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Username: ${widget.username}'),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: const Text('Register'),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

/* =========================
   VAULT PAGE (FULL UI)
   ========================= */

class VaultPage extends StatefulWidget {
  final String token;
  final String password;
  final Map<String, dynamic> vaultResponse;

  const VaultPage({
    super.key,
    required this.token,
    required this.password,
    required this.vaultResponse,
  });

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final _authService = AuthService();
  Map<String, String> _vaultItems = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    final blob = widget.vaultResponse['blob'];
    if (blob == null) return;

    final decrypted = await _authService.decryptVault(
      Map<String, dynamic>.from(blob),
      widget.password,
    );

    setState(() {
      _vaultItems = Map<String, String>.from(decrypted);
    });
  }

  Future<void> _saveVault() async {
    setState(() => _loading = true);

    final encrypted =
        await _authService.encryptVault(_vaultItems, widget.password);
    await _authService.updateVault(widget.token, encrypted);

    setState(() => _loading = false);
  }

  void _addItem() {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: valCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _vaultItems[keyCtrl.text] = valCtrl.text;
              });
              Navigator.pop(context);
              _saveVault();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editItem(String key, String currentValue) {
    final valCtrl = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $key'),
        content: TextField(
          controller: valCtrl,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _vaultItems[key] = valCtrl.text;
              });
              Navigator.pop(context);
              _saveVault();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(String key) {
    setState(() {
      _vaultItems.remove(key);
    });
    _saveVault();
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const StartPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: _vaultItems.isEmpty
          ? const Center(child: Text('Your vault is empty'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _vaultItems.entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text(entry.key),
                    subtitle: const Text('••••••••'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copy(entry.value),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editItem(entry.key, entry.value),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(entry.key),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
