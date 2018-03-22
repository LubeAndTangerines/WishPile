import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'dart:io';
import 'dart:convert';

void main() => runApp(new MaterialApp(home: new MyApp()));


//Global variables
List<String> _savedItems = [];
List<String> _gottenNames = ["Piim", "Leib", "Sink"];
List<String> _savedWishpiles = ["Töö", "Kodu"];
Map<String, String> _amounts = {};

final TextEditingController _itemInput = new TextEditingController();
final TextEditingController _amountInput = new TextEditingController();

//Main activator
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

//Home page widget
class MyHomePage extends StatefulWidget {

  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

//This has conent
class _MyHomePageState extends State<MyHomePage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<DrawerControllerState> _drawerKey = new GlobalKey<
      DrawerControllerState>();

  Color _tileColor = Colors.white;

  //Removes items with sync
  Future<Null> removeItem(int index) async {
    setState(() => _savedItems.removeAt(index));
  }

  //Adds items from API with sync
  Future<Null> addItemAPI(String name, int amount) async {
    setState(() {
      _savedItems.add(name);
      _amounts[name] = amount.toString();
    });
  }

  //Adds items in an sync way
  Future<Null> addItem() async {
    setState(() {
      _savedItems.add(_itemInput.text);
      _amounts[_itemInput.text] = _amountInput.text;
    });
  }

  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    if (_reload == 0) {
      getDataFromAPI();
      _reload++;
    }
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
        child: buildDrawerContent(context),
      ),

      //Generate the body
      body: buildWishPileItem,

      //FAB
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
          getDataFromAPI();
          addItemsView(context);
        },
        tooltip: 'Add an item',
        child: new Icon(Icons.add),
      ),
    );
  }

  ListView buildDrawerContent(BuildContext context) {
    return new ListView(
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
      );
  }

  //FAB functionality
  void addItemsView(BuildContext context) {
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

  //Read data from database and fill list with them
  getDataFromAPI() async {
    String id = "1";

    var httpClient = new HttpClient();
    var uri = new Uri.http(
        '159.89.107.237:1337', '/api/v1/piles/' + id + '/wishes',
        {'status': 'wished'});
    var request = await httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(UTF8.decoder).join();
    Map data = JSON.decode(responseBody);
    for (int i = 0; i < data['data']['resultCount']; i++) {
      addItemAPI(data['data']['result'][i]['wish'],
          data['data']['result'][i]['amount']);
    }
  }

}
