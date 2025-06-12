class Item {
  final double? latitude;
  final double? longitude;
  final String username;
  final String prenom;
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
      required this.latitude,
      required this.longitude,
      required this.username,
      required this.prenom,
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