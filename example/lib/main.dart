import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'org_flutter',
      restorationScopeId: 'example_root',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('org_flutter'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Simple'),
              Tab(text: 'Complex'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          SimpleTab(),
          ComplexTab(),
        ]),
      ),
    );
  }
}

class SimpleTab extends StatelessWidget {
  const SimpleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Org(
      '''* TODO [#A] foo bar
baz buzz''',
      restorationId: 'my_org_widget',
    );
  }
}

class ComplexTab extends StatefulWidget {
  const ComplexTab({super.key});

  @override
  State<ComplexTab> createState() => _ComplexTabState();
}

class _ComplexTabState extends State<ComplexTab> {
  late OrgDocument root;

  @override
  void initState() {
    root = OrgDocument.parse('''* TODO [#A] foo bar
~1~''');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OrgController(
      root: root,
      child: ListView(
        children: [
          OrgRootWidget(child: OrgDocumentWidget(root, shrinkWrap: true)),
          ElevatedButton(
            onPressed: _incrementCounter,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }

  void _incrementCounter() {
    late OrgMarkup markupNode;
    root.visit<OrgMarkup>((node) {
      markupNode = node;
      return false; // stop visiting
    });
    final value = int.parse(markupNode.content.children.single.toMarkup());
    setState(() {
      root = root
          .editNode(markupNode)!
          .replace(OrgMarkup.just('${value + 1}', OrgStyle.code))
          .commit() as OrgDocument;
    });
  }
}
