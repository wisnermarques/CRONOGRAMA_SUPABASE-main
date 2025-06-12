import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelper {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://xrvlludmkeytytiymzlu.supabase.co/',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhydmxsdWRta2V5dHl0aXltemx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1NTk3MDAsImV4cCI6MjA2NDEzNTcwMH0.ws26ZPPy_cKSA21ZDmtV06rZJf8ogwxhATuNSWSSiX0',
    );
  }
}
