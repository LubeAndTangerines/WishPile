import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:wish_pile/decorations.dart';

void main() => runApp(new MaterialApp(home: new MyApp()));

//Global variables
List<String> _savedWishpiles = ["Töö", "Kodu"];

//Server IP
//String _serverIP = '159.89.107.237:1337';
String _localhost = "10.0.2.2:1337";

List<String> _savedID = [];
Map<String, String> _wishes = {};
Map<String, String> _amounts = {};

List<String> _gottenID = [];
List<String> _allIDs = [];
List<String> _tempIDs = [];

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

//This has content
class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<DrawerControllerState> _drawerKey =
      new GlobalKey<DrawerControllerState>();

  Color _tileColor = Colors.white;

  Future<Null> updateItemLocation(String wishID) async {
    setState(() {
      if (_savedID.contains(wishID)) {
        _savedID.remove(wishID);
        updateData(wishID, "checked");
        _gottenID.add(wishID);
        buildAllItems;
      } else {
        _gottenID.remove(wishID);
        updateData(wishID, "wished");
        _savedID.add(wishID);
        buildAllItems;
      }
    });
  }

  //Deleting items aka adding to archive
  Future<bool> updateData(String wishID, String method) async {
    String id = "1";
    String body = json.encode({
      "updateField": "status",
      "wishes": [
        {"id": int.parse(wishID), "status": method}
      ]
    });
    var httpClient = new HttpClient();
    var request = await httpClient.patch(
        '10.0.2.2', 1337, '/api/v1/piles/' + id + '/wishes');
    request.headers.contentType =
        new ContentType("application", "json", charset: "utf-8");
    request.write(body);

    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();

    return true;
  }

  //Editing wish description
  Future<bool> updateDescription(
      String wishID, String method, String newText) async {
    String id = "1";
    String body = json.encode({
      "updateField": method,
      "wishes": [
        {"id": int.parse(wishID), method: newText}
      ]
    });
    var httpClient = new HttpClient();
    var request = await httpClient.patch(
        '10.0.2.2', 1337, '/api/v1/piles/' + id + '/wishes');
    request.headers.contentType =
        new ContentType("application", "json", charset: "utf-8");
    request.write(body);

    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();

    return true;
  }

  //Removes items with sync
  Future<Null> removeItem(String wishID) async {
    setState(() {
      _savedID.remove(wishID);
      _allIDs.remove(wishID);
      updateData(wishID, "archived");
    });
  }

  //Adds items from API with sync
  Future<Null> addItemAPI(
      String pileID, String wishID, String name, String amount) async {
    setState(() {
      _savedID.add(wishID);
      _allIDs.add(wishID);
      _wishes[wishID] = name;
      _amounts[wishID] = amount;
    });
  }

  //Adds items in an sync way
  Future<Null> addItem() async {
    setState(() {
      String id = "1";
      if (sendData(id, _itemInput.text, _amountInput.text) != null) {
        addItemAPI(id, "null", _itemInput.text, _amountInput.text);
      }
    });
  }

  //Adds item to the database
  Future<bool> sendData(String id, String text, String amount) async {
    String body = json.encode({
      "wishes": [
        {"description": text, "amount": amount}
      ]
    });
    var httpClient = new HttpClient();
    var request = await httpClient.post(
        '10.0.2.2', 1337, '/api/v1/piles/' + id + '/wishes');
    request.headers.contentType =
        new ContentType("application", "json", charset: "utf-8");
    request.write(body);

    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    if (data['status'] == 201) {
      return true;
    }
    return false;
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
        leading: new IconButton(
          icon: new Icon(Icons.list),
          onPressed: () {
            _scaffoldKey.currentState.openDrawer();
          },
        ),
      ),

      drawer: new Drawer(
        key: _drawerKey,
        child: buildDrawerContent(context),
      ),

      //Generate the body
      body: buildAllItems,

      //FAB
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
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
        new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        new Text("Home"),
        new Divider(),
        new ListTile(
            leading: new Icon(Icons.settings), title: new Text("Settings")),
        new ListTile(
          leading: new Icon(Icons.share),
          title: new Text("Share"),
          onTap: () {
            share('check out my website https://example.com');
          },
        ),
        new Divider(),
        new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new Text("Your piles"),
            new IconButton(icon: new Icon(Icons.add), onPressed: null),
          ],
        ),
        new ListTile(
          leading: new Icon(Icons.view_list),
          title: new Text("Home"),
        ),
        new ListTile(
          leading: new Icon(Icons.view_list),
          title: new Text("Work"),
        )
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
                new Column(children: <Widget>[
                  new TextFormField(
                    controller: _itemInput,
                    decoration: new InputDecoration(
                      contentPadding:
                          new EdgeInsets.fromLTRB(16.0, 150.0, 16.0, 16.0),
                      hintText: 'Enter the item',
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  new TextFormField(
                    controller: _amountInput,
                    decoration: new InputDecoration(
                      contentPadding:
                          new EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                      hintText: 'Enter the amount',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ]),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new IconButton(
                        icon: new Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(false)),
                    new IconButton(
                        icon: new Icon(Icons.add),
                        onPressed: () {
                          if (_itemInput.text.length > 0) {
                            addItem();
                            Navigator.of(context).pop(true);
                          }
                        })
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void editItemsView(BuildContext context, String wishID) {
    TextEditingController _editingTextInput =
        new TextEditingController(text: _wishes[wishID]);
    TextEditingController _editingAmountInput =
        new TextEditingController(text: _amounts[wishID]);

    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Edit ' + _wishes[wishID]),
            ),
            body: new ListView(
              children: <Widget>[
                new Column(children: <Widget>[
                  new TextField(
                    controller: _editingTextInput,
                    decoration: new InputDecoration(
                      contentPadding:
                          new EdgeInsets.fromLTRB(16.0, 150.0, 16.0, 16.0),
                      hintText: 'Enter the item',
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  new TextField(
                    controller: _editingAmountInput,
                    decoration: new InputDecoration(
                      contentPadding:
                          new EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                      hintText: 'Enter the amount',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ]),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new IconButton(
                        icon: new Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(false)),
                    new IconButton(
                        icon: new Icon(Icons.edit),
                        onPressed: () {
                          if (_editingTextInput.text.length > 0) {
                            updateDescription(
                                wishID, "description", _editingTextInput.text);
                            updateDescription(wishID, "amount",
                                _editingAmountInput.text.toString());
                            _wishes[wishID] = _editingTextInput.text;
                            _amounts[wishID] = _editingAmountInput.text;

                            Navigator.of(context).pop(false);
                          }
                        }),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  //Test method to combine listViews using combining IDs.
  ListView get buildAllItems {
    _tempIDs = _savedID + _gottenID;
    return new ListView.builder(
      itemCount: _tempIDs != [] ? _tempIDs.length : 0.0,
      padding: new EdgeInsets.symmetric(vertical: 16.0),
      itemBuilder: (BuildContext context, int index) {
        var random = new Random();
        final wishID = _tempIDs[index];
        final wish = _wishes[wishID];
        if (_savedID.contains(wishID)) {
          return new Container(
            child: new Dismissible(
              key: new ObjectKey(
                  _wishes[wishID] + random.nextInt(10000).toString()),
              onDismissed: (direction) {
                updateItemLocation(wishID);
                Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text("$wish added to gotten pile")));
              },
              background: new Container(color: Colors.pink),
              child: buildExpansionTileForWishes(wishID, index),
            ),
          );
        } else {
          return new Container(
            foregroundDecoration: new StrikeThroughDecoration(),
            child: new Dismissible(
              key: new ObjectKey(
                  _wishes[wishID] + random.nextInt(10000).toString()),
              onDismissed: (direction) {
                updateItemLocation(wishID);
                Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text("$wish added to gotten pile")));
              },
              background: new Container(color: Colors.pink),
              child: buildExpansionTileForWishes(wishID, index),
            ),
          );
        }
      },
    );
  }

  //Generates the tile
  ExpansionTile buildExpansionTileForWishes(String wishID, int index) {
    if (_savedID.contains(wishID)) {
      return new ExpansionTile(
        backgroundColor: _tileColor,
        title: new Text(_wishes['$wishID']),
        trailing: new Text(_amounts['$wishID']),
        children: <Widget>[
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new IconButton(
                  icon: new Icon(Icons.edit),
                  onPressed: () {
                    editItemsView(context, wishID);
                  }),
              new IconButton(
                  icon: new Icon(Icons.delete),
                  onPressed: () {
                    removeItem('$wishID');
                  }),
            ],
          )
        ],
      );
    } else {
      return new ExpansionTile(
        backgroundColor: _tileColor,
        title: buildStrikeThroughText(wishID), //new Text(_wishes['$wishID']),
        trailing: new Text(_amounts['$wishID']),
        children: <Widget>[
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new IconButton(
                  icon: new Icon(Icons.edit),
                  onPressed: () {
                    //edit item
                  }),
              new IconButton(
                  icon: new Icon(Icons.delete),
                  onPressed: () {
                    removeItem('$wishID');
                  }),
            ],
          )
        ],
      );
    }
  }

  //Strike through text builder style.
  RichText buildStrikeThroughText(String item) {
    return new RichText(
      text: new TextSpan(
        children: <TextSpan>[
          new TextSpan(
            text: _wishes['$item'],
            style: new TextStyle(
              color: Colors.black,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  //Read data from database and fill list with them
  getDataFromAPI() async {
    String id = "1";
    var httpClient = new HttpClient();
//    var uri = new Uri.http(
//        _localhost, '/api/v1/piles/' + id + '/wishes', {'status': 'wished'});
    var uri = new Uri.http(
        _localhost, '/api/v1/piles/' + id + '/wishes', {'status': 'wished'});
    var request = await httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    emptyCurrentCache();
    for (int i = 0; i < data['data']['resultCount']; i++) {
      addItemAPI(
          id,
          data['data']['result'][i]['id'].toString(),
          data['data']['result'][i]['wish'],
          data['data']['result'][i]['amount'].toString());
    }
  }

  void emptyCurrentCache() {
    _allIDs = [];
    _savedID = [];
    _amounts = {};
    _wishes = {};
    _gottenID = [];
  }
}
