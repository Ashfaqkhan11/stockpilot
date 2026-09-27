import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../products/controller/products_controller.dart';

class SalesController extends GetxController {
  final supabase = Supabase.instance.client;

  var sales = <dynamic>[].obs;
  var filteredSales = <dynamic>[].obs;
  var products = <dynamic>[].obs;
  var isLoading = true.obs;
  var isSaving = false.obs;

  var selectedProductId = Rx<dynamic>(null);
  final qtyController = TextEditingController();
  final priceController = TextEditingController();
  final totalController = TextEditingController();
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadAll();
    qtyController.addListener(calcTotal);
    priceController.addListener(calcTotal);
  }

  @override
  void onClose() {
    qtyController.dispose();
    priceController.dispose();
    totalController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void calcTotal() {
    final qty = int.tryParse(qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    totalController.text = (qty * price).toStringAsFixed(0);
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      filteredSales.value = sales;
    } else {
      filteredSales.value = sales.where((s) {
        final name = s['products']?['name']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    }
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final myId = supabase.auth.currentUser!.id;

      final salesRes = await supabase
          .from('sales')
          .select('*, products(name)')
          .eq('user_id', myId)
          .order('created_at', ascending: false);

      sales.value = salesRes;
      filteredSales.value = salesRes;

      final prodRes = await supabase
          .from('products')
          .select()
          .eq('user_id', myId)
          .order('name');
      products.value = prodRes;

    } catch (e) {
      print("LOAD ERROR $e");
    }
    isLoading.value = false;
  }

  Future<void> addSale() async {
    if (selectedProductId.value == null || qtyController.text.isEmpty) {
      Get.snackbar("Error", "Select product and quantity");
      return;
    }

    final prod = products.firstWhere((p) => p['id'] == selectedProductId.value);
    final stock = int.tryParse(prod['quantity'].toString()) ?? 0;
    final sellQty = int.tryParse(qtyController.text) ?? 0;

    if (sellQty > stock) {
      Get.snackbar("Error", "Only $stock in stock", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isSaving.value = true;
    try {
      final myId = supabase.auth.currentUser!.id;
      final qty = int.parse(qtyController.text.trim());
      final salePrice = double.parse(priceController.text.trim());

      // FIX Rs 0 - GET PURCHASE PRICE FROM PRODUCT
      final purchasePrice = double.tryParse(prod['purchase_price']?.toString() ?? '0') ?? 0;
      final profitPerItem = salePrice - purchasePrice;
      final totalProfit = profitPerItem * qty;

      // DON'T SEND total_amount (it's GENERATED) - BUT SEND profit + purchase_price
      await supabase.from('sales').insert({
        'product_id': selectedProductId.value,
        'quantity_sold': qty,
        'sale_price': salePrice,
        'purchase_price': purchasePrice, // needed for history recalc
        'profit': totalProfit, // THIS FIXES HISTORY Rs 0
        'product_name': prod['name'], // for history display
        'user_id': myId,
      });

      await supabase.from('products').update({
        'quantity': stock - qty
      }).eq('id', selectedProductId.value);

      Get.back();
      clearForm();
      await loadAll();
      try { Get.find<ProductsController>().loadProducts(); } catch (_) {}
      try { Get.find<DashboardController>().loadDashboard(); } catch (_) {}
      Get.snackbar("Success", "Sale Added - Profit Rs $totalProfit", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print("SALE ERROR: $e");
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
    isSaving.value = false;
  }

  void clearForm() {
    selectedProductId.value = null;
    qtyController.clear();
    priceController.clear();
    totalController.clear();
  }

  void showAddDialog() {
    clearForm();
    Get.dialog(
      Obx(() => AlertDialog(
        title: const Text("New Sale"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField(
              initialValue: selectedProductId.value,
              decoration: const InputDecoration(labelText: "Select Product", border: OutlineInputBorder()),
              items: products.map<DropdownMenuItem>((p) {
                return DropdownMenuItem(value: p['id'], child: Text("${p['name']} (Stock: ${p['quantity']})"));
              }).toList(),
              onChanged: (v) {
                selectedProductId.value = v;
                final prod = products.firstWhere((e) => e['id'] == v);
                priceController.text = (prod['sale_price'] ?? prod['selling_price'] ?? 0).toString();
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: "Quantity Sold", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Sale Price", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: totalController, decoration: const InputDecoration(labelText: "Total (Auto)", border: OutlineInputBorder()), readOnly: true),
          ]),
        ),
        actions: [
          TextButton(onPressed: () { Get.back(); clearForm(); }, child: const Text("Cancel")),
          Obx(() => ElevatedButton(onPressed: isSaving.value ? null : addSale, child: Text(isSaving.value ? "Selling..." : "Sell"))),
        ],
      )),
    );
  }
}