import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/modules/auth/views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yrgmuqvpfnslmzrolbwl.supabase.co', // <- put from Supabase dashboard
    publishableKey: 'sb_publishable_rqw3KHwzXSWQUbjZ45jPmw_lAeNbipW', // <- put anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StockPilot',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: LoginView(),
    );
  }
}