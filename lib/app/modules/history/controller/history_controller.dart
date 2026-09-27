import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = true.obs;
  var historyList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
    _listenLive();
  }

  void _listenLive() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    supabase.from('sales').stream(primaryKey: ['id']).eq('user_id', userId).listen((_) => fetchHistory());
    supabase.from('purchases').stream(primaryKey: ['id']).eq('user_id', userId).listen((_) => fetchHistory());
  }

  Future<void> fetchHistory() async {
    try {
      isLoading.value = true;
      final userId = supabase.auth.currentUser!.id;

      final purchases = await supabase.from('purchases').select().eq('user_id', userId).order('created_at', ascending: false);
      final sales = await supabase.from('sales').select().eq('user_id', userId).order('created_at', ascending: false);

      // SAFE products fetch - for fallback names & profit calc
      Map<String, dynamic> productMap = {};
      try {
        final products = await supabase.from('products').select('id,name,purchase_price,sale_price').eq('user_id', userId);
        for (var pr in products) {
          productMap[pr['id'].toString()] = pr;
        }
      } catch (e) {
        print("Products fetch ignored: $e");
      }

      List<Map<String, dynamic>> combined = [];

      for (var p in purchases) {
        final prodId = p['product_id']?.toString();
        final qty = p['quantity_purchased'] ?? p['quantity'] ?? p['qty'] ?? 0;
        final total = p['total_amount'] ?? p['purchase_price'] ?? p['total'] ?? 0;

        // FIX: Use productMap if product_name is empty (your bug)
        final prodName = p['product_name'] ?? p['name'] ?? productMap[prodId]?['name'] ?? 'Product';

        combined.add({
          'type': 'purchase',
          'title': 'Purchase - $prodName',
          'subtitle': 'Qty: $qty | Total: Rs $total | ${p['created_at'].toString().substring(0, 10)}',
          'date': p['created_at'],
          'amount': total,
        });
      }

      for (var s in sales) {
        final prodId = s['product_id']?.toString();
        final qty = s['quantity_sold'] ?? s['quantity'] ?? s['qty'] ?? 0;
        final total = s['total_amount'] ?? s['total'] ?? 0;
        var profit = s['profit'];

        // FIX 1: calc from sales row itself
        if (profit == null || profit == 0) {
          var sellPrice = s['sale_price'] ?? s['selling_price'] ?? 0;
          var buyPrice = s['purchase_price'] ?? 0;
          if (sellPrice != 0 && buyPrice != 0) {
            int q = qty is int ? qty : int.tryParse(qty.toString()) ?? 0;
            profit = (sellPrice - buyPrice) * q;
          }
        }

        // FIX 2: calc from products table for old records
        if ((profit == null || profit == 0) && prodId != null && productMap.containsKey(prodId)) {
          var prod = productMap[prodId];
          var sell = prod['sale_price'] ?? 0;
          var buy = prod['purchase_price'] ?? 0;
          if (sell != 0 && buy != 0) {
            int q = qty is int ? qty : int.tryParse(qty.toString()) ?? 0;
            profit = (sell - buy) * q;
          }
        }

        profit ??= 0;
        final prodName = s['product_name'] ?? s['name'] ?? productMap[prodId]?['name'] ?? 'Product';

        combined.add({
          'type': 'sale',
          'title': 'Sale - $prodName',
          'subtitle': 'Qty: $qty | Total: Rs $total | Profit: Rs $profit | ${s['created_at'].toString().substring(0, 10)}',
          'date': s['created_at'],
          'amount': total,
          'profit': profit,
        });
      }

      combined.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
      historyList.value = combined;
      print("History loaded: ${combined.length}");
    } catch (e) {
      print("History Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}