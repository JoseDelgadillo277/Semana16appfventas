import 'package:bancofalabella_app2/services/scoring_repository.dart';
import 'package:flutter/material.dart';

class _AppColors {
  static const green = Color(0xFF007A3D);
  static const deepGreen = Color(0xFF005B2E);
  static const lime = Color(0xFFC7D900);
  static const blue = Color(0xFF2563EB);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFDC2626);
  static const teal = Color(0xFF0F766E);
  static const purple = Color(0xFF7C3AED);
  static const background = Color(0xFFF2F6F3);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.demoMode = false, this.userEmail});

  final bool demoMode;
  final String? userEmail;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final repository = ScoringRepository();
  late Future<SalesDashboardData> dashboardFuture;
  int selectedIndex = 0;
  int selectedClientIndex = 0;
  String segmentFilter = 'TODOS';
  String statusFilter = 'TODOS';

  @override
  void initState() {
    super.initState();
    dashboardFuture = repository.loadDashboard(forceDemo: widget.demoMode);
  }

  Future<void> refresh() async {
    setState(() {
      dashboardFuture = repository.loadDashboard(forceDemo: widget.demoMode);
    });
  }

  Future<void> signOut() async {
    await repository.signOut();
  }

  void openFieldFile(int index) {
    setState(() {
      selectedClientIndex = index;
      selectedIndex = 2;
    });
  }

  void openRoute(int index) {
    setState(() {
      selectedClientIndex = index;
      selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_AppColors.green, _AppColors.deepGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Fuerza de Ventas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: refresh,
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: widget.demoMode ? null : signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<SalesDashboardData>(
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
          final filtered = _filteredClients(data.portfolio);
          final safeSelectedIndex = data.portfolio.isEmpty
              ? 0
              : selectedClientIndex.clamp(0, data.portfolio.length - 1).toInt();
          final selectedClient = data.portfolio.isEmpty
              ? null
              : data.portfolio[safeSelectedIndex];

          final pages = [
            _PortfolioTab(
              data: data,
              clients: filtered,
              segmentFilter: segmentFilter,
              statusFilter: statusFilter,
              onSegmentChanged: (value) =>
                  setState(() => segmentFilter = value),
              onStatusChanged: (value) => setState(() => statusFilter = value),
              onOpenFieldFile: (client) =>
                  openFieldFile(data.portfolio.indexOf(client)),
              onOpenRoute: (client) =>
                  openRoute(data.portfolio.indexOf(client)),
            ),
            _RouteTab(
              clients: data.portfolio,
              selected: selectedClient,
              onSelect: (index) => setState(() => selectedClientIndex = index),
            ),
            _FieldFileTab(
              client: selectedClient,
              data: data,
              repository: repository,
              onSubmitted: refresh,
            ),
            _TrackingTab(data: data),
            _NetworkTab(data: data),
          ];

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: pages[selectedIndex],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0F2E7),
        surfaceTintColor: Colors.white,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Cartera',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Ruta',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Ficha',
          ),
          NavigationDestination(
            icon: Icon(Icons.rule_outlined),
            selectedIcon: Icon(Icons.rule),
            label: 'Estados',
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

  List<PreapprovedClient> _filteredClients(List<PreapprovedClient> clients) {
    return clients.where((client) {
      final bySegment =
          segmentFilter == 'TODOS' || client.segment == segmentFilter;
      final byStatus = statusFilter == 'TODOS' || client.status == statusFilter;
      return bySegment && byStatus;
    }).toList();
  }
}

class _PortfolioTab extends StatelessWidget {
  const _PortfolioTab({
    required this.data,
    required this.clients,
    required this.segmentFilter,
    required this.statusFilter,
    required this.onSegmentChanged,
    required this.onStatusChanged,
    required this.onOpenFieldFile,
    required this.onOpenRoute,
  });

  final SalesDashboardData data;
  final List<PreapprovedClient> clients;
  final String segmentFilter;
  final String statusFilter;
  final ValueChanged<String> onSegmentChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<PreapprovedClient> onOpenFieldFile;
  final ValueChanged<PreapprovedClient> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final pending = data.portfolio
        .where((client) => client.status == 'preaprobado')
        .length;
    final visits = data.portfolio.where((client) => client.hasVisit).length;
    final amount = data.portfolio.fold<num>(
      0,
      (sum, client) => sum + client.hypothesisAmount,
    );

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.isDemo)
            const _Banner(
              icon: Icons.info_outline,
              text:
                  'Modo demo activo. El login real se mantiene con alumno1@example.com.',
            ),
          _AdvisorHeader(advisor: data.advisor),
          const SizedBox(height: 16),
          _MetricStrip(
            metrics: [
              _MetricItem(
                Icons.people,
                'Cartera diaria',
                '${data.portfolio.length}',
                _AppColors.green,
              ),
              _MetricItem(
                Icons.pending_actions,
                'Pendientes',
                '$pending',
                _AppColors.orange,
              ),
              _MetricItem(
                Icons.assignment_turned_in,
                'Visitados',
                '$visits',
                _AppColors.teal,
              ),
              _MetricItem(
                Icons.payments,
                'Hipotesis',
                _money(amount),
                _AppColors.blue,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FilterBar(
            segmentFilter: segmentFilter,
            statusFilter: statusFilter,
            onSegmentChanged: onSegmentChanged,
            onStatusChanged: onStatusChanged,
          ),
          const SizedBox(height: 14),
          _SectionTitle('Cartera diaria'),
          if (clients.isEmpty)
            const _StateMessage(
              icon: Icons.search_off,
              title: 'Sin clientes con este filtro',
              message: 'Cambia el segmento o estado para ver mas candidatos.',
            )
          else
            ...clients.map(
              (client) => _ClientCard(
                client: client,
                onOpenFieldFile: () => onOpenFieldFile(client),
                onOpenRoute: () => onOpenRoute(client),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteTab extends StatelessWidget {
  const _RouteTab({
    required this.clients,
    required this.selected,
    required this.onSelect,
  });

  final List<PreapprovedClient> clients;
  final PreapprovedClient? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return const _StateMessage(
        icon: Icons.route,
        title: 'Ruta sin clientes',
        message: 'Cuando la cartera cargue, aqui aparecera el plan de visitas.',
      );
    }

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionIntro(
            icon: Icons.route,
            title: 'Planificacion de ruta',
            description:
                'Mapa operativo con pins simulados, coordenadas y orden sugerido de visita.',
            color: _AppColors.teal,
          ),
          _RouteMap(clients: clients, selected: selected),
          const SizedBox(height: 18),
          _SectionTitle('Visitas del dia'),
          for (var i = 0; i < clients.length; i++)
            _DataTile(
              icon: Icons.location_on,
              title: clients[i].fullName,
              subtitle: '${clients[i].business} - ${clients[i].district}',
              trailing: '${clients[i].scoreValue.toStringAsFixed(0)}/800',
              color: _segmentColor(clients[i].segment),
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _FieldFileTab extends StatefulWidget {
  const _FieldFileTab({
    required this.client,
    required this.data,
    required this.repository,
    required this.onSubmitted,
  });

  final PreapprovedClient? client;
  final SalesDashboardData data;
  final ScoringRepository repository;
  final VoidCallback onSubmitted;

  @override
  State<_FieldFileTab> createState() => _FieldFileTabState();
}

class _FieldFileTabState extends State<_FieldFileTab> {
  bool negocioVerificado = true;
  String antiguedadNegocio = 'mas_3_anios';
  String tenenciaLocal = 'alquilado_con_contrato';
  String ventasDiariasRango = '151_a_300';
  String ratioGastos = 'menos_50pct';
  String tieneDeudaInformal = 'no';
  String participaPandero = 'no';
  String stockVisible = 'abundante';
  String activosHogar = 'al_menos_uno';
  String caracterResultado = 'sin_penalidad';
  String recomendacion = 'aprobar';
  bool dniCaptured = false;
  bool businessDocCaptured = false;
  bool sending = false;
  final amountController = TextEditingController(text: '1800');
  final observationsController = TextEditingController();
  int plazoMeses = 12;

  @override
  void dispose() {
    amountController.dispose();
    observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    if (client == null) {
      return const _StateMessage(
        icon: Icons.assignment_late_outlined,
        title: 'Selecciona un cliente',
        message:
            'Desde Cartera puedes iniciar la ficha de evaluacion de campo.',
      );
    }

    final amount =
        num.tryParse(amountController.text.replaceAll(',', '.')) ??
        client.hypothesisAmount;
    final input = FieldScoringInput(
      negocioVerificado: negocioVerificado,
      antiguedadNegocio: antiguedadNegocio,
      tenenciaLocal: tenenciaLocal,
      ventasDiariasRango: ventasDiariasRango,
      ratioGastos: ratioGastos,
      tieneDeudaInformal: tieneDeudaInformal,
      participaPandero: participaPandero,
      stockVisible: stockVisible,
      activosHogar: activosHogar,
      caracterResultado: caracterResultado,
      montoPropuesto: amount,
      plazoMeses: plazoMeses,
      recomendacion: recomendacion,
      observaciones: observationsController.text,
    );
    final result = input.calculate(
      client.scoreValue,
      _number(client.score, 'ingreso_promedio_ref', fallback: 3000),
    );

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClientSummary(client: client),
          const SizedBox(height: 16),
          _ScoreSummary(result: result, transactionalScore: client.scoreValue),
          const SizedBox(height: 18),
          _SectionTitle('F1 Verificacion del negocio'),
          _SwitchRow(
            title: 'Negocio verificado fisicamente',
            value: negocioVerificado,
            onChanged: (value) => setState(() => negocioVerificado = value),
          ),
          _OptionSelect(
            label: 'Antiguedad',
            value: antiguedadNegocio,
            options: const {
              'menos_1_anio': 'Menos de 1 ano',
              '1_a_3_anios': '1 a 3 anos',
              'mas_3_anios': 'Mas de 3 anos',
            },
            onChanged: (value) => setState(() => antiguedadNegocio = value),
          ),
          _OptionSelect(
            label: 'Tenencia del local',
            value: tenenciaLocal,
            options: const {
              'alquilado_sin_contrato': 'Alquilado sin contrato',
              'alquilado_con_contrato': 'Alquilado con contrato',
              'propio': 'Propio',
            },
            onChanged: (value) => setState(() => tenenciaLocal = value),
          ),
          const SizedBox(height: 18),
          _SectionTitle('F2 Capacidad de pago'),
          _OptionSelect(
            label: 'Ventas diarias',
            value: ventasDiariasRango,
            options: const {
              'menos_50': 'Menos de S/ 50',
              '50_a_150': 'S/ 50 a S/ 150',
              '151_a_300': 'S/ 151 a S/ 300',
              'mas_300': 'Mas de S/ 300',
            },
            onChanged: (value) => setState(() => ventasDiariasRango = value),
          ),
          _OptionSelect(
            label: 'Gastos fijos',
            value: ratioGastos,
            options: const {
              'mas_80pct': 'Mas del 80%',
              '50_a_80pct': '50% a 80%',
              'menos_50pct': 'Menos del 50%',
            },
            onChanged: (value) => setState(() => ratioGastos = value),
          ),
          const SizedBox(height: 18),
          _SectionTitle('F3 Deuda informal'),
          _OptionSelect(
            label: 'Prestamos informales',
            value: tieneDeudaInformal,
            options: const {
              'si_significativa': 'Si, significativa',
              'si_menor': 'Si, menor',
              'no': 'No',
            },
            onChanged: (value) => setState(() => tieneDeudaInformal = value),
          ),
          _OptionSelect(
            label: 'Pandero o junta',
            value: participaPandero,
            options: const {
              'si_mayor_cuota': 'Si, cuota mayor',
              'si_menor_cuota': 'Si, cuota menor',
              'no': 'No',
            },
            onChanged: (value) => setState(() => participaPandero = value),
          ),
          const SizedBox(height: 18),
          _SectionTitle('F4 Activos y documentos'),
          _OptionSelect(
            label: 'Stock visible',
            value: stockVisible,
            options: const {
              'escaso': 'Escaso',
              'moderado': 'Moderado',
              'abundante': 'Abundante',
            },
            onChanged: (value) => setState(() => stockVisible = value),
          ),
          _OptionSelect(
            label: 'Activos del hogar',
            value: activosHogar,
            options: const {
              'ninguno': 'Ninguno',
              'al_menos_uno': 'Al menos uno',
            },
            onChanged: (value) => setState(() => activosHogar = value),
          ),
          Row(
            children: [
              Expanded(
                child: _CaptureButton(
                  label: 'DNI',
                  captured: dniCaptured,
                  onPressed: () => setState(() => dniCaptured = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CaptureButton(
                  label: 'Documento negocio',
                  captured: businessDocCaptured,
                  onPressed: () => setState(() => businessDocCaptured = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle('F5 Caracter y propuesta'),
          _OptionSelect(
            label: 'Caracter del cliente',
            value: caracterResultado,
            options: const {
              'sin_penalidad': 'Sin penalidad',
              'alerta': 'Alerta',
              'veto': 'Veto',
            },
            onChanged: (value) => setState(() => caracterResultado = value),
          ),
          _ProposalForm(
            amountController: amountController,
            plazoMeses: plazoMeses,
            recomendacion: recomendacion,
            observationsController: observationsController,
            onChanged: () => setState(() {}),
            onTermChanged: (value) => setState(() => plazoMeses = value),
            onRecommendationChanged: (value) =>
                setState(() => recomendacion = value),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: sending ? null : () => _submit(client, input, result),
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Enviar al comite'),
            style: FilledButton.styleFrom(
              backgroundColor: _AppColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    PreapprovedClient client,
    FieldScoringInput input,
    FieldScoringResult result,
  ) async {
    setState(() => sending = true);
    try {
      await widget.repository.submitFieldFile(
        client: client,
        input: input,
        result: result,
        advisorName: _text(
          widget.data.advisor,
          'nombre_completo',
          fallback: 'Asesor',
        ),
        agency: _text(
          widget.data.advisor,
          'agencia',
          fallback: 'Agencia Huancayo Centro',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ficha enviada al comite')));
      widget.onSubmitted();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar: $error'),
          backgroundColor: _AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}

class _TrackingTab extends StatelessWidget {
  const _TrackingTab({required this.data});

  final SalesDashboardData data;

  @override
  Widget build(BuildContext context) {
    final states = <String, int>{};
    for (final client in data.portfolio) {
      states.update(client.status, (value) => value + 1, ifAbsent: () => 1);
    }

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionIntro(
            icon: Icons.rule,
            title: 'Estado de solicitudes',
            description:
                'Seguimiento del flujo enviado, comite, aprobado y desembolsado.',
            color: _AppColors.purple,
          ),
          _MetricStrip(
            metrics: states.entries
                .map(
                  (entry) => _MetricItem(
                    Icons.timeline,
                    _pretty(entry.key),
                    '${entry.value}',
                    _AppColors.purple,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          _SectionTitle('Historial de visitas'),
          if (data.history.isEmpty)
            const _StateMessage(
              icon: Icons.history,
              title: 'Sin historial',
              message: 'Las fichas enviadas apareceran en esta seccion.',
            )
          else
            ...data.history.map(
              (visit) => _DataTile(
                icon: Icons.fact_check,
                title: _text(
                  visit,
                  'nombre_cliente',
                  fallback: 'Cliente visitado',
                ),
                subtitle:
                    '${_text(visit, 'fecha_visita')} - ${_pretty(_text(visit, 'recomendacion_asesor'))}',
                trailing: _text(
                  visit,
                  'segmento_resultante',
                  fallback: 'PENDIENTE',
                ),
                color: _segmentColor(_text(visit, 'segmento_resultante')),
              ),
            ),
          const SizedBox(height: 18),
          _SectionTitle('KPIs piloto'),
          ...data.kpis.map((kpi) => _KpiTile(kpi: kpi)),
        ],
      ),
    );
  }
}

class _NetworkTab extends StatelessWidget {
  const _NetworkTab({required this.data});

  final SalesDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionIntro(
            icon: Icons.groups,
            title: 'Red comercial',
            description:
                'Agencias, asesores y metas cargadas desde los SQL del profesor.',
            color: _AppColors.teal,
          ),
          _SectionTitle('Agencias'),
          ...data.agencies.map(
            (agency) => _DataTile(
              icon: Icons.account_balance,
              title: _text(agency, 'nombre'),
              subtitle:
                  '${_text(agency, 'codigo')} - ${_text(agency, 'region')}',
              trailing:
                  '${_number(agency, 'total_asesores').toStringAsFixed(0)} asesores',
              color: _AppColors.green,
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle('Asesores de negocio'),
          ...data.advisors.map(
            (advisor) => _DataTile(
              icon: Icons.badge,
              title: _text(advisor, 'nombre_completo'),
              subtitle:
                  '${_text(advisor, 'nivel')} - ${_text(advisor, 'agencia')}',
              trailing:
                  '${_number(advisor, 'creditos_meta').toStringAsFixed(0)} metas',
              color: _AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorHeader extends StatelessWidget {
  const _AdvisorHeader({required this.advisor});

  final Map<String, dynamic> advisor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _boxDecoration(accent: _AppColors.lime),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent,
              color: _AppColors.green,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(
                    advisor,
                    'nombre_completo',
                    fallback: 'Asesor Fuerza de Ventas',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${_text(advisor, 'agencia')} - ${_text(advisor, 'nivel')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          _StatusPill(
            text: _text(advisor, 'codigo', fallback: 'AG-001'),
            color: _AppColors.green,
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.segmentFilter,
    required this.statusFilter,
    required this.onSegmentChanged,
    required this.onStatusChanged,
  });

  final String segmentFilter;
  final String statusFilter;
  final ValueChanged<String> onSegmentChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _boxDecoration(accent: _AppColors.blue),
      child: Column(
        children: [
          _OptionSelect(
            label: 'Segmento',
            value: segmentFilter,
            options: const {
              'TODOS': 'Todos',
              'PREMIER': 'Premier',
              'ESTANDAR': 'Estandar',
              'BASICO': 'Basico',
            },
            onChanged: onSegmentChanged,
          ),
          _OptionSelect(
            label: 'Estado',
            value: statusFilter,
            options: const {
              'TODOS': 'Todos',
              'preaprobado': 'Preaprobado',
              'contactado': 'Contactado',
              'visita_realizada': 'Visita realizada',
              'en_comite': 'En comite',
              'aprobado': 'Aprobado',
              'desembolsado': 'Desembolsado',
              'rechazado': 'Rechazado',
            },
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.onOpenFieldFile,
    required this.onOpenRoute,
  });

  final PreapprovedClient client;
  final VoidCallback onOpenFieldFile;
  final VoidCallback onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final color = _segmentColor(client.segment);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(accent: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${client.business} - ${client.district}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              _StatusPill(text: client.segment, color: color),
            ],
          ),
          const SizedBox(height: 12),
          _MetricStrip(
            metrics: [
              _MetricItem(
                Icons.speed,
                'Score',
                '${client.scoreValue.toStringAsFixed(0)}/800',
                color,
              ),
              _MetricItem(
                Icons.payments,
                'Hipotesis',
                _money(client.hypothesisAmount),
                _AppColors.blue,
              ),
              _MetricItem(
                Icons.flag,
                'Estado',
                _pretty(client.status),
                _AppColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenFieldFile,
                  icon: const Icon(Icons.assignment),
                  label: const Text('Iniciar ficha'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _AppColors.green,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Ver en ruta',
                onPressed: onOpenRoute,
                icon: const Icon(Icons.route),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.clients, required this.selected});

  final List<PreapprovedClient> clients;
  final PreapprovedClient? selected;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE5EFE9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD2E1D8)),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
            for (var i = 0; i < clients.length; i++)
              Positioned(
                left: 32.0 + (i * 74) % 260,
                top: 34.0 + (i * 58) % 210,
                child: Tooltip(
                  message:
                      '${clients[i].fullName} - ${_money(clients[i].hypothesisAmount)}',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _segmentColor(clients[i].segment),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: clients[i] == selected
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(Icons.store, size: 17, color: Colors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selected == null
                      ? 'Selecciona un cliente para ver su ubicacion'
                      : '${selected!.fullName} - ${selected!.lat.toStringAsFixed(5)}, ${selected!.lng.toStringAsFixed(5)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final thinRoadPaint = Paint()
      ..color = const Color(0xFFBCD5C7)
      ..strokeWidth = 2;

    for (var y = 36.0; y < size.height; y += 58) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 24), roadPaint);
    }
    for (var x = 34.0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x + 24, size.height), thinRoadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClientSummary extends StatelessWidget {
  const _ClientSummary({required this.client});

  final PreapprovedClient client;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(accent: _segmentColor(client.segment)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  client.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _StatusPill(
                text: client.segment,
                color: _segmentColor(client.segment),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${client.business} - ${client.district}'),
          Text(
            _text(
              client.profile,
              'direccion_negocio',
              fallback: 'Direccion por confirmar',
            ),
          ),
          const SizedBox(height: 12),
          _MetricStrip(
            metrics: [
              _MetricItem(
                Icons.speed,
                'Score transaccional',
                '${client.scoreValue.toStringAsFixed(0)}/800',
                _AppColors.green,
              ),
              _MetricItem(
                Icons.payments,
                'Monto hipotesis',
                _money(client.hypothesisAmount),
                _AppColors.blue,
              ),
              _MetricItem(
                Icons.account_balance,
                'SBS',
                _text(client.profile, 'calificacion_sbs', fallback: 'Normal'),
                _AppColors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary({required this.result, required this.transactionalScore});

  final FieldScoringResult result;
  final num transactionalScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(
        accent: result.disqualified
            ? _AppColors.red
            : _segmentColor(result.segment),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.disqualified ? result.reason : result.segment,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                result.disqualified ? '0' : '${result.scoreFinal}/1000',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetricStrip(
            metrics: [
              _MetricItem(
                Icons.analytics,
                'Campo',
                '${result.scoreCampo}/200',
                _AppColors.orange,
              ),
              _MetricItem(
                Icons.scoreboard,
                'Final',
                result.disqualified ? 'DESC' : '${result.scoreFinal}',
                _AppColors.green,
              ),
              _MetricItem(
                Icons.payments,
                'Monto max.',
                _money(result.maxAmount),
                _AppColors.blue,
              ),
              _MetricItem(
                Icons.receipt_long,
                'Cuota',
                _money(result.payment),
                _AppColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Base transaccional: ${transactionalScore.toStringAsFixed(0)}/800',
          ),
        ],
      ),
    );
  }
}

class _ProposalForm extends StatelessWidget {
  const _ProposalForm({
    required this.amountController,
    required this.plazoMeses,
    required this.recomendacion,
    required this.observationsController,
    required this.onChanged,
    required this.onTermChanged,
    required this.onRecommendationChanged,
  });

  final TextEditingController amountController;
  final int plazoMeses;
  final String recomendacion;
  final TextEditingController observationsController;
  final VoidCallback onChanged;
  final ValueChanged<int> onTermChanged;
  final ValueChanged<String> onRecommendationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(accent: _AppColors.purple),
      child: Column(
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto propuesto',
              prefixIcon: Icon(Icons.payments),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          _OptionSelect(
            label: 'Plazo',
            value: plazoMeses.toString(),
            options: const {'3': '3 meses', '6': '6 meses', '12': '12 meses'},
            onChanged: (value) => onTermChanged(int.parse(value)),
          ),
          _OptionSelect(
            label: 'Recomendacion',
            value: recomendacion,
            options: const {
              'aprobar': 'Aprobar',
              'aprobar_monto_reducido': 'Aprobar monto reducido',
              'elevar_comite': 'Elevar comite',
              'rechazar': 'Rechazar',
            },
            onChanged: onRecommendationChanged,
          ),
          TextField(
            controller: observationsController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.label,
    required this.captured,
    required this.onPressed,
  });

  final String label;
  final bool captured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(captured ? Icons.check_circle : Icons.photo_camera),
      label: Text(captured ? '$label listo' : label),
    );
  }
}

class _OptionSelect extends StatelessWidget {
  const _OptionSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items: options.entries
            .map(
              (entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: _boxDecoration(
        accent: value ? _AppColors.green : _AppColors.red,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: _boxDecoration(accent: color),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.metrics});

  final List<_MetricItem> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 760
            ? 4
            : (constraints.maxWidth > 520 ? 2 : 1);
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _MetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricItem metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(12),
      decoration: _boxDecoration(accent: metric.color),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(metric.icon, color: metric.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem(this.icon, this.label, this.value, this.color);

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        _pretty(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
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
          '${_number(kpi, 'desembolsos').toStringAsFixed(0)} desembolsos - Mora 30: ${_number(kpi, 'mora_30_pct').toStringAsFixed(1)}%',
      trailing: '${_number(kpi, 'tasa_conversion_pct').toStringAsFixed(1)}%',
      color: _AppColors.teal,
    );
  }
}

class _DataTile extends StatelessWidget {
  const _DataTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: _boxDecoration(accent: color),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
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
              Flexible(
                child: Text(
                  trailing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
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
          constraints: const BoxConstraints(maxWidth: 980),
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
      child: Row(
        children: [
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              color: _AppColors.green,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _AppColors.orange),
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
            Icon(icon, size: 56, color: _AppColors.green),
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

BoxDecoration _boxDecoration({Color accent = _AppColors.green}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border(left: BorderSide(color: accent, width: 4)),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.08),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

Color _segmentColor(String segment) {
  return switch (segment.toUpperCase()) {
    'PREMIER' => _AppColors.green,
    'ESTANDAR' => _AppColors.blue,
    'BASICO' => _AppColors.orange,
    'DESCALIFICADO' => _AppColors.red,
    _ => _AppColors.teal,
  };
}

String _text(Map<String, dynamic> map, String key, {String fallback = ''}) {
  final value = map[key];
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

num _number(Map<String, dynamic> map, String key, {num fallback = 0}) {
  final value = map[key];
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? fallback;
  return fallback;
}

String _money(num value) {
  return 'S/ ${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
}

String _pretty(String value) {
  if (value.isEmpty) return '-';
  return value.replaceAll('_', ' ').toUpperCase();
}
