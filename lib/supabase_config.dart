class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lvmnykemxmthlxutbpfx.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_97J6Tr63Nw5JmwwFN0sDNw_w6ixWUq6',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
