// Checks docs/plans/store-listing.md against Play Console's field limits, so an
// over-long description is caught here rather than by a rejected upload.
//
// Limits: app name 30, short description 80, full description 4000.
//
// Run: dart run tool/check_store_listing.dart
// ignore_for_file: avoid_print
import 'dart:io';

const limits = {
  'App name': 30,
  'Short description': 80,
  'Full description': 4000,
};

void main() {
  final lines = File('docs/plans/store-listing.md').readAsLinesSync();

  String? field;
  var inFence = false;
  final buffer = <String>[];
  final results = <(String, int, int)>[]; // field, length, limit
  var problems = 0;

  void finish() {
    if (field == null) return;
    final text = buffer.join('\n').trim();
    final limit = limits[field]!;
    results.add((field!, text.length, limit));
    if (text.length > limit) problems++;
    field = null;
    buffer.clear();
  }

  for (final line in lines) {
    final heading = RegExp(r'^###\s+(.*)$').firstMatch(line);
    if (heading != null) {
      finish();
      final name = heading.group(1)!.trim();
      if (limits.containsKey(name)) field = name;
      continue;
    }
    if (field == null) continue;
    if (line.trim() == '```') {
      if (inFence) {
        inFence = false;
        finish();
      } else {
        inFence = true;
      }
      continue;
    }
    if (inFence) buffer.add(line);
  }
  finish();

  if (results.isEmpty) {
    print('No listing fields found — has the document structure changed?');
    exitCode = 1;
    return;
  }

  for (final (name, length, limit) in results) {
    final status = length > limit ? 'OVER by ${length - limit}' : 'ok';
    print('${name.padRight(18)} ${length.toString().padLeft(5)} / $limit  '
        '$status');
  }
  print('');
  print(problems == 0
      ? 'All ${results.length} fields within Play\'s limits.'
      : '$problems field(s) too long — Play will reject these.');
  if (problems > 0) exitCode = 1;
}
