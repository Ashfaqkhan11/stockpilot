import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stockpilot/app/modules/sales/views/sale_view.dart';
import '../../products/views/products_view.dart';
import '../../purchases/views/purchases_view.dart';
import '../../suppliers/views/suppliers_view.dart';
import '../../history/views/history_view.dart';
import '../../history/controller/history_controller.dart';
import '../controller/dashboard_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../inventory/views/inventory_view.dart';
import '../../auth/views/login_view.dart';

class DashboardView extends StatefulWidget {
  DashboardView({super.key});
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with TickerProviderStateMixin {
  final DashboardController c = Get.put(DashboardController());
  final HistoryController h = Get.put(HistoryController());
  late AnimationController _pulseController;
  late AnimationController _bgController;
  final primary = const Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
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
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24))),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text("StockPilot", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(Supabase.instance.client.auth.currentUser?.email ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            _drawerTile(Icons.dashboard_rounded, "Dashboard", true, 0, onTap: () => Get.back()),
            _drawerTile(Icons.inventory_2_rounded, "Products", false, 1, onTap: () { Get.back(); Get.to(() => ProductsView()); }),
            _drawerTile(Icons.warehouse_rounded, "Inventory", false, 2, onTap: () { Get.back(); Get.to(() => InventoryView()); }),
            _drawerTile(Icons.groups_rounded, "Suppliers", false, 3, onTap: () { Get.back(); Get.to(() => SuppliersView()); }),
            _drawerTile(Icons.shopping_bag_rounded, "Purchases", false, 4, onTap: () { Get.back(); Get.to(() => PurchasesView()); }),
            _drawerTile(Icons.point_of_sale_rounded, "Sales", false, 5, onTap: () { Get.back(); Get.to(() => SaleView()); }),
            _drawerTile(Icons.history_rounded, "History", false, 6, onTap: () { Get.back(); Get.to(() => const HistoryView()); }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () async {
                Get.back();
                await Supabase.instance.client.auth.signOut();
                Get.deleteAll();
                Get.offAll(() => LoginView());
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => Positioned(
              top: -50, right: -50,
              child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.03 + _bgController.value * 0.04))),
            ),
          ),
          Obx(() {
            if (c.isLoading.value || h.isLoading.value) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
            return RefreshIndicator(
              onRefresh: () async {
                await c.loadDashboard();
                await h.fetchHistory();
              },
              color: primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.20,
                      children: [
                        _animatedCard(0, count: "${c.totalProducts.value}", title: "Total Products", color: primary, icon: Icons.inventory_2_rounded, onTap: () => Get.to(() => ProductsView())),
                        _animatedCard(1, count: "${c.totalSuppliers.value}", title: "Total Suppliers", color: const Color(0xFF00897B), icon: Icons.groups_rounded, onTap: () => Get.to(() => SuppliersView())),
                        _animatedCard(2, count: "${c.totalPurchases.value}", title: "Total Purchases", color: const Color(0xFFEF6C00), icon: Icons.shopping_bag_rounded, onTap: () => Get.to(() => PurchasesView())),
                        _animatedCard(3, count: "${c.totalSales.value}", title: "Total Sales", color: const Color(0xFF6A1B9A), icon: Icons.point_of_sale_rounded, onTap: () => Get.to(() => SaleView())),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) => TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        builder: (context, double val, child) => Transform.scale(scale: val, child: child),
                        child: InkWell(
                          onTap: () => Get.to(() => InventoryView()),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3 + _pulseController.value * 0.2), blurRadius: 10 + _pulseController.value * 6, offset: const Offset(0, 4))],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Transform.scale(
                                  scale: 1 + _pulseController.value * 0.15,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${c.totalProducts.value} Items", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const Text("Inventory - Tap to view low stock", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.teal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recent History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                        TextButton(onPressed: () => Get.to(() => const HistoryView()), child: const Text("View All", style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (h.historyList.isEmpty)
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, double val, _) => Opacity(opacity: val, child: Transform.scale(scale: val, child: const Card(child: ListTile(title: Text("No history yet"))))),
                      )
                    else
                      ...h.historyList.take(5).toList().asMap().entries.map((entry) {
                        int idx = entry.key;
                        var item = entry.value;
                        final isPurchase = item['type'] == 'purchase';
                        return TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 400 + (idx * 80)),
                          curve: Curves.easeOutCubic,
                          builder: (context, double val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 15 * (1 - val)), child: child)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 3))]),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(color: (isPurchase ? Colors.green : Colors.red).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
                                child: Icon(isPurchase ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isPurchase ? Colors.green : Colors.red, size: 20),
                              ),
                              title: Text(item['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(item['subtitle'].toString(), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              trailing: Text("Rs ${item['amount']}", style: TextStyle(fontWeight: FontWeight.bold, color: isPurchase ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12)),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () {
          c.loadDashboard();
          h.fetchHistory();
        },
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, bool active, int index, {required VoidCallback onTap}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 60)),
      builder: (context, double val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(-15 * (1 - val), 0), child: child)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: active ? primary.withValues(alpha: 0.08) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: active ? Border.all(color: primary.withValues(alpha: 0.15)) : null),
        child: ListTile(leading: Icon(icon, color: active ? primary : Colors.grey.shade700, size: 21), title: Text(title, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.w500, color: active ? primary : Colors.grey.shade800, fontSize: 13.5)), onTap: onTap),
      ),
    );
  }

  Widget _animatedCard(int index, {required String count, required String title, required Color color, required IconData icon, required VoidCallback onTap}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, double val, child) => Transform.scale(scale: val, child: Opacity(opacity: val.clamp(0.0, 1.0), child: child)),
      child: _card(count: count, title: title, color: color, icon: icon, onTap: onTap, index: index),
    );
  }

  Widget _card({required String count, required String title, required Color color, required IconData icon, required VoidCallback onTap, required int index}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.9), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.28 + (index == 0 ? _pulseController.value * 0.1 : 0)), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 22)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: double.tryParse(count) ?? 0),
                    duration: const Duration(milliseconds: 900),
                    builder: (context, double v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 3),
                  const Row(children: [Text("View", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)), SizedBox(width: 3), Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12)]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}