// Widget tests for the window-close save prompt as wired up by LogEntryEdit
// (save / discard / keep editing).
//
// Runs without a live Pod: only rendering / state behaviour.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:konapod/pages/log_entry_edit.dart';
import 'package:konapod/services/app_provider.dart';

Widget wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(home: child),
    );

/// The Title field is the first text input in the editor.
Finder get titleField => find.byType(TextField).first;

void main() {
  testWidgets('resolveAll succeeds with no prompt when nothing changed', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const LogEntryEdit()));
    await tester.pumpAndSettle();
    expect(await SolidWindowCloseGuard.resolveAll(), isTrue);
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('resolveAll prompts and resolves true on Discard', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const LogEntryEdit()));
    await tester.pumpAndSettle();
    await tester.enterText(titleField, 'Charged at home');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await future, isTrue);
  });

  testWidgets('resolveAll prompts and resolves false on Keep editing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const LogEntryEdit()));
    await tester.pumpAndSettle();
    await tester.enterText(titleField, 'Charged at home');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(await future, isFalse);
    // The editor is still open with the unsaved title intact.
    expect(find.text('Charged at home'), findsOneWidget);
  });

  // Regression: the editor used to pop its entry for the caller to persist, so
  // the Pod write was fire-and-forget. resolveAll() returned immediately, the
  // window was destroyed mid-write, and the entry was lost despite Save.
  testWidgets('window-close Save waits for the Pod write to finish', (
    tester,
  ) async {
    final podWrite = Completer<void>();
    var written = false;

    await tester.pumpWidget(
      wrap(
        LogEntryEdit(
          onSave: (entry) async {
            await podWrite.future;
            written = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(titleField, 'Charged at home');
    await tester.pump();

    var resolved = false;
    final future = SolidWindowCloseGuard.resolveAll()
      ..then((_) => resolved = true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The Pod write is still in flight, so the guard must NOT have resolved
    // — otherwise the caller would destroy the window and lose the entry.
    expect(resolved, isFalse);
    expect(written, isFalse);

    podWrite.complete();
    await tester.pumpAndSettle();

    expect(await future, isTrue);
    expect(written, isTrue);
  });

  testWidgets('editor unregisters its resolver on dispose', (tester) async {
    await tester.pumpWidget(wrap(const LogEntryEdit()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pumpAndSettle();
    // No editor left registered, so nothing to resolve.
    expect(await SolidWindowCloseGuard.resolveAll(), isTrue);
  });

  // A title is required, so Save from the prompt must abort the close and
  // leave the editor open rather than quitting and dropping the work.
  testWidgets('Save with no title keeps the editor open', (tester) async {
    await tester.pumpWidget(wrap(const LogEntryEdit()));
    await tester.pumpAndSettle();
    // A note with no title still counts as unsaved work.
    await tester.enterText(find.byType(TextField).last, 'Some observations');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(await future, isFalse);
    expect(find.text('Some observations'), findsOneWidget);
  });

  // Regression: snapshotting the saved state BEFORE awaiting the write left a
  // failed save looking saved, silencing the window-close prompt.
  testWidgets('a failed save leaves the entry unsaved and still prompting', (
    tester,
  ) async {
    SolidWriteFailures.clear();
    addTearDown(SolidWriteFailures.clear);

    await tester.pumpWidget(
      wrap(
        LogEntryEdit(
          onSave: (entry) async => throw Exception('pod unreachable'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(titleField, 'Charged at home');
    await tester.pump();

    // Save via the window-close prompt.
    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The close must be ABORTED. Asserting only that a second prompt appears
    // would pass even with the bug, because in the real flow there is no
    // second call — the window is already gone.

    expect(await future, isFalse);
    // Reported with konapod's own wording, not a generic message.
    expect(
      SolidWriteFailures.latest.value,
      contains('Failed saving the log entry.'),
    );

    // The write failed, so the editor must still consider itself dirty: a
    // second close attempt has to prompt again rather than discard silently.
    final second = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await second, isTrue);
  });
}
