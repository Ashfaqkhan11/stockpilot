import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/products_controller.dart';

class ProductsView extends StatelessWidget {
  ProductsView({super.key});
  final ProductsController c = Get.put(ProductsController());

  String getPriceText(dynamic p) {
    return (p['selling_price']?? p['price']?? 0).toString();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A237E);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Products", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: c.loadProducts)
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () {
          c.isEditMode.value = false;
          c.showAddDialog();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // SEARCH - DECORATED
          Container(
            color: primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: c.searchController,
                onChanged: c.filterSearch,
                decoration: InputDecoration(
                  hintText: "Search name, sku, category...",
                  prefixIcon: const Icon(Icons.search_rounded, color: primary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: primary));
              }
              if (c.filteredProducts.isEmpty) {
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, double val, child) => Opacity(opacity: val, child: Transform.scale(scale: val, child: child)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text("No products found. Add new!", style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: c.filteredProducts.length,
                itemBuilder: (context, i) {
                  final p = c.filteredProducts[i];
                  final qty = p['quantity'] is int? p['quantity'] : int.tryParse(p['quantity'].toString())?? 0;
                  final isLow = qty <= 5;
                  final imgUrl = p['image_url'];
                  final sku = p['sku']?? 'NO SKU';
                  final category = p['category']?? 'No Category';

                  // STAGGERED ANIMATION PER ITEM
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + (i % 6 * 80)),
                    curve: Curves.easeOutCubic,
                    builder: (context, double val, child) {
                      return Opacity(
                        opacity: val,
                        child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: isLow? [Colors.red.shade50, Colors.white] : [Colors.white, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: isLow? Colors.red.withValues(alpha: 0.3) : Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        leading: Hero(
                          tag: p['id'].toString(),
                          child: imgUrl!= null && imgUrl.toString().isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imgUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isLow? Colors.red : primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(isLow? Icons.warning_rounded : Icons.inventory_2_rounded, color: Colors.white),
                              ),
                            ),
                          )
                              : Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: isLow? [Colors.red.shade400, Colors.red.shade700] : [primary.withValues(alpha: 0.8), primary]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(isLow? Icons.warning_rounded : Icons.inventory_2_rounded, color: Colors.white),
                          ),
                        ),
                        title: Text(p['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _chip(sku, Colors.blueGrey),
                                const SizedBox(width: 6),
                                _chip(category, primary),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Qty: $qty | Purchase: ${p['purchase_price']?? 0} | Sell: Rs ${getPriceText(p)}",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isLow? Colors.red.shade700 : Colors.black87),
                            ),
                            if (isLow)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text("⚠️ Low Stock! Only $qty left", style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20), onPressed: () => c.startEditProduct(p)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20), onPressed: () => c.deleteProduct(p)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}