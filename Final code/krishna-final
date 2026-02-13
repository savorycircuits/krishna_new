import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(MaterialApp(
  theme: ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF161B22)),
  ),
  home: const AdminMasterScreen(),
  debugShowCheckedModeBanner: false,
));

class AdminMasterScreen extends StatefulWidget {
  const AdminMasterScreen({super.key});
  @override
  State<AdminMasterScreen> createState() => _AdminMasterScreenState();
}

class _AdminMasterScreenState extends State<AdminMasterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? localIp;
  bool isDayStarted = false;
  File? restaurantLogo;
  bool isGstEnabled = true;
  bool isLicensed = false; 
final String licenseKey = "KRISHNA@8462";
DateTime expiryDate = DateTime(2026, 2, 17); // Expires Tuesday, Feb 17 at 00:00

  final TextEditingController _nameCtrl = TextEditingController(text: "KRISHNA RESTAURANT");
  final TextEditingController _addressCtrl = TextEditingController(text: "Main Road, Hyderabad");
  final TextEditingController _phoneCtrl = TextEditingController(text: "9876543210");
  final TextEditingController _gstCtrl = TextEditingController(text: "36AAAAA0000A1Z5");

  Map<String, List<Map<String, dynamic>>> runningTables = {};
  Map<String, List<dynamic>> stockItems = {"Kingfisher_650": [100, 110.0], "Coke_PET": [50, 25.0]};
  Map<String, List<dynamic>> menuItems = {"KF Strong": [180.0, "Alcohol", "Kingfisher_650"], "Coke 500ml": [45.0, "Drinks", "Coke_PET"]};
  List<String> staff = ["Admin", "Ramesh"];
  List<String> tables = ["T1", "T2", "T3", "T4", "T5"];
  List<Map<String, dynamic>> billHistory = [];
  int billCounter = 1;

void _showActions(String t) {
    if (!runningTables.containsKey(t)) return;

    showDialog(
      context: context,
      builder: (ctx) {
        double total = 0;
        for (var item in runningTables[t]!) {
          total += (item['price'] ?? 0) * (item['qty'] ?? 1);
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: Text("Table $t", style: const TextStyle(color: Colors.orange, fontSize: 24)),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: runningTables[t]!.map((item) => ListTile(
                title: Text("${item['name']} x${item['qty']}", style: const TextStyle(color: Colors.white)),
                // Showing Special Request if it exists
                subtitle: item['request'] != null ? Text("Note: ${item['request']}", style: const TextStyle(color: Colors.yellow, fontSize: 12)) : null,
                trailing: Text("₹${(item['price'] * item['qty']).toStringAsFixed(2)}"),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
            // KOT Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () => _printDocument(t, isKOT: true), 
              child: const Text("PRINT KOT")
            ),
            // Settle & Print Bill Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                _printDocument(t, isKOT: false);
                _settleBill(t);
                Navigator.pop(ctx);
              }, 
              child: const Text("PRINT & SETTLE")
            ),
          ],
        );
      },
    );
  }

void _settleBill(String t) {
  if (!runningTables.containsKey(t)) return;

  setState(() {
    double subtotal = 0;
    List currentItems = runningTables[t]!;

    for (var item in currentItems) {
      // 1. Calculate Subtotal
      double price = (item['price'] is num) ? item['price'].toDouble() : 0.0;
      int qty = item['qty'] ?? 1;
      subtotal += price * qty;

      // 2. Deduct from Stock (Existing logic)
      String itemName = item['name'];
      if (menuItems.containsKey(itemName)) {
        String stockKey = menuItems[itemName]![2]; 
        if (stockItems.containsKey(stockKey)) {
          stockItems[stockKey]![0] = (stockItems[stockKey]![0] as num) - qty;
        }
      }
    }

    // --- NEW: Calculate GST for History ---
    double gst = (isGstEnabled && _gstCtrl.text.isNotEmpty) ? (subtotal * 0.05) : 0;
    double finalTotal = subtotal + gst;

    // 3. Save to History with the Final Total
    billHistory.insert(0, {
      "billNo": billCounter++,
      "table": t,
      "items": List.from(currentItems),
      "subtotal": subtotal, // Optional: store subtotal for better reporting
      "gst": gst,           // Optional: store gst separately
      "total": finalTotal,  // This ensures History Tab shows the full amount
      "time": DateTime.now(),
    });

    // 4. Clear the Table
    runningTables.remove(t);
    _saveData();
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("✅ Bill Settled & Stock Updated!"), backgroundColor: Colors.green),
  );
}

Future<void> _printDocument(String tableNum, {required bool isKOT}) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    
    // Safety check: ensure table still has items
    if (!runningTables.containsKey(tableNum)) return;
    final items = runningTables[tableNum]!;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          double subtotal = items.fold(0, (sum, item) => sum + ((item['price'] ?? 0) * (item['qty'] ?? 1)));
          double gst = (isGstEnabled && _gstCtrl.text.isNotEmpty) ? (subtotal * 0.05) : 0;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
            if (!isKOT && restaurantLogo != null)
                pw.Center(
                  child: pw.Container(
                    height: 50, // Reduced slightly to save thermal paper
                    child: pw.Image(
                      pw.MemoryImage(restaurantLogo!.readAsBytesSync()),
                    ),
                  ),
                ),
              if (!isKOT && restaurantLogo != null) pw.SizedBox(height: 5),
              if (!isKOT) ...[
                pw.Center(child: pw.Text(_nameCtrl.text.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
                pw.Center(child: pw.Text(_addressCtrl.text, style: const pw.TextStyle(fontSize: 9))),
                pw.Center(child: pw.Text("Ph: ${_phoneCtrl.text}", style: const pw.TextStyle(fontSize: 9))),
                if (_gstCtrl.text.isNotEmpty) pw.Center(child: pw.Text("GSTIN: ${_gstCtrl.text}", style: const pw.TextStyle(fontSize: 9))),
                pw.Divider(thickness: 0.5),
              ],
              
              pw.Center(child: pw.Text(isKOT ? "KITCHEN ORDER" : "TAX INVOICE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
              pw.SizedBox(height: 5),
              pw.Text("Table: $tableNum", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Date: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}"),
              pw.Divider(thickness: 0.5),

              // Items and Special Requests
           // Items and Special Requests
...items.map((item) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(children: [
        pw.Expanded(child: pw.Text("${item['name']} x${item['qty']}", style: const pw.TextStyle(fontSize: 10))),
     if (!isKOT) pw.Text("Rs. ${((item['price'] ?? 0) * (item['qty'] ?? 1)).toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
      ]),
      if (item['request'] != null && item['request'].toString().isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10),
          child: pw.Text("  * Note: ${item['request']}", 
            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
          ),
        ),
    ],
  );
}).toList(),

             pw.Divider(thickness: 0.5),
              if (!isKOT) ...[
                // Row 1: Subtotal
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text("Rs. ${subtotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),

                // Row 2: GST (Only shows if toggle is ON and GST No is entered)
                if (isGstEnabled && gst > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("GST (5%):", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Rs. ${gst.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                
                pw.SizedBox(height: 4),
                
                // Row 3: Grand Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text("Rs. ${(subtotal + gst).toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
                
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text("THANK YOU!", style: const pw.TextStyle(fontSize: 10))),
              ]
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _getHostIp();
    _startServer();
    _loadData();
  }
void _exportHistory() async {
  var excel = Excel.createExcel();
  Sheet sheet = excel['Sales_Report'];
  
  // Use TextCellValue for every string in the row
  sheet.appendRow([
    TextCellValue("Bill No"), 
    TextCellValue("Table"), 
    TextCellValue("Total"), 
    TextCellValue("Time")
  ]);
  
 for (var b in billHistory) {
      sheet.appendRow([
        TextCellValue(b['billNo'].toString()), 
        TextCellValue(b['table'].toString()), 
        TextCellValue(b['total'].toString()), 
        TextCellValue(b['time'].toString())
      ]);
    }

    // --- START: This part was missing/cut off ---
    final dir = await getDownloadsDirectory(); 
    if (dir == null) return;

    final file = File('${dir.path}/Sales_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Report Saved to: ${file.path}"), backgroundColor: Colors.green),
      );
    }
  } // <--- THIS BRACE ENDS _exportHistory

  // --- NOW ADD THE IMPORT FUNCTION AS A SEPARATE MEMBER ---
  void _importMenuFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      setState(() {
        for (var table in excel.tables.keys) {
          for (var i = 1; i < excel.tables[table]!.maxRows; i++) {
            var row = excel.tables[table]!.rows[i];
            if (row.isEmpty) continue;

            String name = row[0]?.value.toString() ?? "";
            double price = double.tryParse(row[1]?.value.toString() ?? "0") ?? 0;
            String cat = row[2]?.value.toString() ?? "General";
            String link = row[3]?.value.toString() ?? name;
            double initialQty = double.tryParse(row[4]?.value.toString() ?? "100") ?? 100;

            if (name.isNotEmpty) {
              menuItems[name] = [price, cat, link];
              if (!stockItems.containsKey(link)) {
                stockItems[link] = [initialQty, 0.0]; 
              }
            }
          }
        }
        _saveData();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Menu & Stock Imported Successfully!"), backgroundColor: Colors.green),
        );
      }
    }
  }
  void _clearHistory() {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Clear All Sales?"),
      content: const Text("This will delete all history and reset the bill counter. This cannot be undone!"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            setState(() {
              billHistory.clear();
              billCounter = 1; // Reset bill numbering
              _saveData();
            });
            Navigator.pop(ctx);
          }, 
          child: const Text("CLEAR EVERYTHING")
        ),
      ],
    ),
  );
}

Future<void> _saveData() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/restaurant_data.json');
    
    // Map history to convert DateTime to String for JSON
    final historyJson = billHistory.map((b) => {
      ...b,
      'time': b['time'] is DateTime ? b['time'].toIso8601String() : b['time'],
    }).toList();

    final data = {
      'stock': stockItems,
      'menu': menuItems,
      'history': historyJson,
      'billCounter': billCounter,
      'staff': staff,
      'tables': tables,
      'logoPath': restaurantLogo?.path, // Save the logo path too!
    };
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> _loadData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/restaurant_data.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        setState(() {
          stockItems = Map<String, List<dynamic>>.from(data['stock']);
          menuItems = Map<String, List<dynamic>>.from(data['menu']);
          billCounter = data['billCounter'] ?? 1;
          staff = List<String>.from(data['staff'] ?? staff);
          tables = List<String>.from(data['tables'] ?? tables);
          if (data['logoPath'] != null) restaurantLogo = File(data['logoPath']);
          
          // Convert String back to DateTime
          billHistory = (data['history'] as List).map((b) => {
            ...Map<String, dynamic>.from(b),
            'time': DateTime.parse(b['time']),
          }).toList();
        });
      }
    } catch (e) { print("Load Error: $e"); }
  }

  Future<void> _getHostIp() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) setState(() => localIp = addr.address);
      }
    }
  }

  void _startServer() async {
    try {
      var server = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
      server.listen(_handleRequests);
    } catch (e) { print(e); }
  }

void _handleRequests(HttpRequest request) async {
    // 1. Setup CORS so the phone is allowed to connect
    request.response.headers.add("Access-Control-Allow-Origin", "*");
    request.response.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    request.response.headers.add("Access-Control-Allow-Headers", "Origin, Content-Type, Accept");

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    // 2. Handle GET (When the phone asks for Menu and Tables)
    if (request.method == 'GET') {
      final data = {
        "menu": menuItems,
        "tables": tables,
        "isDayStarted": isDayStarted
      };
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(data));
    } 
    
    // 3. Handle POST (When the phone sends an order)
    else if (request.method == 'POST') {
      try {
        var content = await utf8.decoder.bind(request).join();
        var data = jsonDecode(content);
        if (mounted) {
          setState(() {
            String t = data['table'].toString();
            List items = data['items'];
            runningTables.putIfAbsent(t, () => []).addAll(items.cast<Map<String, dynamic>>());
            
            // Stock Subtraction Logic
            for (var item in items) {
              String itemName = item['name'];
              int qty = item['qty'] ?? 1;
              String stockKey = menuItems[itemName]?[2] ?? ""; // Index 2 is the Link
              if (stockItems.containsKey(stockKey)) {
                stockItems[stockKey]![0] -= qty;
              }
            }
            _saveData();
          });
        }
        request.response.write(jsonEncode({"status": "success"}));
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
      }
    }
    await request.response.close();
  }

@override
  Widget build(BuildContext context) {
    // 1. Check if the trial period is over
    bool isExpired = DateTime.now().isAfter(expiryDate);

    // 2. THE GATE: If expired and not licensed, show ONLY the lock screen
    if (isExpired && !isLicensed) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: _buildLockScreen(),
      );
    }

    // 3. THE MAIN APP: This runs only if the trial is active OR you entered the key
    return DefaultTabController(
      length: 6, // Matches your 6 tabs: LIVE, STOCK, MENU, STAFF, PROFILE, HISTORY
      child: Scaffold(
        appBar: AppBar(
          title: Text(_nameCtrl.text, style: const TextStyle(color: Colors.orange)),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDayStarted ? Colors.red : Colors.green,
                ),
                onPressed: () => setState(() => isDayStarted = !isDayStarted),
                child: Text(isDayStarted ? "END DAY" : "START DAY"),
              ),
            )
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: "LIVE DASH"), 
              Tab(text: "STOCK"), 
              Tab(text: "MENU"), 
              Tab(text: "STAFF"), 
              Tab(text: "PROFILE"), 
              Tab(text: "HISTORY"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboard(),
            _managerView(stockItems, ["Qty", "Cost"], "ADD STOCK"),
            _managerView(menuItems, ["Price", "Cat", "Link"], "ADD MENU ITEM"),
            _buildStaffTableManager(),
            _buildProfileInfo(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

Widget _buildDashboard() {
    if (!isDayStarted) return const Center(child: Text("Day Not Started", style: TextStyle(fontSize: 24, color: Colors.grey)));
    
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, 
        crossAxisSpacing: 10, 
        mainAxisSpacing: 10
      ),
      itemCount: tables.length,
      itemBuilder: (ctx, i) {
        String t = tables[i];
        bool active = runningTables.containsKey(t);
        
        return InkWell(
          onTap: active ? () => _showActions(t) : () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Table $t is empty")));
          },
          child: Card(
            color: active ? Colors.orange : Colors.grey[900],
            child: Center(
              child: Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))
            ),
          ),
        );
      },
    );
  }
  Widget _buildProfileInfo() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _pField("Restaurant Name", _nameCtrl),
        _pField("Address", _addressCtrl),
        _pField("Phone", _phoneCtrl),
        _pField("GST No", _gstCtrl),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Apply GST (5%) on Bills", style: TextStyle(color: Colors.orange)),
          subtitle: Text(isGstEnabled ? "GST is currently active" : "GST is disabled"),
          value: isGstEnabled,
          activeColor: Colors.orange,
          onChanged: (val) => setState(() => isGstEnabled = val),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Restaurant Logo", style: TextStyle(color: Colors.orange)),
          subtitle: Text(restaurantLogo == null ? "No logo selected" : "Logo updated: ${restaurantLogo!.path.split(Platform.pathSeparator).last}"),
          trailing: ElevatedButton.icon(
            icon: const Icon(Icons.image, size: 18),
            label: const Text("UPLOAD"),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
              if (result != null) {
                setState(() => restaurantLogo = File(result.files.single.path!));
              }
            },
          ),
        ),
        const Divider(),
        const Text("SERVER IP:", style: TextStyle(color: Colors.orange)),
        SelectableText(localIp ?? "Loading...", style: const TextStyle(fontSize: 24, color: Colors.greenAccent)),
      ],
    );
  }

  Widget _pField(String l, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(controller: c, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())),
  );

  Widget _managerView(Map d, List<String> labels, String btnText) {
  return Column(
    children: [
      const SizedBox(height: 10),
      // Put buttons in a Row so they stay organized
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. The standard Add Button (Stock or Menu)
          ElevatedButton(
            onPressed: () => _addItemDialog(d, labels),
            child: Text(btnText),
          ),

          // 2. The Import Button (Only shows on the Menu tab)
          if (btnText == "ADD MENU ITEM") ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: _importMenuFromExcel,
              icon: const Icon(Icons.upload_file),
              label: const Text("IMPORT EXCEL"),
            ),
          ],
        ],
      ),
      const SizedBox(height: 10),
      
      // 3. The List of Items
      Expanded(
        child: ListView(
          children: d.entries.map((e) => ListTile(
            title: Text(e.key),
            subtitle: Text(e.value.toString()),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  d.remove(e.key);
                  _saveData();
                });
              },
            ),
          )).toList(),
        ),
      ),
    ],
  );
}

void _addItemDialog(Map d, List<String> labels) {
    TextEditingController nameCtrl = TextEditingController();
    List<TextEditingController> controllers = List.generate(labels.length, (i) => TextEditingController());
    
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Add New Entry", style: TextStyle(color: Colors.orange)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Item Name")),
          ...List.generate(labels.length, (i) => TextField(
            controller: controllers[i], 
            decoration: InputDecoration(labelText: labels[i])
          )),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
        ElevatedButton(onPressed: () {
          setState(() {
            if (nameCtrl.text.isNotEmpty) {
              // This stores the inputs as numbers where possible
              d[nameCtrl.text] = controllers.map((c) => double.tryParse(c.text) ?? c.text).toList();
              _saveData();
            }
          });
          Navigator.pop(ctx);
        }, child: const Text("SAVE")),
      ],
    ));
  }

Widget _buildStaffTableManager() {
    return Row(children: [
      Expanded(child: _sList(staff, "Staff")),
      const VerticalDivider(width: 1),
      Expanded(child: _sList(tables, "Tables")),
    ]);
  }

  Widget _sList(List<String> l, String title) {
    // We use a local controller inside the build method with care, 
    // but for a 3-day trial, this is the most stable way to handle quick additions.
    final TextEditingController c = TextEditingController();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(title, style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: l.length,
          itemBuilder: (ctx, i) => ListTile(
            title: Text(l[i]),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => setState(() => l.removeAt(i)),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: c,
          onSubmitted: (v) {
            if (v.isNotEmpty) {
              setState(() {
                l.add(v);
                _saveData();
                c.clear();
              });
            }
          },
          decoration: InputDecoration(
            hintText: "Add New $title...",
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.add),
          ),
        ),
      ),
    ]);
  }

Widget _buildHistoryTab() {
  double totalRevenue = billHistory.fold(0, (sum, bill) => sum + (bill['total'] ?? 0));

  if (billHistory.isEmpty) {
    return const Center(
      child: Text("No Sales Recorded Yet", style: TextStyle(color: Colors.grey, fontSize: 18)),
    );
  }

  return Column(
    children: [
     Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        color: Colors.green.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL REVENUE", style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
                Text("₹${totalRevenue.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
            Row( 
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                  onPressed: _clearHistory, 
                  icon: const Icon(Icons.delete_sweep, size: 18), 
                  label: const Text("CLEAR"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                  onPressed: _exportHistory, 
                  icon: const Icon(Icons.description, size: 18), 
                  label: const Text("EXPORT"),
                ),
              ],
            ),
          ],
        ),
      ), // This closing parenthesis and comma are likely what was missing!
      const Divider(height: 1),
      Expanded(
        child: ListView.builder(
          itemCount: billHistory.length,
          itemBuilder: (ctx, i) {
            var bill = billHistory[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: const Color(0xFF161B22),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text("${bill['billNo']}", style: const TextStyle(color: Colors.black)),
                ),
                title: Text("Table ${bill['table']} - ₹${bill['total'].toStringAsFixed(2)}"),
                subtitle: Text("Time: ${bill['time'].toString().substring(11, 16)}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _viewBillDetail(bill),
              ),
            );
          },
        ),
      ),
    ],
  );
}

void _viewBillDetail(Map bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D2127),
        title: Text("Bill #${bill['billNo']} Details", style: const TextStyle(color: Colors.orange)),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: (bill['items'] as List).map((item) {
              return ListTile(
                title: Text("${item['name']}", style: const TextStyle(color: Colors.white)),
                // ADD THE NOTE HERE
                subtitle: item['request'] != null && item['request'].toString().isNotEmpty
                    ? Text("Note: ${item['request']}", style: TextStyle(color: Colors.orange[200], fontSize: 11))
                    : null,
                trailing: Text("x${item['qty']} - ₹${(item['price'] * item['qty']).toStringAsFixed(2)}"),
              );
            }).toList(),
          ),
        ),
       actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  } // This closes _viewBillDetail

Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: Colors.black, // Makes it look more like a lock screen
      body: Center(
        child: Text(
          "TRIAL EXPIRED - PLEASE CONTACT ROSHAN",
          style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

} 
