import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool mostrarContenido = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          mostrarContenido = true;
        });
      }
    });
  }

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    const verdeFalabella = Color(0xFF007A3D);

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: verdeFalabella,
        foregroundColor: Colors.white,
        title: const Text('Banco Falabella'),
        actions: [
          IconButton(
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
        child: mostrarContenido
            ? _DashboardEntry(
                key: const ValueKey('dashboardContent'),
                userEmail: user?.email,
              )
            : const _DashboardSkeleton(
                key: ValueKey('dashboardSkeleton'),
              ),
      ),
    );
  }
}

class _DashboardEntry extends StatelessWidget {
  final String? userEmail;

  const _DashboardEntry({
    super.key,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _DashboardContent(userEmail: userEmail),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final String? userEmail;

  const _DashboardContent({
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    const verdeFalabella = Color(0xFF007A3D);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, ${userEmail ?? 'cliente'}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: verdeFalabella,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo disponible',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'S/ 3,250.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Cuenta Sueldo Banco Falabella',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Operaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: const [
              _MenuCard(
                icon: Icons.savings,
                title: 'Ahorros',
                subtitle: 'Ver cuentas',
              ),
              _MenuCard(
                icon: Icons.credit_card,
                title: 'Créditos',
                subtitle: 'Préstamos activos',
              ),
              _MenuCard(
                icon: Icons.swap_horiz,
                title: 'Transferencias',
                subtitle: 'Enviar dinero',
              ),
              _MenuCard(
                icon: Icons.person,
                title: 'Perfil',
                subtitle: 'Datos del cliente',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Últimos movimientos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const _MovimientoItem(
            titulo: 'Pago con tarjeta',
            fecha: 'Tottus - 12 mayo',
            monto: '- S/ 85.90',
          ),
          const _MovimientoItem(
            titulo: 'Depósito recibido',
            fecha: 'Transferencia - 11 mayo',
            monto: '+ S/ 500.00',
          ),
          const _MovimientoItem(
            titulo: 'Pago de servicio',
            fecha: 'Luz del Sur - 10 mayo',
            monto: '- S/ 120.30',
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShimmerBox(width: 210, height: 28, radius: 8),
          const SizedBox(height: 18),
          const _ShimmerBox(width: double.infinity, height: 142, radius: 24),
          const SizedBox(height: 24),
          const _ShimmerBox(width: 130, height: 26, radius: 8),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: const [
              _ShimmerBox(width: double.infinity, height: 130, radius: 22),
              _ShimmerBox(width: double.infinity, height: 130, radius: 22),
              _ShimmerBox(width: double.infinity, height: 130, radius: 22),
              _ShimmerBox(width: double.infinity, height: 130, radius: 22),
            ],
          ),
          const SizedBox(height: 24),
          const _ShimmerBox(width: 190, height: 26, radius: 8),
          const SizedBox(height: 12),
          const _MovimientoSkeleton(),
          const _MovimientoSkeleton(),
          const _MovimientoSkeleton(),
        ],
      ),
    );
  }
}

class _MovimientoSkeleton extends StatelessWidget {
  const _MovimientoSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          _ShimmerBox(width: 42, height: 42, radius: 21),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                _ShimmerBox(width: 130, height: 14, radius: 7),
              ],
            ),
          ),
          SizedBox(width: 18),
          _ShimmerBox(width: 76, height: 18, radius: 9),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + controller.value * 3, -0.2),
              end: Alignment(-0.5 + controller.value * 3, 0.2),
              colors: const [
                Color(0xFFE2E8EC),
                Color(0xFFF7FAFC),
                Color(0xFFE2E8EC),
              ],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const verdeFalabella = Color(0xFF007A3D);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: verdeFalabella,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovimientoItem extends StatelessWidget {
  final String titulo;
  final String fecha;
  final String monto;

  const _MovimientoItem({
    required this.titulo,
    required this.fecha,
    required this.monto,
  });

  @override
  Widget build(BuildContext context) {
    final bool esIngreso = monto.startsWith('+');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: esIngreso
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.15),
          child: Icon(
            esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
            color: esIngreso ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(fecha),
        trailing: Text(
          monto,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: esIngreso ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
