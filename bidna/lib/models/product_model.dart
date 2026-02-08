class Product {
  final String imageUrl;
  final String productTitle;
  final double price;
  final String category;
  final int bids;
  final String status;

  Product({
    required this.imageUrl,
    required this.productTitle,
    required this.price,
    required this.category,
    required this.bids,
    this.status = "Open",
  });
}
