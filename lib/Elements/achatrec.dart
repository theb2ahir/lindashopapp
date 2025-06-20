class ACR {
  final String productName;
  final String productPrice;
  final String productImageUrl;
  final String quantity;
  final DateTime dateAjout;
  final String transactionId;
  final String reference;
  final String addressLivraison;
  ACR({
    required this.addressLivraison,
    required this.reference,
    required this.transactionId,
    required this.dateAjout,
    required this.productName,
    required this.productPrice,
    required this.productImageUrl,
    required this.quantity,
  });
}
