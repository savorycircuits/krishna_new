// lib/models.dart

class MenuItem {
  final String name;
  final double price;
  final String category;

  MenuItem({required this.name, required this.price, required this.category});
}

class OrderItem {
  final String name;
  final double price;
  final String request;

  OrderItem({required this.name, required this.price, this.request = ""});
}

// Global Category List
final List<String> restaurantCategories = [
  "All", "Scotch", "Vodka", "BIRIYANI", "CHINESE", "SOUP", "COLD DRINKS"
];

// Sample Menu Data (We will expand this to 350+ later)
final List<MenuItem> restaurantMenu = [
  MenuItem(name: "Johnnie Walker Black", price: 450, category: "Scotch"),
  MenuItem(name: "Chicken Biryani", price: 320, category: "BIRIYANI"),
  MenuItem(name: "Coca Cola 500ml", price: 60, category: "COLD DRINKS"),
  MenuItem(name: "Veg Manchow Soup", price: 150, category: "SOUP"),
];
