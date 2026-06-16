import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _cgEmailCtrl  = TextEditingController();
  String _role = 'patient';
  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  Future<void> _register() async {
    if (_loading) return;
    setState(() { _loading = true; _error = ''; });

    try {
      final email    = _emailCtrl.text.trim();
      final password = _passCtrl.text.trim();
      if (email.isEmpty || password.isEmpty) throw Exception('Email and password are required.');

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      final uid = cred.user!.uid;

      final userData = {
        'email': email, 'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_role == 'patient') {
        final cgEmail = _cgEmailCtrl.text.trim();
        if (cgEmail.isEmpty) throw Exception('Please enter your caregiver\'s email.');
        userData['caregiverEmail'] = cgEmail;

        await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

        final cgSnap = await FirebaseFirestore.instance
            .collection('caregiver_registry').doc(cgEmail).get()
            .timeout(const Duration(seconds: 20));

        if (!cgSnap.exists) {
          await cred.user!.delete();
          throw Exception('Caregiver "$cgEmail" not found. Ask them to register first.');
        }
        final cgUid = cgSnap.data()?['uid'] as String?;
        if (cgUid == null) { await cred.user!.delete(); throw Exception('Invalid caregiver data.'); }

        await FirebaseFirestore.instance.collection('pending_patient_links').doc(uid).set({
          'patientUid': uid, 'patientEmail': email,
          'caregiverUid': cgUid, 'caregiverEmail': cgEmail,
          'linkedAt': FieldValue.serverTimestamp(), 'status': 'pending',
        });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
        await FirebaseFirestore.instance.collection('caregiver_registry').doc(email).set({
          'uid': uid, 'email': email,
          'registeredAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_role == 'patient'
              ? 'Account created! You are linked to your caregiver.'
              : 'Account created! Please sign in.'),
          backgroundColor: NenaviTheme.secondary,
        ));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Registration failed.');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NenaviTheme.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: const BackButton(),
      ),
      body: NenaviPage(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────
            Text('Welcome to Nenavi',
                style: NenaviTheme.heading(color: NenaviTheme.accent)),
            const SizedBox(height: 6),
            Text('Fill in the details below to get started.',
                style: NenaviTheme.body(color: NenaviTheme.secondary)),
            const SizedBox(height: 32),

            // ── Email ─────────────────────────────────────────────────
            Text('Your Email', style: NenaviTheme.label()),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: NenaviTheme.body(),
              decoration: const InputDecoration(
                hintText: 'your@email.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 20),

            // ── Password ──────────────────────────────────────────────
            Text('Password', style: NenaviTheme.label()),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: NenaviTheme.body(),
              decoration: InputDecoration(
                hintText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Role ──────────────────────────────────────────────────
            Text('I am a…', style: NenaviTheme.label()),
            const SizedBox(height: 8),
            _RoleSelector(
              value: _role,
              onChanged: (v) => setState(() => _role = v),
            ),
            const SizedBox(height: 20),

            // ── Caregiver email (patient only) ────────────────────────
            if (_role == 'patient') ...[
              Text('Caregiver\'s Email', style: NenaviTheme.label()),
              const SizedBox(height: 8),
              TextField(
                controller: _cgEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: NenaviTheme.body(),
                decoration: const InputDecoration(
                  hintText: 'caregiver@email.com',
                  prefixIcon: Icon(Icons.favorite_outline),
                  helperText: 'Your caregiver must have an account first',
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_error.isNotEmpty) NenaviError(_error),

            // ── Submit ────────────────────────────────────────────────
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _register,
                    icon: const Icon(Icons.person_add_alt_1, size: 24),
                    label: const Text('Create Account'),
                  ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Sign in'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Big tap-friendly role selector
class _RoleSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RoleSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _RoleTile(
        label: 'Patient',
        icon: Icons.person,
        selected: value == 'patient',
        onTap: () => onChanged('patient'),
      )),
      const SizedBox(width: 12),
      Expanded(child: _RoleTile(
        label: 'Caregiver',
        icon: Icons.medical_services_outlined,
        selected: value == 'caregiver',
        onTap: () => onChanged('caregiver'),
      )),
    ]);
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? NenaviTheme.primary : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? NenaviTheme.primary : NenaviTheme.secondary.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Column(children: [
          Icon(icon, size: 32,
              color: selected ? Colors.white : NenaviTheme.accent),
          const SizedBox(height: 6),
          Text(label,
              style: NenaviTheme.body(
                  color: selected ? Colors.white : NenaviTheme.accent)
                  .copyWith(fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
