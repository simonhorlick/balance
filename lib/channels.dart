import 'package:flutter/material.dart';

class Channels extends StatefulWidget {
  const Channels({Key key}) : super(key: key);

  static const String routeName = '/channels';

  @override
  _ChannelsState createState() => new _ChannelsState();
}

class _ChannelsState extends State<Channels> {
  static final GlobalKey<ScaffoldState> scaffoldKey =
      new GlobalKey<ScaffoldState>();

  // FIXME(simon): Example data.
  List<String> items = <String>[
    'A',
    'B',
    'C',
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

    return new Scrollbar(
      child: new ListView(
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        children: listTiles.toList(),
      ),
    );
  }
}
