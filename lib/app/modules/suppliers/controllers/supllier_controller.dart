import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuppliersController extends GetxController {
  final supabase = Supabase.instance.client;
  var suppliers = <dynamic>[].obs;
  var isLoading = false.obs;
  final nameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();

  @override
  void onInit() { super.onInit(); fetchSuppliers(); }

  Future<void> fetchSuppliers() async {
    isLoading.value = true;
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase.from('suppliers').select().eq('user_id', uid).order('created_at', ascending: false);
    suppliers.value = data;
    isLoading.value = false;
  }

  Future<void> addSupplier() async {
    final uid = supabase.auth.currentUser!.id;
    if (nameCtrl.text.trim().isEmpty) return;
    await supabase.from('suppliers').insert({
      'name': nameCtrl.text.trim(),
      'contact': contactCtrl.text.trim(),
      'user_id': uid,
    });
    nameCtrl.clear(); contactCtrl.clear();
    Get.back();
    fetchSuppliers();
  }

  Future<void> deleteSupplier(String id) async {
    await supabase.from('suppliers').delete().eq('id', id);
    fetchSuppliers();
  }

  @override
  void onClose() { nameCtrl.dispose(); contactCtrl.dispose(); super.onClose(); }
}