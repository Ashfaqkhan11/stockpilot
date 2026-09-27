import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sale_controller.dart';

class SaleView extends StatelessWidget {
  const SaleView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesController());
    const primary = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Sales", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.filterSearch,
                decoration: InputDecoration(
                  hintText: "Search sold product...",
                  prefixIcon: const Icon(Icons.search_rounded, color: primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: primary));
              }
              if (controller.filteredSales.isEmpty) {
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, double val, child) => Opacity(opacity: val, child: Transform.scale(scale: val, child: child)),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.point_of_sale_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("No sales yet", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: controller.filteredSales.length,
                itemBuilder: (context, i) {
                  final s = controller.filteredSales[i];
                  final productName = s['products']!= null? s['products']['name'] : 'Unknown';
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 350 + (i % 5 * 80)),
                    curve: Curves.easeOutCubic,
                    builder: (context, double val, child) {
                      return Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child));
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
                          ),
                          child: const Icon(Icons.point_of_sale_rounded, color: Colors.white),
                        ),
                        title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Qty: ${s['quantity_sold']} | Price: Rs ${s['sale_price']}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                              child: Text("Total: Rs ${s['total_amount']}", style: const TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.showAddDialog(),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Sell", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}