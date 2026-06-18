import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../services/patient_link_service.dart';
import '../localization.dart';
import '../widgets/language_selector.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _cgEmailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _role = 'patient';
  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  Future<void> _register() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final email = PatientLinkService.normalizeEmail(_emailCtrl.text);
      final password = _passCtrl.text.trim();
      if (email.isEmpty || password.isEmpty)
        throw Exception('Email and password are required.');

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      final uid = cred.user!.uid;

      final userData = {
        'email': email,
        'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_role == 'patient') {
        final cgEmail = PatientLinkService.normalizeEmail(_cgEmailCtrl.text);
        if (cgEmail.isEmpty)
          throw Exception('Please enter your caregiver\'s email.');
        if (_nameCtrl.text.trim().isEmpty)
          throw Exception('Please enter your name.');
        if (_ageCtrl.text.trim().isEmpty)
          throw Exception('Please enter your age.');
        userData['caregiverEmail'] = cgEmail;
        userData['name'] = _nameCtrl.text.trim();
        userData['age'] = int.tryParse(_ageCtrl.text.trim()) ?? 0;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData);

        final cgSnap = await FirebaseFirestore.instance
            .collection('caregiver_registry')
            .doc(cgEmail)
            .get()
            .timeout(const Duration(seconds: 20));

        if (!cgSnap.exists) {
          await cred.user!.delete();
          throw Exception(
            'Caregiver "$cgEmail" not found. Ask them to register first.',
          );
        }
        final cgUid = cgSnap.data()?['uid'] as String?;
        if (cgUid == null) {
          await cred.user!.delete();
          throw Exception('Invalid caregiver data.');
        }

        await PatientLinkService.linkPatientToCaregiver(
          patientUid: uid,
          patientEmail: email,
          caregiverUid: cgUid,
        );
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData);
        await FirebaseFirestore.instance
            .collection('caregiver_registry')
            .doc(email)
            .set({
              'uid': uid,
              'email': email,
              'registeredAt': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _role == 'patient'
                  ? 'Account created! You are linked to your caregiver.'
                  : 'Account created! Please sign in.',
            ),
            backgroundColor: NenaviTheme.secondary,
          ),
        );
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
    return ValueListenableBuilder<String>(
      valueListenable: globalLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: NenaviTheme.background,
          appBar: AppBar(
            title: Text(Localization.get('register_title', lang)),
            leading: const BackButton(),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
                child: LanguageSelector(),
              ),
            ],
          ),
          body: NenaviPage(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ───────────────────────────────────────────────
                Text(
                  Localization.get('welcome_nenavi', lang),
                  style: NenaviTheme.heading(color: NenaviTheme.accent),
                ),
                const SizedBox(height: 6),
                Text(
                  Localization.get('fill_details', lang),
                  style: NenaviTheme.body(color: NenaviTheme.secondary),
                ),
                const SizedBox(height: 32),

                // ── Email ─────────────────────────────────────────────────
                Text(
                  Localization.get('email', lang),
                  style: NenaviTheme.label(),
                ),
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
                Text(
                  Localization.get('password', lang),
                  style: NenaviTheme.label(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: NenaviTheme.body(),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Role ──────────────────────────────────────────────────
                Text(
                  Localization.get('role_question', lang),
                  style: NenaviTheme.label(),
                ),
                const SizedBox(height: 8),
                _RoleSelector(
                  value: _role,
                  lang: lang,
                  onChanged: (v) => setState(() => _role = v),
                ),
                const SizedBox(height: 20),

                // ── Patient Only Fields ───────────────────────────────────
                if (_role == 'patient') ...[
                  Text(
                    Localization.get('name', lang),
                    style: NenaviTheme.label(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: NenaviTheme.body(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    Localization.get('age', lang),
                    style: NenaviTheme.label(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    style: NenaviTheme.body(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    Localization.get('caregiver_email', lang),
                    style: NenaviTheme.label(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cgEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: NenaviTheme.body(),
                    decoration: const InputDecoration(
                      hintText: 'caregiver@email.com',
                      prefixIcon: Icon(Icons.favorite_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_error.isNotEmpty) NenaviError(_error),

                // ── Submit ────────────────────────────────────────────────
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        child: Text(Localization.get('create_account', lang)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NenaviTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      Localization.get('already_have_account', lang),
                      style: NenaviTheme.body(color: NenaviTheme.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Big tap-friendly role selector
class _RoleSelector extends StatelessWidget {
  final String value;
  final String lang;
  final ValueChanged<String> onChanged;
  const _RoleSelector({
    required this.value,
    required this.lang,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleTile(
            label: Localization.get('patient', lang),
            icon: Icons.person,
            selected: value == 'patient',
            onTap: () => onChanged('patient'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleTile(
            label: Localization.get('caregiver', lang),
            icon: Icons.medical_services_outlined,
            selected: value == 'caregiver',
            onTap: () => onChanged('caregiver'),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? NenaviTheme.primary
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? NenaviTheme.primary
                : NenaviTheme.secondary.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: selected ? Colors.white : NenaviTheme.accent,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: NenaviTheme.body(
                color: selected ? Colors.white : NenaviTheme.accent,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
