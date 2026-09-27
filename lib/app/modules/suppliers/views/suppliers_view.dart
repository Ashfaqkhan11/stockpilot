import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuppliersView extends StatefulWidget {
  const SuppliersView({super.key});
  @override
  State<SuppliersView> createState() => _SuppliersViewState();
}

class _SuppliersViewState extends State<SuppliersView> {
  final supabase = Supabase.instance.client;
  List<dynamic> suppliers = [];
  bool isLoading = true;

  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    setState(() => isLoading = true);
    try {
      final myId = supabase.auth.currentUser!.id;
      final res = await supabase
          .from('suppliers')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false);
      setState(() => suppliers = res);
    } catch (e) {
      print("Load error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> addSupplier() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter Supplier Name")));
      return;
    }
    try {
      final myId = supabase.auth.currentUser!.id;
      await supabase.from('suppliers').insert({
        'name': nameController.text.trim(),
        'contact': contactController.text.trim(),
        'address': addressController.text.trim(),
        'user_id': myId,
      });
      Navigator.pop(context);
      nameController.clear();
      contactController.clear();
      addressController.clear();
      loadSuppliers();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Supplier Added!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      print(e);
    }
  }

  void showAddDialog() {
    const primary = Color(0xFF1A237E);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text("New Supplier", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: primary)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _decorField(controller: nameController, label: "Name *", icon: Icons.person_rounded),
                  const SizedBox(height: 12),
                  _decorField(controller: contactController, label: "Phone / Contact", icon: Icons.phone_rounded, type: TextInputType.phone),
                  const SizedBox(height: 12),
                  _decorField(controller: addressController, label: "Address", icon: Icons.location_on_rounded),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: addSupplier,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_rounded, size: 18), SizedBox(width: 6), Text("Save", style: TextStyle(fontWeight: FontWeight.bold))]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _decorField({required TextEditingController controller, required String label, required IconData icon, TextInputType? type}) {
    const primary = Color(0xFF1A237E);
    return TextField(
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
    );
  }

  Future<void> deleteSupplier(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (context, double val, child) => Transform.scale(scale: val, child: child),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_rounded, color: Colors.red)), const SizedBox(width: 10), const Expanded(child: Text("Delete Supplier?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]),
          content: const Text("Are you sure you want to delete this supplier?", style: TextStyle(fontSize: 13, color: Colors.grey)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text("Delete", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
    if (confirm!= true) return;
    await supabase.from('suppliers').delete().eq('id', id);
    loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A237E);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Suppliers", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : suppliers.isEmpty
          ? TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, double val, child) => Opacity(opacity: val, child: Transform.scale(scale: val, child: child)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text("No suppliers yet", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Click + to add", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadSuppliers,
        color: primary,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 80),
          itemCount: suppliers.length,
          itemBuilder: (context, i) {
            final s = suppliers[i];
            final name = s['name']?? '';
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: Center(child: Text(name.isNotEmpty? name[0].toUpperCase() : "S", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.phone_rounded, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(child: Text(s['contact']?? 'No contact', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(child: Text(s['address']?? 'No address', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20), onPressed: () => deleteSupplier(s['id'])),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}