import 'package:flutter/material.dart';

class WelcomePageEntry {
  final String descriptionText;
  final String headerText;
  final IconData icon;

  WelcomePageEntry(this.icon, this.headerText, this.descriptionText);
}

class _PageSelector extends StatelessWidget {
  const _PageSelector({this.pages});

  final List<WelcomePageEntry> pages;

  @override
  Widget build(BuildContext context) {
    final TabController controller = DefaultTabController.of(context);

    return new Column(
      children: <Widget>[
        new Expanded(
          child: new TabBarView(
              children: pages.map((WelcomePageEntry page) {
            var entries = [
              new Icon(page.icon, size: 300.0, color: Colors.blueAccent),
              new Text(page.headerText,
                  textAlign: TextAlign.center,
                  style:
                      new TextStyle(color: Colors.blueAccent, fontSize: 26.0)),
              new Text(page.descriptionText,
                  textAlign: TextAlign.center,
                  style: new TextStyle(color: Colors.black, fontSize: 18.0)),
            ];

            if (page == pages.last) {
              entries.add(new FlatButton(
                  child: new Text("OK"),
                  onPressed: () => Navigator
                      .of(context)
                      .pushReplacementNamed('/transactions')));
            }

            return new Container(
              key: new ObjectKey(page),
              padding: const EdgeInsets.all(32.0),
              child: new Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: entries),
            );
          }).toList()),
        ),
        new Container(
          margin: new EdgeInsets.only(bottom: 32.0),
          child: new TabPageSelector(controller: controller),
        ),
      ],
    );
  }
}

class Welcome extends StatelessWidget {
  static const String routeName = '/welcome';

  static final List<WelcomePageEntry> pages = <WelcomePageEntry>[
    new WelcomePageEntry(Icons.event, "Header Text 1",
        "Lorem Ipsum is simply dummy text of the printing and typesetting industry."),
    new WelcomePageEntry(Icons.home, "Header Text 2",
        "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."),
    new WelcomePageEntry(Icons.alarm, "Header Text 3",
        "It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged."),
  ];

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new DefaultTabController(
        length: pages.length,
        child: new _PageSelector(pages: pages),
      ),
    );
  }
}
