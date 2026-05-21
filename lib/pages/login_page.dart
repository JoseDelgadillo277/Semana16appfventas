import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool loading = false;
  bool hidePassword = true;

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on AuthException catch (error) {
      showMessage(error.message);
    } catch (_) {
      showMessage('No se pudo iniciar sesion. Revisa tu conexion o Supabase.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF007A3D);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _FalabellaLogo(),
                        const SizedBox(height: 8),
                        const Text(
                          'Banca movil para clientes',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electronico',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Ingrese su correo';
                            if (!email.contains('@')) {
                              return 'Ingrese un correo valido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          decoration: InputDecoration(
                            labelText: 'Contrasena',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => hidePassword = !hidePassword);
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) {
                              return 'Ingrese su contrasena';
                            }
                            if (password.length < 5) {
                              return 'La contrasena debe tener minimo 5 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: loading ? null : signIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: loading
                                  ? const _LoadingButtonContent()
                                  : const Text(
                                      key: ValueKey('loginText'),
                                      'Ingresar',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FalabellaLogo extends StatelessWidget {
  const _FalabellaLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 92,
            height: 78,
            child: CustomPaint(painter: _FalabellaMarkPainter()),
          ),
          const SizedBox(width: 12),
          Text(
            'Banco\nFalabella',
            style: TextStyle(
              height: 0.95,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FalabellaMarkPainter extends CustomPainter {
  const _FalabellaMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final greenPaint = Paint()..color = const Color(0xFF007A3D);
    final limePaint = Paint()..color = const Color(0xFFC7D900);
    final shadowPaint = Paint()..color = const Color(0x66004A25);

    canvas
      ..save()
      ..translate(size.width * 0.42, size.height * 0.64)
      ..rotate(-0.06)
      ..drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.98,
          height: size.height * 0.56,
        ),
        greenPaint,
      )
      ..restore()
      ..save()
      ..translate(size.width * 0.48, size.height * 0.28)
      ..rotate(0.35)
      ..drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.74,
          height: size.height * 0.42,
        ),
        limePaint,
      )
      ..restore()
      ..save()
      ..translate(size.width * 0.58, size.height * 0.47)
      ..rotate(0.25)
      ..drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.38,
          height: size.height * 0.24,
        ),
        shadowPaint,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoadingButtonContent extends StatelessWidget {
  const _LoadingButtonContent();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: ValueKey('loadingText'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.4,
          ),
        ),
        SizedBox(width: 12),
        Text(
          'Cargando...',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
