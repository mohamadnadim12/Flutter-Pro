import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardModel()),
      ],
      child: MaterialApp(
        title: 'Dashboard App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: DashboardScreen(),
      ),
    );
  }
}

class DashboardModel with ChangeNotifier {
  final CollectionReference itemsCollection = FirebaseFirestore.instance.collection('items');

  Future<void> addItem(String text, String imageUrl) async {
    if (text.isNotEmpty && imageUrl.isNotEmpty) {
      await itemsCollection.add({'text': text, 'imageUrl': imageUrl});
      Fluttertoast.showToast(msg: "Item added successfully");
    } else {
      Fluttertoast.showToast(msg: "Text and Image URL cannot be empty");
    }
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await itemsCollection.doc(id).delete();
    Fluttertoast.showToast(msg: "Item deleted successfully");
    notifyListeners();
  }

  Stream<QuerySnapshot> get itemsStream => itemsCollection.snapshots();
}

class DashboardScreen extends StatelessWidget {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Enter text'),
                    controller: _textController,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Enter image URL'),
                    controller: _imageController,
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    Provider.of<DashboardModel>(context, listen: false)
                        .addItem(_textController.text, _imageController.text);
                    _textController.clear();
                    _imageController.clear();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<DashboardModel>(
              builder: (context, model, child) {
                return StreamBuilder<QuerySnapshot>(
                  stream: model.itemsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final data = item.data() as Map<String, dynamic>;
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          child: ListTile(
                            leading: Image.network(data['imageUrl']),
                            title: Text(data['text']),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Confirm Delete'),
                                    content: Text('Are you sure you want to delete this item?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Provider.of<DashboardModel>(context, listen: false)
                                              .deleteItem(item.id);
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
