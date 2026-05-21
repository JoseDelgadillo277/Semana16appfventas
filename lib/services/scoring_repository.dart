import 'package:bancofalabella_app2/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardData {
  const DashboardData({
    required this.profile,
    required this.score,
    required this.credit,
    required this.fieldFile,
    required this.agencies,
    required this.advisors,
    required this.kpis,
    required this.isDemo,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> score;
  final Map<String, dynamic> credit;
  final Map<String, dynamic> fieldFile;
  final List<Map<String, dynamic>> agencies;
  final List<Map<String, dynamic>> advisors;
  final List<Map<String, dynamic>> kpis;
  final bool isDemo;
}

class ScoringRepository {
  Future<DashboardData> loadDashboard({bool forceDemo = false}) async {
    if (forceDemo || !SupabaseConfig.isConfigured) {
      return _demoData;
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      return _demoData;
    }

    final results = await Future.wait<dynamic>([
      client
          .from('perfiles_clientes')
          .select()
          .eq('user_id', userId)
          .maybeSingle(),
      client
          .from('scores_transaccionales')
          .select()
          .eq('user_id', userId)
          .maybeSingle(),
      client
          .from('creditos_preaprobados')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      client
          .from('fichas_campo')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      client.from('vw_pbi_agencias').select().limit(6),
      client.from('vw_pbi_asesores').select().limit(8),
      client.from('vw_pbi_kpis_piloto').select().limit(6),
    ]);

    return DashboardData(
      profile: _asMap(results[0]),
      score: _asMap(results[1]),
      credit: _asMap(results[2]),
      fieldFile: _asMap(results[3]),
      agencies: _asList(results[4]),
      advisors: _asList(results[5]),
      kpis: _asList(results[6]),
      isDemo: false,
    );
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value.map((item) => _asMap(item)).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  DashboardData get _demoData => const DashboardData(
    isDemo: true,
    profile: {
      'nombres': 'Rosa',
      'apellidos': 'Quispe Flores',
      'dni': '20000042',
      'telefono': '987654321',
      'distrito': 'Huancayo',
      'departamento': 'Junin',
      'tipo_negocio': 'Bodega',
      'nombre_negocio': 'Bodega Quispe',
      'antiguedad_negocio_meses': 38,
      'num_entidades_sbs': 1,
    },
    score: {
      'pts_saldo': 160,
      'pts_regularidad': 128,
      'pts_disciplina': 120,
      'pts_vinculo': 160,
      'pts_riesgo': 90,
      'score_transaccional': 658,
      'segmento_preliminar': 'PREMIER',
      'monto_hipotesis': 5000,
      'ingreso_promedio_ref': 3600,
      'cuota_max_ref': 1080,
    },
    credit: {
      'segmento': 'PREMIER',
      'score_campo': 150,
      'score_final': 808,
      'monto_aprobado': 4200,
      'plazo_meses': 12,
      'cuota_mensual': 475.5,
      'estado': 'desembolsado',
      'dias_mora': 0,
      'estado_pago': 'al_dia',
    },
    fieldFile: {
      'asesor_nombre': 'Marco Sulca Vera',
      'agencia': 'Agencia Huancayo Centro',
      'fecha_visita': '2026-05-12',
      'negocio_verificado': true,
      'ventas_diarias_rango': '151_a_300',
      'ventas_mensuales_est': 5720,
      'gastos_fijos_mes': 2173.6,
      'tiene_deuda_informal': 'no',
      'stock_visible': 'abundante',
      'caracter_resultado': 'sin_penalidad',
      'recomendacion_asesor': 'aprobar',
      'comite_resolucion': 'aprobado',
    },
    agencies: [
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
    advisors: [
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
    kpis: [
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
  );
}
