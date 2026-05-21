import 'package:bancofalabella_app2/services/scoring_repository.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.demoMode = false, this.userEmail});

  final bool demoMode;
  final String? userEmail;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final repository = ScoringRepository();
  late final Future<DashboardData> dashboardFuture;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    dashboardFuture = repository.loadDashboard(forceDemo: widget.demoMode);
  }

  Future<void> signOut() async {
    await repository.signOut();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF007A3D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text('Banco Falabella'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: widget.demoMode ? null : signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingDashboard();
          }

          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.cloud_off,
              title: 'No se pudo cargar Supabase',
              message: snapshot.error.toString(),
            );
          }

          final data = snapshot.data!;
          final pages = [
            _OverviewTab(data: data, userEmail: widget.userEmail),
            _ScoringTab(data: data),
            _FieldTab(data: data),
            _NetworkTab(data: data),
          ];

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: pages[selectedIndex],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: 'Scoring',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Campo',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Red',
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data, required this.userEmail});

  final DashboardData data;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    final profile = data.profile;
    final credit = data.credit;
    final score = data.score;
    final fullName =
        '${_text(profile, 'nombres', fallback: 'Cliente')} ${_text(profile, 'apellidos')}';

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.isDemo)
            const _Banner(
              icon: Icons.info_outline,
              text:
                  'Modo demo activo. Agrega SUPABASE_URL y SUPABASE_ANON_KEY para leer la BD real.',
            ),
          Text(
            'Hola, $fullName',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            userEmail ?? _text(profile, 'email', fallback: 'cliente Supabase'),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          _CreditHero(credit: credit, score: score),
          const SizedBox(height: 18),
          _SectionTitle('Perfil del negocio'),
          _InfoGrid(
            items: [
              _InfoItem(
                Icons.store,
                'Negocio',
                _text(profile, 'nombre_negocio'),
              ),
              _InfoItem(
                Icons.category,
                'Rubro',
                _text(profile, 'tipo_negocio'),
              ),
              _InfoItem(
                Icons.location_on,
                'Distrito',
                _text(profile, 'distrito'),
              ),
              _InfoItem(
                Icons.calendar_month,
                'Antiguedad',
                '${_number(profile, 'antiguedad_negocio_meses').toStringAsFixed(0)} meses',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle('KPIs piloto'),
          ...data.kpis.map((kpi) => _KpiTile(kpi: kpi)),
        ],
      ),
    );
  }
}

class _ScoringTab extends StatelessWidget {
  const _ScoringTab({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final score = data.score;
    final credit = data.credit;
    final scoreValue = _number(score, 'score_transaccional');
    final finalScore = _number(credit, 'score_final', fallback: scoreValue);

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Score transaccional'),
          _ScorePanel(
            score: scoreValue,
            segment: _text(score, 'segmento_preliminar', fallback: 'SIN SCORE'),
            amount: _number(score, 'monto_hipotesis'),
          ),
          const SizedBox(height: 16),
          _ScoreBreakdown(score: score),
          const SizedBox(height: 18),
          _SectionTitle('Credito preaprobado'),
          _InfoGrid(
            items: [
              _InfoItem(
                Icons.workspace_premium,
                'Segmento',
                _text(credit, 'segmento', fallback: 'Pendiente'),
              ),
              _InfoItem(
                Icons.scoreboard,
                'Score final',
                finalScore.toStringAsFixed(0),
              ),
              _InfoItem(
                Icons.payments,
                'Monto aprobado',
                _money(_number(credit, 'monto_aprobado')),
              ),
              _InfoItem(
                Icons.schedule,
                'Plazo',
                '${_number(credit, 'plazo_meses').toStringAsFixed(0)} meses',
              ),
              _InfoItem(
                Icons.receipt_long,
                'Cuota mensual',
                _money(_number(credit, 'cuota_mensual')),
              ),
              _InfoItem(
                Icons.verified,
                'Estado',
                _pretty(_text(credit, 'estado', fallback: 'sin estado')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldTab extends StatelessWidget {
  const _FieldTab({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final field = data.fieldFile;

    if (field.isEmpty) {
      return const _StateMessage(
        icon: Icons.assignment_late_outlined,
        title: 'Sin ficha de campo',
        message:
            'Cuando exista una visita, aqui se mostrara la evaluacion del asesor.',
      );
    }

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Ficha de visita'),
          _TimelineTile(
            icon: Icons.person_pin_circle,
            title: _text(field, 'asesor_nombre', fallback: 'Asesor'),
            subtitle: _text(field, 'agencia', fallback: 'Agencia'),
          ),
          _TimelineTile(
            icon: Icons.event_available,
            title: 'Fecha de visita',
            subtitle: _text(field, 'fecha_visita', fallback: 'Pendiente'),
          ),
          const SizedBox(height: 12),
          _InfoGrid(
            items: [
              _InfoItem(
                Icons.fact_check,
                'Negocio verificado',
                _boolText(field['negocio_verificado']),
              ),
              _InfoItem(
                Icons.trending_up,
                'Ventas mensuales',
                _money(_number(field, 'ventas_mensuales_est')),
              ),
              _InfoItem(
                Icons.account_balance_wallet,
                'Gastos fijos',
                _money(_number(field, 'gastos_fijos_mes')),
              ),
              _InfoItem(
                Icons.warning_amber,
                'Deuda informal',
                _pretty(_text(field, 'tiene_deuda_informal')),
              ),
              _InfoItem(
                Icons.inventory_2,
                'Stock visible',
                _pretty(_text(field, 'stock_visible')),
              ),
              _InfoItem(
                Icons.how_to_reg,
                'Comite',
                _pretty(_text(field, 'comite_resolucion')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkTab extends StatelessWidget {
  const _NetworkTab({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Agencias'),
          ...data.agencies.map((agency) => _AgencyTile(agency: agency)),
          const SizedBox(height: 18),
          _SectionTitle('Asesores de negocio'),
          ...data.advisors.map((advisor) => _AdvisorTile(advisor: advisor)),
        ],
      ),
    );
  }
}

class _CreditHero extends StatelessWidget {
  const _CreditHero({required this.credit, required this.score});

  final Map<String, dynamic> credit;
  final Map<String, dynamic> score;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF007A3D);
    final amount = _number(
      credit,
      'monto_aprobado',
      fallback: _number(score, 'monto_hipotesis'),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Credito preaprobado',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _money(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_pretty(_text(credit, 'estado', fallback: 'preaprobado'))} · ${_pretty(_text(credit, 'segmento', fallback: _text(score, 'segmento_preliminar')))}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.score,
    required this.segment,
    required this.amount,
  });

  final num score;
  final String segment;
  final num amount;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 800).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  segment,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                score.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF007A3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: const Color(0xFFE3EBE6),
          ),
          const SizedBox(height: 12),
          Text('Hipotesis de monto: ${_money(amount)}'),
        ],
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.score});

  final Map<String, dynamic> score;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Saldo', 'pts_saldo', 200),
      ('Regularidad', 'pts_regularidad', 160),
      ('Disciplina', 'pts_disciplina', 160),
      ('Vinculo', 'pts_vinculo', 160),
      ('Riesgo', 'pts_riesgo', 120),
    ];

    return Column(
      children: items.map((item) {
        final value = _number(score, item.$2);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _boxDecoration(),
          child: Row(
            children: [
              Expanded(child: Text(item.$1)),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  value: (value / item.$3).clamp(0, 1).toDouble(),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 42,
                child: Text(
                  value.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 680 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 680 ? 2.05 : 1.08,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: const Color(0xFF007A3D)),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    item.value.isEmpty ? '-' : item.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoItem {
  const _InfoItem(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _AgencyTile extends StatelessWidget {
  const _AgencyTile({required this.agency});

  final Map<String, dynamic> agency;

  @override
  Widget build(BuildContext context) {
    return _DataTile(
      icon: Icons.account_balance,
      title: _text(agency, 'nombre'),
      subtitle: '${_text(agency, 'codigo')} · ${_text(agency, 'region')}',
      trailing:
          '${_number(agency, 'total_asesores').toStringAsFixed(0)} asesores',
    );
  }
}

class _AdvisorTile extends StatelessWidget {
  const _AdvisorTile({required this.advisor});

  final Map<String, dynamic> advisor;

  @override
  Widget build(BuildContext context) {
    return _DataTile(
      icon: Icons.badge,
      title: _text(advisor, 'nombre_completo'),
      subtitle: '${_text(advisor, 'nivel')} · ${_text(advisor, 'agencia')}',
      trailing: '${_number(advisor, 'creditos_meta').toStringAsFixed(0)} metas',
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.kpi});

  final Map<String, dynamic> kpi;

  @override
  Widget build(BuildContext context) {
    return _DataTile(
      icon: Icons.analytics,
      title: _text(kpi, 'agencia', fallback: 'Piloto'),
      subtitle:
          '${_number(kpi, 'desembolsos').toStringAsFixed(0)} desembolsos · Mora 30: ${_number(kpi, 'mora_30_pct').toStringAsFixed(1)}%',
      trailing: '${_number(kpi, 'tasa_conversion_pct').toStringAsFixed(1)}%',
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _DataTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: '',
    );
  }
}

class _DataTile extends StatelessWidget {
  const _DataTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8F5E9),
            foregroundColor: const Color(0xFF007A3D),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '-' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          if (trailing.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(trailing, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

class _PagePadding extends StatelessWidget {
  const _PagePadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8A6200)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF007A3D)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

BoxDecoration _boxDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

String _text(Map<String, dynamic> row, String key, {String fallback = ''}) {
  final value = row[key];
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

num _number(Map<String, dynamic> row, String key, {num fallback = 0}) {
  final value = row[key];
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

String _money(num value) {
  return 'S/ ${value.toStringAsFixed(2)}';
}

String _pretty(String value) {
  if (value.isEmpty) return '-';
  return value.replaceAll('_', ' ').toUpperCase();
}

String _boolText(dynamic value) {
  if (value == true) return 'Si';
  if (value == false) return 'No';
  return '-';
}
