import 'package:get/get.dart';
import '../controllers/supllier_controller.dart';
class SuppliersBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SuppliersController());
  }
}