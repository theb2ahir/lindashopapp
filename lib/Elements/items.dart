class Item {
  final double? latitude;
  final double? longitude;
  final String addressLivraison;
  final String username;
  final  String email;
  final  String phone;
  final int quantity;
  final String productName;
  final String productPrice;
  final String productImageUrl;
  final String livraison;
  final DateTime dateAjout;
  Item(
      {
      required this.addressLivraison,
      required this.latitude,
      required this.longitude,
      required this.username,
      required this.email,
      required this.phone,
      required this.quantity,
      required this.productName,
      required this.productPrice,      
      required this.productImageUrl,
      required this.livraison,
      required this.dateAjout
  });
}