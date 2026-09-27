import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsController extends GetxController {
  final supabase = Supabase.instance.client;

  var products = <dynamic>[].obs;
  var filteredProducts = <dynamic>[].obs;
  var isLoading = true.obs;
  var isSaving = false.obs;
  var pickedImage = Rx<XFile?>(null);

  var isEditMode = false.obs;
  var editingProductId = Rx<dynamic>(null);
  var existingImageUrl = Rx<String?>(null);

  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final skuController = TextEditingController();
  final categoryController = TextEditingController();
  final qtyController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final sellingPriceController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    skuController.dispose();
    categoryController.dispose();
    qtyController.dispose();
    purchasePriceController.dispose();
    sellingPriceController.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      final myId = supabase.auth.currentUser!.id;
      final res = await supabase.from('products').select().eq('user_id', myId).order('created_at', ascending: false);
      products.value = res;
      filteredProducts.value = res;
    } catch (e) {
      print("LOAD ERROR: $e");
    }
    isLoading.value = false;
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      filteredProducts.value = products;
      return;
    }
    final lower = query.toLowerCase();
    filteredProducts.value = products.where((p) {
      return p['name'].toString().toLowerCase().contains(lower) ||
          (p['sku'] ?? '').toString().toLowerCase().contains(lower) ||
          (p['category'] ?? '').toString().toLowerCase().contains(lower);
    }).toList();
  }

  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) pickedImage.value = img;
  }

  Future<String?> uploadImage() async {
    if (pickedImage.value == null) return existingImageUrl.value;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedImage.value!.name}';
    final bytes = await pickedImage.value!.readAsBytes();
    await supabase.storage.from('product_images').uploadBinary(fileName, bytes);
    return supabase.storage.from('product_images').getPublicUrl(fileName);
  }

  void clearFields() {
    nameController.clear();
    skuController.clear();
    categoryController.clear();
    qtyController.clear();
    purchasePriceController.clear();
    sellingPriceController.clear();
    pickedImage.value = null;
    existingImageUrl.value = null;
    isEditMode.value = false;
    editingProductId.value = null;
  }

  Future<void> addProduct() async {
    if (nameController.text.isEmpty || qtyController.text.isEmpty) {
      Get.snackbar("Error", "Name & Qty required");
      return;
    }
    isSaving.value = true;
    try {
      final myId = supabase.auth.currentUser!.id;
      final imgUrl = await uploadImage();
      await supabase.from('products').insert({
        'name': nameController.text.trim(),
        'sku': skuController.text.trim().isEmpty ? null : skuController.text.trim(),
        'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
        'quantity': int.tryParse(qtyController.text.trim()) ?? 0,
        'purchase_price': double.tryParse(purchasePriceController.text.trim()) ?? 0,
        'selling_price': double.tryParse(sellingPriceController.text.trim()) ?? 0,
        'user_id': myId,
        'image_url': imgUrl,
      });
      Get.back();
      clearFields();
      loadProducts();
      Get.snackbar("Success", "Product Added", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
    isSaving.value = false;
  }

  void startEditProduct(dynamic product) {
    isEditMode.value = true;
    editingProductId.value = product['id'];
    nameController.text = product['name'] ?? '';
    skuController.text = product['sku'] ?? '';
    categoryController.text = product['category'] ?? '';
    qtyController.text = (product['quantity'] ?? 0).toString();
    purchasePriceController.text = (product['purchase_price'] ?? 0).toString();
    sellingPriceController.text = (product['selling_price'] ?? product['price'] ?? 0).toString();
    existingImageUrl.value = product['image_url'];
    pickedImage.value = null;
    showAddDialog();
  }

  Future<void> updateProduct() async {
    if (nameController.text.isEmpty) {
      Get.snackbar("Error", "Name required");
      return;
    }
    isSaving.value = true;
    try {
      final imgUrl = await uploadImage();
      await supabase.from('products').update({
        'name': nameController.text.trim(),
        'sku': skuController.text.trim().isEmpty ? null : skuController.text.trim(),
        'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
        'quantity': int.tryParse(qtyController.text.trim()) ?? 0,
        'purchase_price': double.tryParse(purchasePriceController.text.trim()) ?? 0,
        'selling_price': double.tryParse(sellingPriceController.text.trim()) ?? 0,
        'image_url': imgUrl,
      }).eq('id', editingProductId.value);

      Get.back();
      clearFields();
      loadProducts();
      Get.snackbar("Success", "Product Updated", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
    isSaving.value = false;
  }

  Future<void> deleteProduct(dynamic product) async {
    final confirm = await Get.dialog<bool>(
      TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (context, double val, child) => Transform.scale(scale: val.clamp(0.0, 1.5), child: child),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_rounded, color: Colors.red)), const SizedBox(width: 10), Expanded(child: Text("Delete ${product['name']}?", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]),
          content: const Text("Are you sure? This action cannot be undone.", style: TextStyle(fontSize: 13, color: Colors.grey)),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Get.back(result: true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text("Delete", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    await supabase.from('products').delete().eq('id', product['id']);
    loadProducts();
  }

  void showAddDialog() {
    if (!isEditMode.value) {
      clearFields();
    }
    const primary = Color(0xFF1A237E);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF5F6FF),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Obx(() => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.85,
          ),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (context, double val, child) => Transform.scale(
                scale: val,
                child: Opacity(
                    opacity: val.clamp(0.0, 1.0), // FIXED - WAS CRASHING
                    child: child
                )
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Icon(isEditMode.value ? Icons.edit_rounded : Icons.add_box_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(isEditMode.value ? "Edit Product" : "New Product", style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: primary)),
                      const Spacer(),
                      IconButton(onPressed: () { Get.back(); if (!isEditMode.value) clearFields(); }, icon: Icon(Icons.close_rounded, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: pickImage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: pickedImage.value != null || (existingImageUrl.value?.isNotEmpty ?? false) ? primary.withValues(alpha: 0.3) : Colors.grey.shade300, width: 1.2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: pickedImage.value == null
                            ? (existingImageUrl.value != null && existingImageUrl.value!.isNotEmpty
                            ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(existingImageUrl.value!, fit: BoxFit.cover),
                            Container(color: Colors.black.withValues(alpha: 0.2), child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit, color: Colors.white), SizedBox(height: 4), Text("Tap to change", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))),
                          ],
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.add_a_photo_rounded, color: primary)),
                            const SizedBox(height: 8),
                            Text("Tap to add image", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ))
                            : kIsWeb
                            ? Image.network(pickedImage.value!.path, fit: BoxFit.cover)
                            : Image.file(File(pickedImage.value!.path), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _animField(0, controller: nameController, label: "Product Name *", icon: Icons.inventory_2_rounded),
                  const SizedBox(height: 12),
                  _animField(1, controller: skuController, label: "SKU (e.g. hp-111)", icon: Icons.qr_code_rounded),
                  const SizedBox(height: 12),
                  _animField(2, controller: categoryController, label: "Category", icon: Icons.category_rounded),
                  const SizedBox(height: 12),
                  _animField(3, controller: qtyController, label: "Quantity", icon: Icons.numbers_rounded, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _animField(4, controller: purchasePriceController, label: "Purchase Price", icon: Icons.shopping_bag_rounded, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _animField(5, controller: sellingPriceController, label: "Selling Price", icon: Icons.sell_rounded, type: TextInputType.number),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () { Get.back(); clearFields(); }, style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600), child: const Text("Cancel")),
                      const SizedBox(width: 8),
                      Obx(() => ElevatedButton(
                        onPressed: isSaving.value ? null : (isEditMode.value ? updateProduct : addProduct),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                        ),
                        child: isSaving.value
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(mainAxisSize: MainAxisSize.min, children: [Icon(isEditMode.value ? Icons.check_rounded : Icons.add_rounded, size: 18), const SizedBox(width: 6), Text(isEditMode.value ? "Update" : "Save", style: const TextStyle(fontWeight: FontWeight.bold))]),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )),
      ),
      barrierDismissible: false,
    );
  }

  Widget _animField(int index, {required TextEditingController controller, required String label, required IconData icon, TextInputType? type}) {
    const primary = Color(0xFF1A237E);
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, double val, child) => Opacity(
          opacity: val.clamp(0.0, 1.0), // FIXED - WAS CRASHING
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - val)),
              child: child
          )
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primary, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
        ),
      ),
    );
  }
}