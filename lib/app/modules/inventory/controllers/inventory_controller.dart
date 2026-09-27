import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = true.obs;
  var inventoryList = <Map<String, dynamic>>[].obs;
  var lowStockList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchInventory();
    _listenLive(); // LIVE animation of data
  }

  // LIVE REALTIME - inventory updates instantly
  void _listenLive() {
    supabase.from('products').stream(primaryKey: ['id']).listen((data) {
      List<Map<String, dynamic>> result = [];
      List<Map<String, dynamic>> lowStock = [];

      for (var prod in data) {
        int stock = (prod['quantity'] ?? prod['stock'] ?? prod['currentStock'] ?? 0) as int;

        // FIX RS 0 - READ CORRECT PRICE FIELDS
        var price = prod['selling_price'] ??
            prod['sellingPrice'] ??
            prod['price'] ??
            prod['purchase_price'] ?? 0;

        var item = {
          'id': prod['id'],
          'name': prod['name']?? 'No Name',
          'currentStock': stock,
          'quantity': stock,
          // keep both so your view works in both cases
          'price': price,
          'selling_price': price,
          'purchase_price': prod['purchase_price']?? 0,
        };

        result.add(item);
        if (stock < 5) lowStock.add(item);
      }

      inventoryList.value = result;
      lowStockList.value = lowStock;
    });
  }

  Future<void> fetchInventory() async {
    try {
      isLoading.value = true;
      final products = await supabase.from('products').select().order('quantity', ascending: true);

      List<Map<String, dynamic>> result = [];
      List<Map<String, dynamic>> lowStock = [];

      for (var prod in products) {
        int stock = (prod['quantity'] ?? prod['stock'] ?? 0) as int;

        // FIX RS 0 HERE
        var price = prod['selling_price'] ??
            prod['price'] ??
            prod['purchase_price'] ?? 0;

        var item = {
          'id': prod['id'],
          'name': prod['name']?? 'No Name',
          'currentStock': stock,
          'quantity': stock,
          'price': price,
          'selling_price': price,
          'purchase_price': prod['purchase_price']?? 0,
        };

        result.add(item);
        if (stock < 5) {
          lowStock.add(item);
        }
      }

      inventoryList.value = result;
      lowStockList.value = lowStock;

    } catch (e) {
      print("Inventory Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshInventory() => fetchInventory();
}