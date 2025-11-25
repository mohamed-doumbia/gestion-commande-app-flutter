import 'package:gestion_commandes/data/models/vendor_info_mode.dart';

import 'product_model.dart';


class ProductWithVendorModel {
  final ProductModel product;
  final VendorInfoModel vendorInfo;

  ProductWithVendorModel({
    required this.product,
    required this.vendorInfo,
  });
}