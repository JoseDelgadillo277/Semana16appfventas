import 'dart:math';

import 'package:bancofalabella_app2/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesDashboardData {
  const SalesDashboardData({
    required this.advisor,
    required this.portfolio,
    required this.agencies,
    required this.advisors,
    required this.kpis,
    required this.history,
    required this.isDemo,
  });

  final Map<String, dynamic> advisor;
  final List<PreapprovedClient> portfolio;
  final List<Map<String, dynamic>> agencies;
  final List<Map<String, dynamic>> advisors;
  final List<Map<String, dynamic>> kpis;
  final List<Map<String, dynamic>> history;
  final bool isDemo;
}

class PreapprovedClient {
  const PreapprovedClient({
    required this.credit,
    required this.profile,
    required this.score,
    required this.fieldFile,
  });

  final Map<String, dynamic> credit;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> score;
  final Map<String, dynamic> fieldFile;

  String get id => _text(credit, 'id');
  String get userId => _text(credit, 'user_id');
  String get fullName {
    final name = _text(profile, 'nombres');
    final lastName = _text(profile, 'apellidos');
    return '$name $lastName'.trim().isEmpty
        ? 'Cliente preaprobado'
        : '$name $lastName'.trim();
  }

  String get business => _text(profile, 'tipo_negocio', fallback: 'Negocio');
  String get district => _text(profile, 'distrito', fallback: 'Sin distrito');
  String get segment => _text(
    credit,
    'segmento',
    fallback: _text(score, 'segmento_preliminar', fallback: 'PENDIENTE'),
  );
  String get status => _text(credit, 'estado', fallback: 'preaprobado');
  num get scoreValue => _number(
    credit,
    'score_transaccional',
    fallback: _number(score, 'score_transaccional'),
  );
  num get finalScore => _number(
    credit,
    'score_final',
    fallback: scoreValue + _number(fieldFile, 'score_campo'),
  );
  num get hypothesisAmount => _number(
    credit,
    'monto_hipotesis',
    fallback: _number(score, 'monto_hipotesis'),
  );
  num get approvedAmount =>
      _number(credit, 'monto_aprobado', fallback: hypothesisAmount);
  num get lat => _number(profile, 'lat_negocio');
  num get lng => _number(profile, 'lng_negocio');
  bool get hasVisit => fieldFile.isNotEmpty;
}

class FieldScoringInput {
  const FieldScoringInput({
    required this.negocioVerificado,
    required this.antiguedadNegocio,
    required this.tenenciaLocal,
    required this.ventasDiariasRango,
    required this.ratioGastos,
    required this.tieneDeudaInformal,
    required this.participaPandero,
    required this.stockVisible,
    required this.activosHogar,
    required this.caracterResultado,
    required this.montoPropuesto,
    required this.plazoMeses,
    required this.recomendacion,
    required this.observaciones,
  });

  final bool negocioVerificado;
  final String antiguedadNegocio;
  final String tenenciaLocal;
  final String ventasDiariasRango;
  final String ratioGastos;
  final String tieneDeudaInformal;
  final String participaPandero;
  final String stockVisible;
  final String activosHogar;
  final String caracterResultado;
  final num montoPropuesto;
  final int plazoMeses;
  final String recomendacion;
  final String observaciones;

  FieldScoringResult calculate(num scoreTransaccional, num ingresoPromedio) {
    if (!negocioVerificado) {
      return FieldScoringResult.disqualified('Negocio no verificado');
    }
    if (caracterResultado == 'veto') {
      return FieldScoringResult.disqualified('Veto por caracter del cliente');
    }

    final ptsAntiguedad = switch (antiguedadNegocio) {
      'mas_3_anios' => 40,
      '1_a_3_anios' => 20,
      _ => 0,
    };
    final ptsTenencia = switch (tenenciaLocal) {
      'propio' => 20,
      'alquilado_con_contrato' => 10,
      _ => 0,
    };
    final ptsVentas = switch (ventasDiariasRango) {
      'mas_300' => 45,
      '151_a_300' => 30,
      '50_a_150' => 15,
      _ => 0,
    };
    final ptsGastos = switch (ratioGastos) {
      'menos_50pct' => 15,
      '50_a_80pct' => 5,
      _ => 0,
    };
    final ptsDeuda = switch (tieneDeudaInformal) {
      'no' => 20,
      'si_menor' => -20,
      'si_significativa' => -50,
      _ => 0,
    };
    final ptsPandero = switch (participaPandero) {
      'no' => 20,
      'si_menor_cuota' => 0,
      'si_mayor_cuota' => -20,
      _ => 0,
    };
    final ptsStock = switch (stockVisible) {
      'abundante' => 20,
      'moderado' => 10,
      _ => 0,
    };
    final ptsActivos = activosHogar == 'al_menos_uno' ? 20 : 0;
    final scoreCampo =
        ptsAntiguedad +
        ptsTenencia +
        ptsVentas +
        ptsGastos +
        ptsDeuda +
        ptsPandero +
        ptsStock +
        ptsActivos;
    final scoreFinal = scoreTransaccional.toInt() + scoreCampo;
    final segment = _segmentForScore(scoreFinal);
    final segmentCap = switch (segment) {
      'PREMIER' => 5000.0,
      'ESTANDAR' => 2500.0,
      'BASICO' => 1000.0,
      _ => 0.0,
    };
    final term = switch (segment) {
      'PREMIER' => 12,
      'ESTANDAR' => 6,
      'BASICO' => 3,
      _ => plazoMeses,
    };
    final factor = ScoringRepository.paymentFactor(0.60, plazoMeses);
    final incomeCap = ingresoPromedio * 2;
    final paymentCap = factor == 0 ? 0 : (ingresoPromedio * 0.30) / factor;
    final maxAmount = [segmentCap, incomeCap, paymentCap]
        .where((value) => value > 0)
        .fold<double>(
          segmentCap,
          (previous, current) => min(previous, current.toDouble()),
        );
    final proposed = montoPropuesto <= 0
        ? maxAmount
        : min(montoPropuesto.toDouble(), maxAmount);

    return FieldScoringResult(
      disqualified: false,
      reason: '',
      ptsF1: ptsAntiguedad + ptsTenencia,
      ptsF2: ptsVentas + ptsGastos,
      ptsF3: ptsDeuda + ptsPandero,
      ptsF4: ptsStock + ptsActivos,
      scoreCampo: scoreCampo,
      scoreFinal: scoreFinal,
      segment: segment,
      maxAmount: maxAmount,
      suggestedTerm: term,
      payment: proposed * factor,
      ptsAntiguedad: ptsAntiguedad,
      ptsTenencia: ptsTenencia,
      ptsVentas: ptsVentas,
      ptsGastos: ptsGastos,
      ptsDeuda: ptsDeuda,
      ptsPandero: ptsPandero,
      ptsStock: ptsStock,
      ptsActivos: ptsActivos,
    );
  }
}

class FieldScoringResult {
  const FieldScoringResult({
    required this.disqualified,
    required this.reason,
    required this.ptsF1,
    required this.ptsF2,
    required this.ptsF3,
    required this.ptsF4,
    required this.scoreCampo,
    required this.scoreFinal,
    required this.segment,
    required this.maxAmount,
    required this.suggestedTerm,
    required this.payment,
    required this.ptsAntiguedad,
    required this.ptsTenencia,
    required this.ptsVentas,
    required this.ptsGastos,
    required this.ptsDeuda,
    required this.ptsPandero,
    required this.ptsStock,
    required this.ptsActivos,
  });

  factory FieldScoringResult.disqualified(String reason) => FieldScoringResult(
    disqualified: true,
    reason: reason,
    ptsF1: 0,
    ptsF2: 0,
    ptsF3: 0,
    ptsF4: 0,
    scoreCampo: 0,
    scoreFinal: 0,
    segment: 'DESCALIFICADO',
    maxAmount: 0,
    suggestedTerm: 0,
    payment: 0,
    ptsAntiguedad: 0,
    ptsTenencia: 0,
    ptsVentas: 0,
    ptsGastos: 0,
    ptsDeuda: 0,
    ptsPandero: 0,
    ptsStock: 0,
    ptsActivos: 0,
  );

  final bool disqualified;
  final String reason;
  final int ptsF1;
  final int ptsF2;
  final int ptsF3;
  final int ptsF4;
  final int scoreCampo;
  final int scoreFinal;
  final String segment;
  final double maxAmount;
  final int suggestedTerm;
  final double payment;
  final int ptsAntiguedad;
  final int ptsTenencia;
  final int ptsVentas;
  final int ptsGastos;
  final int ptsDeuda;
  final int ptsPandero;
  final int ptsStock;
  final int ptsActivos;
}

class ScoringRepository {
  Future<SalesDashboardData> loadDashboard({bool forceDemo = false}) async {
    if (forceDemo || !SupabaseConfig.isConfigured) {
      return _demoData;
    }

    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return _demoData;

    try {
      final results = await Future.wait<dynamic>([
        client
            .from('creditos_preaprobados')
            .select()
            .order('score_final', ascending: false)
            .limit(30),
        client.from('vw_pbi_agencias').select().limit(8),
        client.from('vw_pbi_asesores').select().limit(12),
        client.from('vw_pbi_kpis_piloto').select().limit(8),
        client.from('vw_pbi_fichas_campo').select().limit(12),
      ]);

      final credits = _asList(results[0]);
      if (credits.isEmpty) return _demoData;

      final userIds = credits
          .map((item) => _text(item, 'user_id'))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final scoreIds = credits
          .map((item) => _text(item, 'score_id'))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final related = await Future.wait<dynamic>([
        userIds.isEmpty
            ? Future.value(<Map<String, dynamic>>[])
            : client
                  .from('perfiles_clientes')
                  .select()
                  .inFilter('user_id', userIds),
        scoreIds.isEmpty
            ? Future.value(<Map<String, dynamic>>[])
            : client
                  .from('scores_transaccionales')
                  .select()
                  .inFilter('id', scoreIds),
        userIds.isEmpty
            ? Future.value(<Map<String, dynamic>>[])
            : client
                  .from('fichas_campo')
                  .select()
                  .inFilter('user_id', userIds)
                  .order('fecha_visita', ascending: false),
      ]);

      final profiles = _indexBy(_asList(related[0]), 'user_id');
      final scores = _indexBy(_asList(related[1]), 'id');
      final fieldFiles = _latestByUser(_asList(related[2]));
      final portfolio = credits
          .map(
            (credit) => PreapprovedClient(
              credit: credit,
              profile: profiles[_text(credit, 'user_id')] ?? const {},
              score: scores[_text(credit, 'score_id')] ?? const {},
              fieldFile: fieldFiles[_text(credit, 'user_id')] ?? const {},
            ),
          )
          .toList();

      return SalesDashboardData(
        advisor: _advisorFromSession(client.auth.currentUser?.email),
        portfolio: portfolio,
        agencies: _asList(results[1]),
        advisors: _asList(results[2]),
        kpis: _asList(results[3]),
        history: _asList(results[4]),
        isDemo: false,
      );
    } catch (_) {
      return _demoData;
    }
  }

  Future<void> submitFieldFile({
    required PreapprovedClient client,
    required FieldScoringInput input,
    required FieldScoringResult result,
    required String advisorName,
    required String agency,
  }) async {
    if (!SupabaseConfig.isConfigured) return;

    final supabase = Supabase.instance.client;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final estadoCredito = result.disqualified
        ? 'rechazado'
        : 'visita_realizada';
    final ventasMensuales = switch (input.ventasDiariasRango) {
      'mas_300' => 10500,
      '151_a_300' => 5720,
      '50_a_150' => 2700,
      _ => 1200,
    };
    final gastos = switch (input.ratioGastos) {
      'menos_50pct' => ventasMensuales * 0.42,
      '50_a_80pct' => ventasMensuales * 0.65,
      _ => ventasMensuales * 0.88,
    };

    await supabase.from('fichas_campo').insert({
      'user_id': client.userId,
      'score_id': _text(client.credit, 'score_id').isEmpty
          ? null
          : _text(client.credit, 'score_id'),
      'asesor_nombre': advisorName,
      'agencia': agency,
      'fecha_visita': today,
      'hora_inicio': '09:00',
      'hora_fin': '09:45',
      'negocio_verificado': input.negocioVerificado,
      'motivo_no_verificado': result.disqualified ? result.reason : null,
      'antiguedad_negocio': input.antiguedadNegocio,
      'pts_antiguedad': result.ptsAntiguedad,
      'tenencia_local': input.tenenciaLocal,
      'pts_tenencia': result.ptsTenencia,
      'direccion_verificada': _text(client.profile, 'direccion_negocio'),
      'ventas_diarias_rango': input.ventasDiariasRango,
      'pts_ventas': result.ptsVentas,
      'ventas_mensuales_est': ventasMensuales,
      'gastos_fijos_mes': gastos,
      'ratio_gastos': input.ratioGastos,
      'pts_gastos': result.ptsGastos,
      'ingreso_consistente': true,
      'tiene_deuda_informal': input.tieneDeudaInformal,
      'pts_deuda_informal': result.ptsDeuda,
      'monto_deuda_informal': input.tieneDeudaInformal == 'no' ? 0 : 600,
      'participa_pandero': input.participaPandero,
      'pts_pandero': result.ptsPandero,
      'stock_visible': input.stockVisible,
      'pts_stock': result.ptsStock,
      'activos_hogar': input.activosHogar,
      'pts_activos': result.ptsActivos,
      'caracter_resultado': input.caracterResultado,
      'obs_caracter': input.observaciones,
      'score_transaccional_ref': client.scoreValue.toInt(),
      'monto_aprobado_propuesto': result.disqualified
          ? 0
          : min(input.montoPropuesto.toDouble(), result.maxAmount),
      'plazo_propuesto_meses': input.plazoMeses,
      'cuota_estimada': result.payment,
      'recomendacion_asesor': result.disqualified
          ? 'rechazar'
          : input.recomendacion,
      'obs_finales': input.observaciones,
      'estado_ficha': 'completada',
    });

    await supabase
        .from('creditos_preaprobados')
        .update({'estado': estadoCredito, 'fecha_visita': today})
        .eq('id', client.id);
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  static double paymentFactor(double tea, int months) {
    if (months <= 0) return 0;
    final tem = pow(1 + tea, 1 / 12) - 1;
    return tem * pow(1 + tem, months) / (pow(1 + tem, months) - 1);
  }

  static Map<String, dynamic> _advisorFromSession(String? email) => {
    'nombre_completo': 'Asesor Fuerza de Ventas',
    'email': email ?? 'alumno1@example.com',
    'agencia': 'Agencia Huancayo Centro',
    'nivel': 'Senior II',
    'codigo': 'AG-001-01',
  };

  static Map<String, Map<String, dynamic>> _indexBy(
    List<Map<String, dynamic>> rows,
    String key,
  ) {
    return {for (final row in rows) _text(row, key): row};
  }

  static Map<String, Map<String, dynamic>> _latestByUser(
    List<Map<String, dynamic>> rows,
  ) {
    final values = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final userId = _text(row, 'user_id');
      if (userId.isNotEmpty && !values.containsKey(userId)) {
        values[userId] = row;
      }
    }
    return values;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) return value.map((item) => _asMap(item)).toList();
    return const <Map<String, dynamic>>[];
  }

  SalesDashboardData get _demoData {
    final clients = [
      _demoClient(
        id: '44444444-4444-4444-4444-444444444444',
        name: 'Alumno',
        lastName: 'Uno Demo',
        business: 'Bodega',
        district: 'Huancayo',
        segment: 'PREMIER',
        score: 690,
        finalScore: 845,
        status: 'desembolsado',
        amount: 5000,
        approved: 4200,
        lat: -12.065,
        lng: -75.205,
        hasVisit: true,
      ),
      _demoClient(
        id: '55555555-5555-5555-5555-555555555555',
        name: 'Rosa',
        lastName: 'Quispe Flores',
        business: 'Puesto de abarrotes',
        district: 'El Tambo',
        segment: 'ESTANDAR',
        score: 562,
        finalScore: 0,
        status: 'preaprobado',
        amount: 2500,
        approved: 1800,
        lat: -12.055,
        lng: -75.215,
      ),
      _demoClient(
        id: '66666666-6666-6666-6666-666666666666',
        name: 'Marco',
        lastName: 'Palian Rojas',
        business: 'Ferreteria',
        district: 'Chilca',
        segment: 'BASICO',
        score: 438,
        finalScore: 0,
        status: 'contactado',
        amount: 1000,
        approved: 900,
        lat: -12.078,
        lng: -75.197,
      ),
    ];

    return SalesDashboardData(
      isDemo: true,
      advisor: const {
        'nombre_completo': 'Marco Sulca Vera',
        'email': 'alumno1@example.com',
        'agencia': 'Agencia Huancayo Centro',
        'nivel': 'Senior II',
        'codigo': 'AG-001-01',
      },
      portfolio: clients,
      agencies: const [
        {
          'codigo': 'AG-001',
          'nombre': 'Agencia Huancayo Centro',
          'region': 'Centro',
          'total_asesores': 12,
          'meta_creditos_agencia': 117,
          'meta_monto_agencia': 210600,
        },
        {
          'codigo': 'AG-013',
          'nombre': 'Agencia Arequipa Centro',
          'region': 'Sur',
          'total_asesores': 12,
          'meta_creditos_agencia': 117,
          'meta_monto_agencia': 210600,
        },
      ],
      advisors: const [
        {
          'codigo': 'AG-001-01',
          'nombre_completo': 'Marco Sulca Vera',
          'nivel': 'Senior II',
          'agencia': 'Agencia Huancayo Centro',
          'creditos_meta': 16,
          'monto_meta': 28800,
        },
        {
          'codigo': 'AG-001-10',
          'nombre_completo': 'Ana Flores Poma',
          'nivel': 'Junior I',
          'agencia': 'Agencia Huancayo Centro',
          'creditos_meta': 4,
          'monto_meta': 7200,
        },
      ],
      kpis: const [
        {
          'agencia': 'Agencia Huancayo Centro',
          'visitas_totales': 60,
          'desembolsos': 44,
          'monto_desembolsado': 184800,
          'mora_30_pct': 3.8,
          'tasa_conversion_pct': 73.3,
          'semaforo_mora_30': 'OK',
        },
      ],
      history: const [
        {
          'fecha_visita': '2026-05-24',
          'asesor_nombre': 'Marco Sulca Vera',
          'agencia': 'Agencia Huancayo Centro',
          'nombre_cliente': 'Alumno Uno Demo',
          'score_final': 845,
          'segmento_resultante': 'PREMIER',
          'recomendacion_asesor': 'aprobar',
          'estado_ficha': 'completada',
        },
      ],
    );
  }

  PreapprovedClient _demoClient({
    required String id,
    required String name,
    required String lastName,
    required String business,
    required String district,
    required String segment,
    required int score,
    required int finalScore,
    required String status,
    required num amount,
    required num approved,
    required num lat,
    required num lng,
    bool hasVisit = false,
  }) {
    final userId = '$id-user';
    return PreapprovedClient(
      credit: {
        'id': id,
        'user_id': userId,
        'score_id': '$id-score',
        'segmento': segment,
        'score_transaccional': score,
        'score_campo': hasVisit ? finalScore - score : 0,
        'score_final': finalScore == 0 ? score : finalScore,
        'monto_hipotesis': amount,
        'monto_aprobado': approved,
        'plazo_meses': 12,
        'cuota_mensual': 475.5,
        'estado': status,
        'fecha_preaprobacion': '2026-05-24',
        'dias_mora': 0,
        'estado_pago': 'al_dia',
      },
      profile: {
        'user_id': userId,
        'nombres': name,
        'apellidos': lastName,
        'dni': '12345678',
        'telefono': '999888777',
        'distrito': district,
        'departamento': 'Junin',
        'tipo_negocio': business,
        'nombre_negocio': '$business $name',
        'direccion_negocio': 'Jr. Real 123',
        'lat_negocio': lat,
        'lng_negocio': lng,
        'antiguedad_negocio_meses': 42,
        'tenencia_local': 'alquilado_con_contrato',
        'num_entidades_sbs': 1,
        'calificacion_sbs': 'Normal',
      },
      score: {
        'id': '$id-score',
        'user_id': userId,
        'pts_saldo': 160,
        'pts_regularidad': 128,
        'pts_disciplina': 120,
        'pts_vinculo': 160,
        'pts_riesgo': 90,
        'score_transaccional': score,
        'segmento_preliminar': segment,
        'monto_hipotesis': amount,
        'ingreso_promedio_ref': 3600,
        'cuota_max_ref': 1080,
      },
      fieldFile: hasVisit
          ? {
              'asesor_nombre': 'Marco Sulca Vera',
              'agencia': 'Agencia Huancayo Centro',
              'fecha_visita': '2026-05-24',
              'negocio_verificado': true,
              'score_campo': finalScore - score,
              'score_final': finalScore,
              'segmento_resultante': segment,
              'recomendacion_asesor': 'aprobar',
              'estado_ficha': 'completada',
            }
          : const {},
    );
  }
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

String _segmentForScore(int score) {
  if (score >= 750) return 'PREMIER';
  if (score >= 550) return 'ESTANDAR';
  if (score >= 350) return 'BASICO';
  return 'NO_APLICA';
}
