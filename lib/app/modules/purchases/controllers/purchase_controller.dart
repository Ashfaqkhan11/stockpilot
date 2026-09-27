import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../products/controller/products_controller.dart';
import '../../dashboard/controller/dashboard_controller.dart';

class PurchasesController extends GetxController {
  final supabase = Supabase.instance.client;

  var purchases = <dynamic>[].obs;
  var products = <dynamic>[].obs;
  var suppliers = <dynamic>[].obs;
  var isLoading = true.obs;
  var isSaving = false.obs;

  var selectedProductId = Rx<dynamic>(null);
  var selectedSupplierId = Rx<dynamic>(null);
  final qtyController = TextEditingController();
  final priceController = TextEditingController();
  final totalController = TextEditingController();

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
    super.onClose();
  }

  void calcTotal() {
    final qty = int.tryParse(qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    totalController.text = (qty * price).toStringAsFixed(0);
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      // FIXED: No user_id filter - so your 3 NULL rows will show
      final purRes = await supabase
          .from('purchases')
          .select('*, products(name), suppliers(name)')
          .order('created_at', ascending: false);

      purchases.value = purRes;

        print("PURCHASES LOADED: ${purRes.length}");


      // Products & suppliers - show all (no filter) so dropdown works
      final prodRes = await supabase.from('products').select().order('name');
      products.value = prodRes;

      final supRes = await supabase.from('suppliers').select().order('name');
      suppliers.value = supRes;

    } catch (e) {
      print("LOAD ERROR: $e");
      Get.snackbar("Error", e.toString());
    }
    isLoading.value = false;
  }

  Future<void> addPurchase() async {
    if (selectedProductId.value == null || qtyController.text.isEmpty) {
      Get.snackbar("Error", "Select product and quantity");
      return;
    }
    isSaving.value = true;
    try {
      final myId = supabase.auth.currentUser!.id;
      final qty = int.parse(qtyController.text.trim());
      final unitPrice = double.tryParse(priceController.text.trim()) ?? 0;
      final total = double.tryParse(totalController.text.trim()) ?? 0;

      // CORRECT COLUMNS - as per your DB screenshot
      await supabase.from('purchases').insert({
        'product_id': selectedProductId.value,
        'supplier_id': selectedSupplierId.value,
        'quantity': qty,
        'purchase_price': unitPrice,
        'total_amount': total,
        'user_id': myId,
      });

      // Update product stock
      final currentProd = products.firstWhere((p) => p['id'] == selectedProductId.value);
      final currentQty = int.tryParse(currentProd['quantity'].toString()) ?? 0;
      await supabase.from('products').update({'quantity': currentQty + qty}).eq('id', selectedProductId.value);

      Get.back();
      clearForm();
      await loadAll();

      try { Get.find<ProductsController>().loadProducts(); } catch (_) {}
      try { Get.find<DashboardController>().loadDashboard(); } catch (_) {}

      Get.snackbar("Success", "Purchase Added", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print("ADD ERROR: $e");
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
    isSaving.value = false;
  }

  Future<void> deletePurchase(dynamic purchase) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Delete?"),
        content: const Text("Stock will be reduced."),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final qty = int.tryParse(purchase['quantity'].toString()) ?? 0;
      final prodId = purchase['product_id'];
      if (prodId != null) {
        final prodRes = await supabase.from('products').select('quantity').eq('id', prodId).single();
        final currQty = int.tryParse(prodRes['quantity'].toString()) ?? 0;
        await supabase.from('products').update({'quantity': currQty - qty}).eq('id', prodId);
      }
      await supabase.from('purchases').delete().eq('id', purchase['id']);
      await loadAll();
      try { Get.find<DashboardController>().loadDashboard(); } catch (_) {}
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  void clearForm() {
    selectedProductId.value = null;
    selectedSupplierId.value = null;
    qtyController.clear();
    priceController.clear();
    totalController.clear();
  }

  void showAddDialog() {
    clearForm();
    Get.dialog(
      Obx(() => AlertDialog(
        title: const Text("New Purchase"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField(
              initialValue: selectedProductId.value,
              decoration: const InputDecoration(labelText: "Product", border: OutlineInputBorder()),
              items: products.map<DropdownMenuItem>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
              onChanged: (v) {
                selectedProductId.value = v;
                final prod = products.firstWhere((e) => e['id'] == v);
                priceController.text = (prod['purchase_price'] ?? 0).toString();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              initialValue: selectedSupplierId.value,
              decoration: const InputDecoration(labelText: "Supplier", border: OutlineInputBorder()),
              items: suppliers.map<DropdownMenuItem>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']))).toList(),
              onChanged: (v) => selectedSupplierId.value = v,
            ),
            const SizedBox(height: 10),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Unit Price", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: totalController, decoration: const InputDecoration(labelText: "Total", border: OutlineInputBorder()), readOnly: true),
          ]),
        ),
        actions: [
          TextButton(onPressed: () { Get.back(); clearForm(); }, child: const Text("Cancel")),
          Obx(() => ElevatedButton(onPressed: isSaving.value ? null : addPurchase, child: Text(isSaving.value ? "Saving..." : "Save"))),
        ],
      )),
    );
  }
}