// Widget tests for the Edit Log Entry dialog's own exits — Cancel, the close
// button, and what Save actually writes.
//
// The window-close prompt (quitting the app) is covered separately in
// window_close_guard_test.dart. These cover closing just the dialog.
//
// Runs without a live Pod: only rendering / state behaviour.

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/pages/log_entry_edit.dart';
import 'package:konapod/pages/log_location_section.dart';
import 'package:konapod/services/app_provider.dart';

/// The Title field is the first text input in the editor.
Finder get titleField => find.byType(TextField).first;

/// The address field of the location section, which is in its manual-entry
/// state because the test provider has no vehicle to take coordinates from.
Finder get addressField => find.descendant(
      of: find.byType(LogLocationSection),
      matching: find.byType(TextField),
    );

/// Whether the editor is still on screen.
Finder get editor => find.text('New Log Entry');

/// Show the editor the way the log book does — as a dialog whose barrier
/// cannot dismiss it — so that closing it can be observed.

Future<void> showEditor(
  WidgetTester tester, {
  Future<void> Function(LogEntry)? onSave,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => LogEntryEdit(onSave: onSave),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Cancel with nothing typed closes without asking', (
    tester,
  ) async {
    await showEditor(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsNothing);
    expect(editor, findsNothing);
  });

  // Regression: Cancel used to pop the dialog outright, so a form full of
  // readings went in one tap with nothing asked and nothing written.
  testWidgets('Cancel with edits asks first, and Keep editing keeps them', (
    tester,
  ) async {
    await showEditor(tester);
    await tester.enterText(titleField, 'Charged at home');
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(editor, findsOneWidget);
    expect(find.text('Charged at home'), findsOneWidget);
  });

  testWidgets('Cancel then Discard closes without writing anything', (
    tester,
  ) async {
    var saves = 0;
    await showEditor(tester, onSave: (_) async => saves++);
    await tester.enterText(titleField, 'Charged at home');
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(editor, findsNothing);
    expect(saves, 0);
  });

  testWidgets('Cancel then Save writes the entry and then closes', (
    tester,
  ) async {
    LogEntry? saved;
    await showEditor(tester, onSave: (e) async => saved = e);
    await tester.enterText(titleField, 'Charged at home');
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    // The editor's own button reads "Add Entry" for a new entry, so "Save"
    // here is unambiguously the prompt's.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved?.title, 'Charged at home');
    expect(editor, findsNothing);
  });

  testWidgets('the close button goes through the same guard as Cancel', (
    tester,
  ) async {
    await showEditor(tester);
    await tester.enterText(titleField, 'Charged at home');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsOneWidget);
  });

  // Choosing Save must not close over the top of work that never landed.
  testWidgets('a failed save from the prompt leaves the editor open', (
    tester,
  ) async {
    SolidWriteFailures.clear();
    addTearDown(SolidWriteFailures.clear);

    await showEditor(tester, onSave: (_) async => throw Exception('no pod'));
    await tester.enterText(titleField, 'Charged at home');
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(editor, findsOneWidget);
    expect(find.text('Charged at home'), findsOneWidget);
  });

  // A title is required, so Save cannot run yet — the close has to be
  // abandoned rather than discarding the note the user just wrote.
  testWidgets('Save from the prompt with no title leaves the editor open', (
    tester,
  ) async {
    await showEditor(tester);
    await tester.enterText(find.byType(TextField).last, 'Some observations');
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(editor, findsOneWidget);
    expect(find.text('Some observations'), findsOneWidget);
  });

  // Regression: the location section only reported an address once Find had
  // geocoded one, so an address typed and then saved was silently dropped.
  testWidgets('Save keeps an address typed without pressing Find', (
    tester,
  ) async {
    LogEntry? saved;
    await showEditor(tester, onSave: (e) async => saved = e);
    await tester.enterText(titleField, 'Charged at home');
    await tester.enterText(addressField, 'Dickson Woolworths');
    await tester.pump();

    await tester.tap(find.text('Add Entry'));
    await tester.pumpAndSettle();

    expect(saved?.locationAddress, 'Dickson Woolworths');
  });

  // The same address has to count as unsaved work, or Cancel would drop it
  // without asking.
  testWidgets('an address typed without Find counts as an unsaved edit', (
    tester,
  ) async {
    await showEditor(tester);
    await tester.enterText(addressField, 'Dickson Woolworths');
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsOneWidget);
  });
}
