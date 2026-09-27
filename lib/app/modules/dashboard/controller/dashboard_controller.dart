import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardController extends GetxController {
  final supabase = Supabase.instance.client;

  var totalProducts = 0.obs;
  var totalSuppliers = 0.obs;
  var totalPurchases = 0.obs;
  var totalSales = 0.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      final myId = supabase.auth.currentUser!.id;

      final prod = await supabase.from('products').select('id').eq('user_id', myId);
      totalProducts.value = prod.length;

      final sup = await supabase.from('suppliers').select('id').eq('user_id', myId);
      totalSuppliers.value = sup.length;

      // FIX: Count my purchases + NULL purchases
      final pur = await supabase.from('purchases').select('id').or('user_id.eq.$myId,user_id.is.null');
      totalPurchases.value = pur.length;
      print("PURCHASES COUNT: ${pur.length}");

      final sales = await supabase.from('sales').select('id').eq('user_id', myId);
      totalSales.value = sales.length;

    } catch (e) {
      print("ERROR: $e");
    }
    isLoading.value = false;
  }
}