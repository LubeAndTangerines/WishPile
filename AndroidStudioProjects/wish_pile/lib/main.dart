import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share/share.dart';

void main() => runApp(new MaterialApp(home: new MyApp()));

List<String> _savedItems = ["Kana", "Muna", "Koeratoit"];
List<String> _gottenNames = ["Piim", "Leib", "Sink"];
List<String> _savedWishpiles = ["Töö", "Kodu"];
Map<String, String> _amounts = {"Kana": "1", "Muna": "12", "Koeratoit": "2"};

final TextEditingController _itemInput = new TextEditingController();
final TextEditingController _amountInput = new TextEditingController();


class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {

  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<DrawerControllerState> _drawerKey = new GlobalKey<
      DrawerControllerState>();

  Color _tileColor = Colors.white;


  Future<Null> removeItem(int index) async {
    setState(() => _savedItems.removeAt(index));
  }

  Future<Null> addItem() async {
    setState(() {
      _savedItems.add(_itemInput.text);
      _amounts[_itemInput.text] = _amountInput.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(

      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text("WishPile App"),
        leading: new IconButton(icon: new Icon(Icons.list), onPressed: () {
          _scaffoldKey.currentState.openDrawer();
        },),
      ),

      drawer: new Drawer(
        key: _drawerKey,
        child: new ListView(
          children: <Widget>[

            new IconButton(icon: new Icon(Icons.arrow_back), onPressed: () {
              Navigator.of(context).pop();
            }),
            new ListTile(
                leading: new Icon(Icons.settings),
                title: new Text("Settings")
            ),
            new ListTile(
              leading: new Icon(Icons.share),
              title: new Text("Share"),
              onTap: () {
                share('check out my website https://example.com');
              },
            ),

          ],
        ),
      ),

      //Generate the body
      body: buildWishPileItem,

      //FAB
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            new MaterialPageRoute(
              builder: (context) {
                return new Scaffold(
                  appBar: new AppBar(
                    title: new Text('Add an item'),
                  ),
                  body: new ListView(
                    children: <Widget>[
                      new TextFormField(
                        controller: _itemInput,
                        decoration: new InputDecoration(
                          hintText: 'Enter the item',
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      new TextFormField(
                        controller: _amountInput,
                        decoration: new InputDecoration(
                          hintText: 'Enter the amount',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      new Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          new IconButton(icon: new Icon(Icons.arrow_back),
                              onPressed: () =>
                                  Navigator.pop(context, true)),
                          new IconButton(
                              icon: new Icon(Icons.add), onPressed: () {
                            if (_itemInput.text.length > 0) {
                              addItem();
                              Navigator.pop(context, "Add");
                            }
                          })
                        ],),
                    ],
                  ),
                );
              },
            ),
          );
        },
        tooltip: 'Add an item',
        child: new Icon(Icons.add),
      ),
    );
  }


  // Build the wish pile tiles.
  ListView get buildWishPileItem {
    return new ListView.builder(
      itemCount: _savedItems != [] ? _savedItems.length : 0.0,
      padding: new EdgeInsets.symmetric(vertical: 16.0),
      itemBuilder: (BuildContext context, int index) {
        final item = _savedItems[index];
        return new Dismissible(
          key: new ObjectKey(item),
          onDismissed: (direction) {
            _savedItems.removeAt(index);
            Scaffold.of(context).showSnackBar(
                new SnackBar(content: new Text("$item added to gotten pile")));
          },
          background: new Container(color: Colors.pink),
          child: buildExpansionTile(item, index),
        );
      },);
  }

  //Generates the tile
  ExpansionTile buildExpansionTile(String item, int index) {
    return new ExpansionTile(
      backgroundColor: _tileColor,
      title: new Text('$item'),
      trailing: new Text(_amounts['$item']),
      children: <Widget>[
        new Row (
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            new IconButton(icon: new Icon(Icons.edit), onPressed: () {
              //edit item
            }),
            new IconButton(
                icon: new Icon(Icons.delete), onPressed: () {
              removeItem(index);
            }),
          ],
        )
      ],
    );
  }
}
