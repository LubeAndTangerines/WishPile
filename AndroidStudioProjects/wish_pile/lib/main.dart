import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:wish_pile/decorations.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(new MaterialApp(home: new MyApp()));

//WishPile variables
Map<String, String> _savedWishPiles = {};
String _activeWishPileID = "";
String _wishPileName = "";
String _wishPileDescription = "";
String _wishPileLink = "";

//Server IP
//String _serverIP = '159.89.107.237:1337';
String _localhost = "10.0.2.2:1337";

//Wish storage variables
List<String> _savedID = [];
Map<String, String> _wishes = {};
Map<String, String> _amounts = {};

//Individual storage variables
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
      title: 'WishPile',
      theme: new ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: new MyHomePage(title: 'WishPile'),
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

  //Dismissible relocation action
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

  //Changing wish status wished/checked/archived
  Future<bool> updateData(String wishID, String method) async {
    String body = json.encode({
      "updateField": "status",
      "wishes": [
        {"id": int.parse(wishID), "status": method}
      ]
    });
    var httpClient = new HttpClient();
    var request = await httpClient.patch(
        '10.0.2.2', 1337, '/api/v1/piles/' + _activeWishPileID + '/wishes');
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
    String body = json.encode({
      "updateField": method,
      "wishes": [
        {"id": int.parse(wishID), method: newText}
      ]
    });
    var httpClient = new HttpClient();
    var request = await httpClient.patch(
        '10.0.2.2', 1337, '/api/v1/piles/' + _activeWishPileID + '/wishes');
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
      if (_savedID.contains(wishID)) _savedID.remove(wishID);
      if (_gottenID.contains(wishID)) _gottenID.remove(wishID);
      _allIDs.remove(wishID);
      updateData(wishID, "archived");
    });
  }

  //Adds items from API with sync
  Future<Null> addWishesFromAPI(String pileID, String wishID, String name,
      String amount, String status) async {
    setState(() {
      if (status == "wished") {
        _savedID.add(wishID);
      } else if (status == "checked") {
        _gottenID.add(wishID);
      }
      _allIDs.add(wishID);
      _wishes[wishID] = name;
      _amounts[wishID] = amount;
    });
  }

  //Adds items in an sync way
  Future<Null> addItem() async {
    setState(() {
      if (sendData(_activeWishPileID, _itemInput.text, _amountInput.text) !=
          null) {
        addWishesFromAPI(_activeWishPileID, "null", _itemInput.text,
            _amountInput.text, "wished");
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

  //Get the path from phone
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  //Get the file from phone
  Future<File> get _localFile async {
    final path = await _localPath;
    return new File('$path/data.json');
  }

  //Write data as json to phone
  Future<File> writeDataToPhone() async {
    final file = await _localFile;

    Map data = new Map();
    List dataParsed = [];
    for (int i = 0; i < _savedWishPiles.keys.length; i++) {
      data = {};
      data['pileID'] = _savedWishPiles.keys.toList()[i];
      data["name"] = _savedWishPiles[_savedWishPiles.keys.toList()[i]];
      dataParsed.add(data);
    }
    String body = json.encode({
      "data": {"pileAmount": _savedWishPiles.keys.length, "piles": dataParsed}
    });
    print(body);
    return file.writeAsString(body);
  }

  //Get json if it exists
  Future<String> readDataFromPhone() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      try {
        Map data = json.decode(contents);
        _activeWishPileID = data["data"]["piles"][0]["pileID"];
        for (int i = 0; i < data["data"]["piles"].length; i++) {
          _savedWishPiles[data["data"]["piles"][i]["pileID"]] =
          data["data"]["piles"][i]["name"];
        }
        readDataFromAPI(_activeWishPileID);
        getWishPileName();
        getWishPileDescription();
        getWishPileLink();
      } catch (e) {
        return "";
      }
      return contents;
    } catch (e) {
      return "";
    }
  }

  //Main method
  @override
  Widget build(BuildContext context) {
    if (_reload == 0) {
      _reload++;
      readDataFromPhone();
      getWishPileName();
      getWishPileDescription();
      getWishPileLink();
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

  //Get wished and checked objects
  void readDataFromAPI(String pileID) {
    emptyCurrentCache();
    getWishedDataFromAPI(pileID);
    getCheckedDataFromAPI(pileID);
  }

  //Get wishPile name for drawer display
  String getWishPileName() {
    if (_activeWishPileID != "") {
      final future = getExistingWishPile(context, _activeWishPileID, "name");
      future.then((value) {
        _wishPileName = value;
        return value;
      });
    }
    return "ERROR";
  }

  //get wishPile description for drawer display
  String getWishPileDescription() {
    if (_activeWishPileID != "") {
      final future =
          getExistingWishPile(context, _activeWishPileID, "description");
      future.then((value) {
        _wishPileDescription = value;
        return value;
      });
    }
    return "ERROR";
  }

  //get wishPile share link
  String getWishPileLink() {
    if (_activeWishPileID != "") {
      final future = getExistingWishPile(context, _activeWishPileID, "link");
      future.then((value) {
        _wishPileLink = value;
        return value;
      });
    }
    return "ERROR";
  }

  //Drawer method
  Drawer buildDrawerContent(BuildContext context) {
    return new Drawer(
      child: new ListView(
        padding: const EdgeInsets.only(top: 0.0),
        children: _buildDrawerChildren(),
      ),
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

  //Edit items
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

  //wishPile adding choice
  void chooseWishPileAddingMethod(context) {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return new Scaffold(
          appBar: new AppBar(
            title: new Text("Choose WishPile adding method"),
          ),
          body: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  new FlatButton.icon(
                    onPressed: () {
                      addNewWishPileView(context);
                    },
                    icon: new Icon(
                      Icons.add,
                      size: 24.0,
                    ),
                    label: new Text(
                      "Add a new WishPile",
                      style: new TextStyle(fontSize: 24.0),
                    ),
                  ),
                ],
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  new FlatButton.icon(
                    onPressed: () {
                      addExistingWishPileView(context);
                    },
                    icon: new Icon(
                      Icons.add_shopping_cart,
                      size: 24.0,
                    ),
                    label: new Text("Add an exisiting WishPile",
                        style: new TextStyle(fontSize: 24.0)),
                  ),
                ],
              ),
            ],
          ));
    }));
  }

  //Add wishPile from code
  void addExistingWishPileView(BuildContext context) {
    TextEditingController _wishPileName = new TextEditingController();
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Add a new WishPile'),
            ),
            body: new ListView(
              children: <Widget>[
                new Column(children: <Widget>[
                  new TextFormField(
                    controller: _wishPileName,
                    decoration: new InputDecoration(
                      contentPadding:
                          new EdgeInsets.fromLTRB(16.0, 150.0, 16.0, 16.0),
                      hintText: 'Code of your excisting WishPile',
                    ),
                    keyboardType: TextInputType.text,
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
                          if (_wishPileName.text.length > 0) {
                            final future = getExistingWishPile(
                                context, _wishPileName.text, "get");
                            future.then((pileID) {
                              _savedWishPiles[pileID] = _wishPileName.text;
                              _activeWishPileID = pileID;
                              writeDataToPhone();
                              readDataFromAPI(pileID);
                              getWishPileName();
                              getWishPileDescription();
                              getWishPileLink();
                              Navigator.of(context).pop(true);
                            });
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

  //Add new WishPile
  void addNewWishPileView(BuildContext context) {
    TextEditingController _wishPileName = new TextEditingController();
    TextEditingController _wishPileDescription = new TextEditingController();

    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Add a new WishPile'),
            ),
            body: new ListView(
              children: <Widget>[
                new Column(children: <Widget>[
                  new TextFormField(
                    controller: _wishPileName,
                    decoration: new InputDecoration(
                      contentPadding:
                          new EdgeInsets.fromLTRB(16.0, 150.0, 16.0, 16.0),
                      hintText: 'Name of your new WishPile',
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  new TextFormField(
                    controller: _wishPileDescription,
                    decoration: new InputDecoration(
                      contentPadding:
                          new EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                      hintText: 'Description of your WishPile',
                    ),
                    keyboardType: TextInputType.multiline,
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
                          if (_wishPileName.text.length > 0) {
                            final future = addNewWishPile(
                                _wishPileName.text, _wishPileDescription.text);
                            future.then((pileID) {
                              _savedWishPiles[pileID] = _wishPileName.text;
                              _activeWishPileID = pileID;
                              writeDataToPhone();
                              readDataFromAPI(pileID);
                              getWishPileName();
                              getWishPileDescription();
                              getWishPileLink();
                              Navigator.of(context).pop(true);
                            });
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

  //Test method to combine listViews using combining IDs.
  ListView get buildAllItems {
    _tempIDs = _savedID + _gottenID;
    if (_tempIDs == []) {
      return new ListView(
        padding: new EdgeInsets.symmetric(vertical: 16.0),
      );
    }

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
  }

  //Read data from database and fill list with them
  getWishedDataFromAPI(String pileID) async {
    if (pileID != "") {
      var httpClient = new HttpClient();
      var uri = new Uri.http(_localhost, '/api/v1/piles/' + pileID + '/wishes',
          {'status': 'wished'});
      var request = await httpClient.getUrl(uri);
      var response = await request.close();
      var responseBody = await response.transform(utf8.decoder).join();
      Map data = json.decode(responseBody);
      for (int i = 0; i < data['data']['resultCount']; i++) {
        addWishesFromAPI(
            pileID,
            data['data']['result'][i]['id'].toString(),
            data['data']['result'][i]['wish'],
            data['data']['result'][i]['amount'].toString(),
            "wished");
      }
    }
  }

  getCheckedDataFromAPI(String pileID) async {
    if (pileID != "") {
      var httpClient = new HttpClient();
      var uri = new Uri.http(_localhost, '/api/v1/piles/' + pileID + '/wishes',
          {'status': 'checked'});
      var request = await httpClient.getUrl(uri);
      var response = await request.close();
      var responseBody = await response.transform(utf8.decoder).join();
      Map data = json.decode(responseBody);
      for (int i = 0; i < data['data']['resultCount']; i++) {
        addWishesFromAPI(
            pileID,
            data['data']['result'][i]['id'].toString(),
            data['data']['result'][i]['wish'],
            data['data']['result'][i]['amount'].toString(),
            "checked");
      }
    }
  }

  void emptyCurrentCache()  async {
    setState(() {
      _allIDs = [];
      _tempIDs = [];
      _savedID = [];
      _amounts = {};
      _wishes = {};
      _gottenID = [];
    });
  }

  Future<String> getExistingWishPile(
      BuildContext context, String pileID, String method) async {
    var httpClient = new HttpClient();
    var uri = new Uri.http(_localhost, '/api/v1/piles/' + pileID);
    var request = await httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    if (method == "name") {
      return data["data"]["result"]["name"];
    } else if (method == "description") {
      return data["data"]["result"]["description"];
    } else if (method == "get") {
      return data["data"]["result"]["id"].toString();
    } else if (method == "link") {
      return data["data"]["result"]["link"].toString();
    }
    return "";
  }

  Future<String> addNewWishPile(String name, String description) async {
    String body = json.encode({"name": name, "description": description});
    var httpClient = new HttpClient();
    var request = await httpClient.post('10.0.2.2', 1337, '/api/v1/piles/');
    request.headers.contentType =
        new ContentType("application", "json", charset: "utf-8");
    request.write(body);

    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    return data["data"]["id"].toString();
  }

  List<Widget> _buildDrawerChildren() {
    List<Widget> children = [];
    children
      ..addAll(_drawerHeader())
      ..addAll(_settings())
      ..addAll([new Divider()])
      ..addAll(_wishPileHeader())
      ..addAll([new Divider()])
      ..addAll(_wishPileGenerator());
    return children;
  }

  List<Widget> _drawerHeader() {
    return [
      new DrawerHeader(
        child: new ListView(
          //padding: new EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
          children: <Widget>[
            new ListTile(
              title: new Text(
                _wishPileName,
                style:
                    new TextStyle(fontFamily: "Roboto Medium", fontSize: 18.0),
              ),
            ),
            new ListTile(
              title: new Text(
                _wishPileDescription,
                style: new TextStyle(
                    fontFamily: "Roboto Regular,", fontSize: 14.0),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _settings() {
    return [
      new ListTile(
          leading: new Icon(Icons.settings), title: new Text("Settings")),
      new ListTile(
        leading: new Icon(Icons.share),
        title: new Text("Share"),
        onTap: () {
          share('Add a new WishPile with the code of ' + _wishPileLink);
        },
      ),
    ];
  }

  List<Widget> _wishPileHeader() {
    return [
      new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          new Container(
            padding: new EdgeInsets.all(16.0),
            child: new Text("Your piles"),
          ),
          new IconButton(
              icon: new Icon(Icons.add),
              onPressed: () {
                chooseWishPileAddingMethod(context);
              }),
        ],
      ),
    ];
  }

  List<Widget> _wishPileGenerator() {
    List<Widget> listTiles = [];
    _savedWishPiles.keys.toList().forEach((wishPile) {
      listTiles.add(new ListTile(
        title: new Text(_savedWishPiles[wishPile]),
        leading: new Icon(Icons.list),
        onTap: () {
          _activeWishPileID = wishPile;
          emptyCurrentCache();
          readDataFromAPI(wishPile);
          getWishPileName();
          getWishPileDescription();
          getWishPileLink();
          Navigator.of(context).pop(true);
        },
      ));
    });
    return listTiles;
  }
}
