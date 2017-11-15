import 'package:flutter/material.dart';

class Transactions extends StatefulWidget {
  const Transactions({Key key}) : super(key: key);

  static const String routeName = '/transactions';

  @override
  _TransactionsState createState() => new _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  static final GlobalKey<ScaffoldState> scaffoldKey =
      new GlobalKey<ScaffoldState>();

  // FIXME(simon): Example data.
  List<String> items = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
  ];

  Widget buildListTile(BuildContext context, String item) {
    Widget secondary = const Text(
      'Even more additional list item information appears on line three.',
    );
    return new MergeSemantics(
      child: new ListTile(
        isThreeLine: true,
        dense: false,
        leading: new ExcludeSemantics(
            child: new CircleAvatar(child: new Text(item))),
        title: new Text('This item represents $item.'),
        subtitle: secondary,
        trailing: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> listTiles =
        items.map((String item) => buildListTile(context, item));

    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Text('Transactions'),
      ),
      body: new Scrollbar(
        child: new ListView(
          padding: new EdgeInsets.symmetric(vertical: 8.0),
          children: listTiles.toList(),
        ),
      ),
    );
  }
}
