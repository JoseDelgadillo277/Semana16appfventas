import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool cargando = false;
  bool ocultarPassword = true;

  Future<void> iniciarSesion() async {
    if (!formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      cargando = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión.';

      if (e.code == 'user-not-found') {
        mensaje = 'No existe un usuario con ese correo en Firebase.';
      } else if (e.code == 'wrong-password') {
        mensaje = 'La contraseña es incorrecta.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo ingresado no es válido.';
      } else if (e.code == 'invalid-credential') {
        mensaje = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'too-many-requests') {
        mensaje = 'Demasiados intentos. Inténtalo más tarde.';
      }

      mostrarMensaje(mensaje);
    } catch (e) {
      mostrarMensaje('Ocurrió un error inesperado.');
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
      ),
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
    const verdeFalabella = Color(0xFF007A3D);
    const verdeClaro = Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: verdeClaro,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                      const SizedBox(height: 6),
                      const Text(
                        'Banca móvil para clientes',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese su correo';
                          }
                          if (!value.contains('@')) {
                            return 'Ingrese un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: ocultarPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              ocultarPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                ocultarPassword = !ocultarPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese su contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: cargando ? null : iniciarSesion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: verdeFalabella,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: cargando
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
            child: CustomPaint(
              painter: _FalabellaMarkPainter(),
            ),
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

    canvas.save();
    canvas.translate(size.width * 0.42, size.height * 0.64);
    canvas.rotate(-0.06);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.98,
        height: size.height * 0.56,
      ),
      greenPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.48, size.height * 0.28);
    canvas.rotate(0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.74,
        height: size.height * 0.42,
      ),
      limePaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.58, size.height * 0.47);
    canvas.rotate(0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.38,
        height: size.height * 0.24,
      ),
      shadowPaint,
    );
    canvas.restore();
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
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
