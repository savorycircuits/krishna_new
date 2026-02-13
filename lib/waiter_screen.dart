import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'models.dart';

class WaiterScreen extends StatefulWidget {
  const WaiterScreen({super.key});
  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen> {
  // 1. App State Variables
  String searchQuery = "";
  String selectedCategory = "All";
  String selectedTable = "Table 1";
  String orderType = "Dine-In";
  List<OrderItem> cart = [];

  // 2. Networking Variable
  late IO.Socket socket;

  // 3. Dropdown Options
  final List<String> tables = List.generate(20, (index) => "Table ${index + 1}");
  final List<String> types = ["Dine-In", "Take Away", "Cabin", "Garden"];

  @override
  void initState() {
    super.initState();
    _connectToLaptop();
  }

  void _connectToLaptop() {
    // Connect to your Linux Laptop
    socket = IO.io('http://192.168.1.102:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) => debugPrint('Connected to Krishna Laptop Server'));
    socket.onDisconnect((_) => debugPrint('Disconnected from Laptop'));
  }

  void _showRequestDialog(MenuItem item) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add ${item.name}"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Special Request (e.g. No Spicy)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                cart.add(OrderItem(name: item.name, price: item.price, request: controller.text));
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMenu = restaurantMenu.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCat = selectedCategory == "All" || item.category == selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 40),
        
        // Table & Type Selection Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.black,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedTable,
                  decoration: const InputDecoration(labelText: "Select Table"),
                  items: tables.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => selectedTable = v!),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: orderType,
                  decoration: const InputDecoration(labelText: "Order Type"),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => orderType = v!),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (v) => setState(() => searchQuery = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.amber),
              hintText: "Search items...",
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // Category Ribbon
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: restaurantCategories.map((cat) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(cat),
                selected: selectedCategory == cat,
                onSelected: (s) => setState(() => selectedCategory = cat),
              ),
            )).toList(),
          ),
        ),

        // Menu List
        Expanded(
          child: ListView.builder(
            itemCount: filteredMenu.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(filteredMenu[i].name),
              subtitle: Text(filteredMenu[i].category),
              trailing: Text("₹${filteredMenu[i].price}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              onTap: () => _showRequestDialog(filteredMenu[i]),
            ),
          ),
        ),

        // SEND KOT BUTTON
        if (cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 55)),
              onPressed: () {
                // ACTUALLY SEND DATA TO LAPTOP
                socket.emit('send_kot', {
                  'table': selectedTable,
                  'type': orderType,
                  'items': cart.map((item) => {
                    'name': item.name,
                    'price': item.price,
                    'request': item.request,
                  }).toList(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("KOT Sent for $selectedTable ($orderType)")),
                );
                setState(() => cart.clear());
              },
              child: Text("SEND KOT - ${cart.length} ITEMS", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
      ],
    );
  }
}
