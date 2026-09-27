import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchasesView extends StatefulWidget {
  const PurchasesView({super.key});
  @override
  State<PurchasesView> createState() => _PurchasesViewState();
}

class _PurchasesViewState extends State<PurchasesView> {
  final supabase = Supabase.instance.client;
  List<dynamic> purchases = [];
  List<dynamic> filteredPurchases = [];
  List<dynamic> products = [];
  List<dynamic> suppliers = [];
  bool isLoading = true;

  String? selectedProductId;
  String? selectedSupplierId;
  final qtyController = TextEditingController();
  final priceController = TextEditingController();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  @override
  void dispose() {
    searchController.dispose();
    qtyController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> loadAll() async {
    setState(() => isLoading = true);
    try {
      final pur = await supabase.from('purchases').select().order('created_at', ascending: false);
      final pro = await supabase.from('products').select().order('name');
      final sup = await supabase.from('suppliers').select().order('name');
      setState(() {
        purchases = pur;
        filteredPurchases = pur;
        products = pro;
        suppliers = sup;
      });
    } catch (e) {
      print("LOAD ERROR: $e");
    }
    setState(() => isLoading = false);
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      setState(() => filteredPurchases = purchases);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      filteredPurchases = purchases.where((p) {
        final prodName = getProductName(p['product_id']).toLowerCase();
        final suppName = getSupplierName(p['supplier_id']).toLowerCase();
        return prodName.contains(lower) || suppName.contains(lower);
      }).toList();
    });
  }

  String formatDate(String? iso) {
    if (iso == null) return "";
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return iso.split('T').first;
    }
  }

  Future<void> deletePurchase(dynamic purchase) async {
    const primary = Color(0xFF1A237E);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (context, double val, child) => Transform.scale(scale: val, child: child),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_rounded, color: Colors.red)), const SizedBox(width: 10), const Expanded(child: Text("Delete Purchase?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]),
          content: Text("Delete ${getProductName(purchase['product_id'])}?", style: const TextStyle(fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text("Delete", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    try {
      try {
        final prod = products.firstWhere((p) => p['id'].toString() == purchase['product_id'].toString());
        final currentQty = prod['quantity'] is int ? prod['quantity'] as int : int.tryParse(prod['quantity'].toString()) ?? 0;
        final purchaseQty = purchase['quantity'] is int ? purchase['quantity'] as int : int.tryParse(purchase['quantity'].toString()) ?? 0;
        await supabase.from('products').update({'quantity': (currentQty - purchaseQty).clamp(0, 9999999)}).eq('id', purchase['product_id']);
      } catch (_) {}
      await supabase.from('purchases').delete().eq('id', purchase['id']);
      loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchase Deleted")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> addPurchase() async {
    if (selectedProductId == null || selectedSupplierId == null || qtyController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }
    try {
      final qty = int.parse(qtyController.text.trim());
      final price = double.parse(priceController.text.trim());
      await supabase.from('purchases').insert({
        'product_id': selectedProductId,
        'supplier_id': int.parse(selectedSupplierId!),
        'quantity': qty,
        'purchase_price': price,
        'total_amount': qty * price,
      });
      try {
        final prod = products.firstWhere((p) => p['id'].toString() == selectedProductId);
        final currentQty = prod['quantity'] is int ? prod['quantity'] as int : int.tryParse(prod['quantity'].toString()) ?? 0;
        await supabase.from('products').update({'quantity': currentQty + qty}).eq('id', selectedProductId!);
      } catch (_) {}
      if (!mounted) return;
      Navigator.pop(context);
      qtyController.clear(); priceController.clear();
      selectedProductId = null; selectedSupplierId = null;
      loadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void showAddDialog() {
    selectedProductId = null; selectedSupplierId = null;
    qtyController.clear(); priceController.clear();
    const primary = Color(0xFF1A237E);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFF5F6FF),
          insetPadding: const EdgeInsets.all(16),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, double val, child) => Transform.scale(scale: val, child: child),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 22)),
                      const SizedBox(width: 12),
                      const Text("New Purchase", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: primary)),
                    ]),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Select Product", prefixIcon: const Icon(Icons.inventory_2_rounded, color: primary, size: 20), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5))),
                      items: products.map((p) => DropdownMenuItem<String>(value: p['id'].toString(), child: Text(p['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setDialogState(() => selectedProductId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Select Supplier", prefixIcon: const Icon(Icons.person_rounded, color: primary, size: 20), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5))),
                      items: suppliers.map((s) => DropdownMenuItem<String>(value: s['id'].toString(), child: Text(s['name'].toString()))).toList(),
                      onChanged: (v) => setDialogState(() => selectedSupplierId = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Quantity", prefixIcon: const Icon(Icons.numbers_rounded, color: primary, size: 20), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)))),
                    const SizedBox(height: 12),
                    TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Price per unit", prefixIcon: const Icon(Icons.payments_rounded, color: primary, size: 20), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)))),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600))),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: addPurchase, style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, elevation: 6, shadowColor: primary.withValues(alpha: 0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_rounded, size: 18), SizedBox(width: 6), Text("Save", style: TextStyle(fontWeight: FontWeight.bold))])),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String getProductName(dynamic id) {
    try { return products.firstWhere((e) => e['id'].toString() == id.toString())['name'].toString(); } catch (_) { return id.toString(); }
  }
  String getSupplierName(dynamic id) {
    try { return suppliers.firstWhere((e) => e['id'].toString() == id.toString())['name'].toString(); } catch (_) { return id.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A237E);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(title: const Text("Purchases", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: primary, foregroundColor: Colors.white, elevation: 0),
      floatingActionButton: FloatingActionButton.extended(onPressed: showAddDialog, backgroundColor: primary, foregroundColor: Colors.white, icon: const Icon(Icons.add_rounded), label: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        Container(
          color: primary,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]),
            child: TextField(
              controller: searchController,
              onChanged: filterSearch,
              decoration: InputDecoration(hintText: "Search product or supplier...", prefixIcon: const Icon(Icons.search_rounded, color: primary), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: primary))
              : filteredPurchases.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_bag_outlined, size: 70, color: Colors.grey.shade300), const SizedBox(height: 10), Text("No purchases", style: TextStyle(color: Colors.grey.shade500))]))
              : ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: filteredPurchases.length,
            itemBuilder: (context, i) {
              final p = filteredPurchases[i];
              return TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 350 + (i % 5 * 80)),
                curve: Curves.easeOutCubic,
                builder: (context, double val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))]),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade700]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))]), child: const Icon(Icons.shopping_bag_rounded, color: Colors.white)),
                    title: Text("${getProductName(p['product_id'])} - Qty: ${p['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 4),
                      Text("Supplier: ${getSupplierName(p['supplier_id'])}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text("${p['purchase_price']} x ${p['quantity']} = Rs ${p['total_amount']}", style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 4),
                      Text(formatDate(p['created_at']?.toString()), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    ]),
                    isThreeLine: true,
                    trailing: Container(decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20), onPressed: () => deletePurchase(p))),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}