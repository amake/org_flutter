import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:org_parser/org_parser.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orgro',
      theme: ThemeData.localize(ThemeData.light(), Typography.englishLike2018),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const platform = MethodChannel('org.madlonkay.orgro/openFile');

class _MyHomePageState extends State<MyHomePage> {
  String _content = 'Nothing Loaded';

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(handler);
  }

  Future<dynamic> handler(MethodCall call) async {
    switch (call.method) {
      case 'loadString':
        // ignore: avoid_as
        final content = call.arguments as String;
        setState(() {
          _content = content;
        });
        break;
    }
  }

  @override
  void dispose() {
    platform.setMethodCallHandler(null);
    super.dispose();
  }

  void _scrollToTop(BuildContext context) {
    final controller = PrimaryScrollController.of(context);
    _scrollTo(controller, controller.position.minScrollExtent);
  }

  void _scrollToBottom(BuildContext context) {
    final controller = PrimaryScrollController.of(context);
    _scrollTo(controller, controller.position.maxScrollExtent);
  }

  void _scrollTo(ScrollController controller, double position) =>
      controller.animateTo(position,
          duration: const Duration(milliseconds: 300), curve: Curves.ease);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orgro'),
        actions: <Widget>[
          // Builders required to get access to PrimaryScrollController
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () => _scrollToTop(context),
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => _scrollToBottom(context),
            ),
          )
        ],
      ),
      body: Center(
        child: Org(_content),
      ),
    );
  }
}

class Org extends StatelessWidget {
  const Org(this.text, {Key key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    final parser = OrgParser();
    final result = parser.parse(text);
    final topContent = result.value[0] as String;
    final sections = result.value[1] as List;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (topContent != null) Text(topContent, style: _orgStyle),
        ...sections.map((section) => OrgSectionWidget(section as OrgSection)),
      ],
    );
  }
}

class OrgSectionWidget extends StatefulWidget {
  const OrgSectionWidget(this.section, {Key key}) : super(key: key);
  final OrgSection section;

  @override
  _OrgSectionWidgetState createState() => _OrgSectionWidgetState();
}

class _OrgSectionWidgetState extends State<OrgSectionWidget> {
  bool _open;

  @override
  void initState() {
    super.initState();
    _open = true;
  }

  void _toggle() => setState(() {
        _open = !_open;
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GestureDetector(
          child: OrgHeadlineWidget(widget.section.headline),
          onTap: _toggle,
        ),
        if (_open) ...[
          if (widget.section.content != null)
            Text(widget.section.content, style: _orgStyle),
          ...widget.section.children.map((child) => OrgSectionWidget(child)),
        ]
      ],
    );
  }
}

class OrgHeadlineWidget extends StatelessWidget {
  const OrgHeadlineWidget(this.headline, {Key key}) : super(key: key);
  final OrgHeadline headline;

  @override
  Widget build(BuildContext context) {
    final color = _orgLevelColors[headline.level % _orgLevelColors.length];
    final baseStyle = _orgStyle.copyWith(
      color: color,
      fontWeight: FontWeight.bold,
    );
    return RichText(
      text: TextSpan(
        text: '${headline.stars} ',
        style: baseStyle,
        children: [
          if (headline.keyword != null)
            TextSpan(
                text: '${headline.keyword} ',
                style: _orgStyle.copyWith(
                    color: headline.keyword == 'DONE'
                        ? _orgDoneColor
                        : _orgTodoColor)),
          if (headline.priority != null)
            TextSpan(text: '${headline.priority} '),
          if (headline.title != null) TextSpan(text: headline.title),
          if (headline.tags.isNotEmpty)
            TextSpan(text: ':${headline.tags.join(':')}:'),
        ],
      ),
    );
  }
}

const _orgLevelColors = [
  Color(0xff0000ff),
  Color(0xffa0522d),
  Color(0xffa020f0),
  Color(0xffb22222),
  Color(0xff228b22),
  Color(0xff008b8b),
  Color(0xff483d8b),
  Color(0xff8b2252),
];
const _orgTodoColor = Color(0xffff0000);
const _orgDoneColor = Color(0xff228b22);
final _orgStyle = GoogleFonts.firaMono(fontSize: 18);
