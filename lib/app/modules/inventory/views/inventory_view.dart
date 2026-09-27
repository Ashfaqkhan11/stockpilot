import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';

class InventoryView extends StatefulWidget {
  InventoryView({super.key});
  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> with TickerProviderStateMixin {
  final InventoryController c = Get.put(InventoryController());
  late AnimationController _pulseController;
  late AnimationController _bgController;
  final primary = const Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Inventory", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.04 + _bgController.value * 0.04),
                ),
              ),
            ),
          ),
          Obx(() {
            if (c.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
            }

            return Column(
              children: [
                if (c.lowStockList.isNotEmpty)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutBack,
                        builder: (context, double val, child) => Transform.scale(scale: val, child: child),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade700]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3 + _pulseController.value * 0.2), blurRadius: 12 + _pulseController.value * 6, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 1 + _pulseController.value * 0.2,
                                    child: const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text("Low Stock Alert!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...c.lowStockList.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text("⚠️ Your item ${item['name']} is low - only ${item['currentStock']} left!",
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                Expanded(
                  child: c.inventoryList.isEmpty
                      ? Center(
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, double val, _) => Opacity(opacity: val, child: Transform.scale(scale: val, child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warehouse_outlined, size: 70, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text("No products in inventory", style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ))),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: c.inventoryList.length,
                    itemBuilder: (context, i) {
                      final item = c.inventoryList[i];
                      final stock = item['currentStock']?? item['quantity']?? 0;
                      final isLow = stock < 5;

                      // FIX RS 0 HERE - read all possible price keys
                      final rawPrice = item['selling_price']?? item['sellingPrice']?? item['price']?? item['purchase_price']?? 0;
                      final displayPrice = (rawPrice is num && rawPrice == 0)? (item['selling_price']?? item['purchase_price']?? item['price']?? 0) : rawPrice;

                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 400 + (i % 5 * 80)),
                        curve: Curves.easeOutCubic,
                        builder: (context, double val, child) {
                          return Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child));
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isLow? Colors.red.withValues(alpha: 0.4) : Colors.grey.shade200, width: isLow? 1.5 : 1),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) => Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: isLow? [Colors.red.shade400, Colors.red.shade700] : [Colors.teal.shade400, Colors.teal.shade700]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: (isLow? Colors.red : Colors.teal).withValues(alpha: isLow? 0.3 + _pulseController.value * 0.2 : 0.3), blurRadius: isLow? 6 + _pulseController.value * 4 : 6, offset: const Offset(0, 3))],
                                ),
                                child: Icon(isLow? Icons.warning_rounded : Icons.inventory_2_rounded, color: Colors.white),
                              ),
                            ),
                            title: Text(item['name']?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                // FIXED LINE
                                Text("Price: Rs $displayPrice", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                if (isLow)
                                  Text("Your item ${item['name']} is low - only $stock left!",
                                      style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isLow? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isLow? Colors.red.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Text("$stock",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLow? Colors.red.shade700 : Colors.green.shade700)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}