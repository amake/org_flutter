import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/src/util/bidi.dart';
import 'package:org_parser/org_parser.dart';

void main() {
  test('detect ltr', () {
    final node = OrgPlainText('foo');
    final textDirection = node.detectTextDirection();
    expect(textDirection, TextDirection.ltr);
  });
  test('detect rtl', () {
    final node = OrgPlainText('אבج');
    final textDirection = node.detectTextDirection();
    expect(textDirection, TextDirection.rtl);
  });
  test('detect unknown', () {
    final node = OrgPlainText('123');
    final textDirection = node.detectTextDirection();
    expect(textDirection, isNull);
  });
  test('detect forced rtl', () {
    final node = OrgPlainText('\u200f123');
    final textDirection = node.detectTextDirection();
    expect(textDirection, TextDirection.rtl);
  });
  test('detect forced ltr', () {
    final node = OrgPlainText('\u200e123');
    final textDirection = node.detectTextDirection();
    expect(textDirection, TextDirection.ltr);
  });
}
