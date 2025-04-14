class Vendor {
  final String vendorId;
  final String vendorName;
  final String vendorDescription;
  final String sellerId;
  final String? imageUrl;

  Vendor({
    required this.vendorId,
    required this.vendorName,
    required this.vendorDescription,
    required this.sellerId,
    this.imageUrl,
  });

  // Factory method to create a Vendor from Firestore document
  factory Vendor.fromDocument(Map<String, dynamic> doc, String docId) {
    return Vendor(
      vendorId: docId,
      vendorName: doc['vendorName'] ?? '',
      vendorDescription: doc['vendorDescription'] ?? '',
      sellerId: doc['sellerId'] ?? '',
      imageUrl: doc['imageUrl'],
    );
  }

  // Optional: convert Vendor back to Map if needed
  Map<String, dynamic> toMap() {
    return {
      'vendorName': vendorName,
      'vendorDescription': vendorDescription,
      'sellerId': sellerId,
      'imageUrl': imageUrl,
    };
  }
}
