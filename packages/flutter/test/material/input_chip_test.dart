// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adds the basic requirements for a Chip.
Widget wrapForChip({
  required Widget child,
  TextDirection textDirection = TextDirection.ltr,
  double textScaleFactor = 1.0,
  Brightness brightness = Brightness.light,
  bool? useMaterial3,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness, useMaterial3: useMaterial3),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: textScaleFactor,
        maxScaleFactor: textScaleFactor,
        child: Material(child: child),
      ),
    ),
  );
}

Widget selectedInputChip({
  Color? checkmarkColor,
  bool enabled = false,
}) {
  return InputChip(
    label: const Text('InputChip'),
    selected: true,
    isEnabled: enabled,
    showCheckmark: true,
    checkmarkColor: checkmarkColor,
  );
}


Future<void> pumpCheckmarkChip(
  WidgetTester tester, {
  required Widget chip,
  Color? themeColor,
  Brightness brightness = Brightness.light,
  bool? useMaterial3,
}) async {
  await tester.pumpWidget(
    wrapForChip(
      useMaterial3: useMaterial3,
      brightness: brightness,
      child: Builder(
        builder: (BuildContext context) {
          final ChipThemeData chipTheme = ChipTheme.of(context);
          return ChipTheme(
            data: themeColor == null ? chipTheme : chipTheme.copyWith(
              checkmarkColor: themeColor,
            ),
            child: chip,
          );
        },
      ),
    ),
  );
}

void expectCheckmarkColor(Finder finder, Color color) {
  expect(
    finder,
    paints
      // Physical model layer path
      ..path()
      // The first layer that is painted is the selection overlay. We do not care
      // how it is painted but it has to be added it to this pattern so that the
      // check mark can be checked next.
      ..rrect()
      // The second layer that is painted is the check mark.
      ..path(color: color),
  );
}

RenderBox getMaterialBox(WidgetTester tester) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: find.byType(InputChip),
      matching: find.byType(CustomPaint),
    ),
  );
}

IconThemeData getIconData(WidgetTester tester) {
  final IconTheme iconTheme = tester.firstWidget(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(IconTheme),
    ),
  );
  return iconTheme.data;
}

void checkChipMaterialClipBehavior(WidgetTester tester, Clip clipBehavior) {
  final Iterable<Material> materials = tester.widgetList<Material>(find.byType(Material));
  // There should be two Material widgets, first Material is from the "_wrapForChip" and
  // last Material is from the "RawChip".
  expect(materials.length, 2);
  // The last Material from `RawChip` should have the clip behavior.
  expect(materials.last.clipBehavior, clipBehavior);
}

// Finds any container of a tooltip.
Finder findTooltipContainer(String tooltipText) {
  return find.ancestor(
    of: find.text(tooltipText),
    matching: find.byType(Container),
  );
}

void main() {
  testWidgets('InputChip.color resolves material states', (WidgetTester tester) async {
    const Color disabledSelectedColor = Color(0xffffff00);
    const Color disabledColor = Color(0xff00ff00);
    const Color backgroundColor = Color(0xff0000ff);
    const Color selectedColor = Color(0xffff0000);
    Widget buildApp({ required bool enabled, required bool selected }) {
      return wrapForChip(
        child: InputChip(
          onSelected: enabled ? (bool value) { } : null,
          selected: selected,
          color: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled) && states.contains(MaterialState.selected)) {
              return disabledSelectedColor;
            }
            if (states.contains(MaterialState.disabled)) {
              return disabledColor;
            }
            if (states.contains(MaterialState.selected)) {
              return selectedColor;
            }
            return backgroundColor;
          }),
          label: const Text('InputChip'),
        ),
      );
    }

    // Test enabled chip.
    await tester.pumpWidget(buildApp(enabled: true, selected: false));

    // Enabled chip should have the provided backgroundColor.
    expect(getMaterialBox(tester), paints..rrect(color: backgroundColor));

    // Test disabled chip.
    await tester.pumpWidget(buildApp(enabled: false, selected: false));
    await tester.pumpAndSettle();

    // Disabled chip should have the provided disabledColor.
    expect(getMaterialBox(tester), paints..rrect(color: disabledColor));

    // Test enabled & selected chip.
    await tester.pumpWidget(buildApp(enabled: true, selected: true));
    await tester.pumpAndSettle();

    // Enabled & selected chip should have the provided selectedColor.
    expect(getMaterialBox(tester), paints..rrect(color: selectedColor));

      // Test disabled & selected chip.
    await tester.pumpWidget(buildApp(enabled: false, selected: true));
    await tester.pumpAndSettle();

    // Disabled & selected chip should have the provided disabledSelectedColor.
    expect(getMaterialBox(tester), paints..rrect(color: disabledSelectedColor));
  });

  testWidgets('InputChip uses provided state color properties', (WidgetTester tester) async {
    const Color disabledColor = Color(0xff00ff00);
    const Color backgroundColor = Color(0xff0000ff);
    const Color selectedColor = Color(0xffff0000);
    Widget buildApp({ required bool enabled, required bool selected }) {
      return wrapForChip(
        child: InputChip(
          onSelected: enabled ? (bool value) { } : null,
          selected: selected,
          disabledColor: disabledColor,
          backgroundColor: backgroundColor,
          selectedColor: selectedColor,
          label: const Text('InputChip'),
        ),
      );
    }

    // Test enabled chip.
    await tester.pumpWidget(buildApp(enabled: true, selected: false));

    // Enabled chip should have the provided backgroundColor.
    expect(getMaterialBox(tester), paints..rrect(color: backgroundColor));

    // Test disabled chip.
    await tester.pumpWidget(buildApp(enabled: false, selected: false));
    await tester.pumpAndSettle();

    // Disabled chip should have the provided disabledColor.
    expect(getMaterialBox(tester), paints..rrect(color: disabledColor));

    // Test enabled & selected chip.
    await tester.pumpWidget(buildApp(enabled: true, selected: true));
    await tester.pumpAndSettle();

    // Enabled & selected chip should have the provided selectedColor.
    expect(getMaterialBox(tester), paints..rrect(color: selectedColor));
  });

  testWidgets('InputChip can be tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: InputChip(
            label: Text('input chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InputChip));
    expect(tester.takeException(), null);
  });

  testWidgets('loses focus when disabled', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'InputChip');
    await tester.pumpWidget(
      wrapForChip(
        child: InputChip(
          focusNode: focusNode,
          autofocus: true,
          shape: const RoundedRectangleBorder(),
          avatar: const CircleAvatar(child: Text('A')),
          label: const Text('Chip A'),
          onPressed: () { },
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      wrapForChip(
        child: InputChip(
          focusNode: focusNode,
          autofocus: true,
          shape: const RoundedRectangleBorder(),
          avatar: const CircleAvatar(child: Text('A')),
          label: const Text('Chip A'),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isFalse);

    focusNode.dispose();
  });

  testWidgets('cannot be traversed to when disabled', (WidgetTester tester) async {
    final FocusNode focusNode1 = FocusNode(debugLabel: 'InputChip 1');
    final FocusNode focusNode2 = FocusNode(debugLabel: 'InputChip 2');
    await tester.pumpWidget(
      wrapForChip(
        child: FocusScope(
          child: Column(
            children: <Widget>[
              InputChip(
                focusNode: focusNode1,
                autofocus: true,
                label: const Text('Chip A'),
                onPressed: () { },
              ),
              InputChip(
                focusNode: focusNode2,
                autofocus: true,
                label: const Text('Chip B'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);

    expect(focusNode1.nextFocus(), isFalse);

    await tester.pump();
    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);

    focusNode1.dispose();
    focusNode2.dispose();
  });

  testWidgets('Material2 - Input chip check mark color is determined by platform brightness when light', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(),
      useMaterial3: false,
    );

    expectCheckmarkColor(find.byType(InputChip), Colors.black.withAlpha(0xde));
  });

  testWidgets('Material3 - Input chip check mark color is determined by platform brightness when light', (WidgetTester tester) async {
    await pumpCheckmarkChip(tester, chip: selectedInputChip());

    expectCheckmarkColor(find.byType(InputChip), Colors.black.withAlpha(0xde));
  });

  testWidgets('Material2 - Input chip check mark color is determined by platform brightness when dark', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(),
      brightness: Brightness.dark,
      useMaterial3: false,
    );

    expectCheckmarkColor(find.byType(InputChip), Colors.white.withAlpha(0xde));
  });

  testWidgets('Material3 - Input chip check mark color is determined by platform brightness when dark', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(),
      brightness: Brightness.dark,
    );

    expectCheckmarkColor(find.byType(InputChip), Colors.white.withAlpha(0xde));
  });

  testWidgets('Input chip check mark color can be set by the chip theme', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(),
      themeColor: const Color(0xff00ff00),
    );

    expectCheckmarkColor(find.byType(InputChip), const Color(0xff00ff00));
  });

  testWidgets('Input chip check mark color can be set by the chip constructor', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(checkmarkColor: const Color(0xff00ff00)),
    );

    expectCheckmarkColor(find.byType(InputChip), const Color(0xff00ff00));
  });

  testWidgets('Input chip check mark color is set by chip constructor even when a theme color is specified', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(checkmarkColor: const Color(0xffff0000)),
      themeColor: const Color(0xff00ff00),
    );

    expectCheckmarkColor(find.byType(InputChip), const Color(0xffff0000));
  });

  testWidgets('InputChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(wrapForChip(child: const InputChip(label: label)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(wrapForChip(child: const InputChip(label: label, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('Material3 - Input chip has correct selected color when enabled', (WidgetTester tester) async {
    final ChipThemeData material3ChipDefaults = ThemeData(useMaterial3: true).chipTheme;
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(enabled: true),
      useMaterial3: true,
    );

    final RenderBox materialBox = getMaterialBox(tester);
    expect(materialBox, paints..rrect(color: material3ChipDefaults.backgroundColor));
  });

  testWidgets('Material3 - Input chip has correct selected color when disabled', (WidgetTester tester) async {
    final ChipThemeData material3ChipDefaults = ThemeData(useMaterial3: true).chipTheme;
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(),
      useMaterial3: true,
    );

    final RenderBox materialBox = getMaterialBox(tester);
    expect(materialBox, paints..path(color: material3ChipDefaults.disabledColor));
  });

  testWidgets('InputChip uses provided iconTheme', (WidgetTester tester) async {
    Widget buildChip({ IconThemeData? iconTheme }) {
      return MaterialApp(
        home: Material(
          child: InputChip(
            iconTheme: iconTheme,
            avatar: const Icon(Icons.add),
            label: const Text('Test'),
          ),
        ),
      );
    }

    // Test default icon theme.
    await tester.pumpWidget(buildChip());

    expect(getIconData(tester).color, ThemeData().iconTheme.color);

    // Test provided icon theme.
    await tester.pumpWidget(buildChip(iconTheme: const IconThemeData(color: Color(0xff00ff00))));

    expect(getIconData(tester).color, const Color(0xff00ff00));
  });

  testWidgets('Delete button is visible on disabled InputChip', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForChip(
        child: InputChip(
          isEnabled: false,
          label: const Text('Label'),
          onDeleted: () { },
        )
      ),
    );

    // Delete button should be visible.
    expectLater(find.byType(RawChip), matchesGoldenFile('input_chip.disabled.delete_button.png'));
  });

  testWidgets('Delete button tooltip is not shown on disabled InputChip', (WidgetTester tester) async {
    Widget buildChip({ bool enabled = true }) {
      return wrapForChip(
        child: InputChip(
          isEnabled: enabled,
          label: const Text('Label'),
          onDeleted: () { },
        )
      );
    }

    // Test enabled chip.
    await tester.pumpWidget(buildChip());

    final Offset deleteButtonLocation = tester.getCenter(find.byType(Icon));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(deleteButtonLocation);
    await tester.pump();

    // Delete button tooltip should be visible.
    expect(findTooltipContainer('Delete'), findsOneWidget);

    // Test disabled chip.
    await tester.pumpWidget(buildChip(enabled: false));
    await tester.pump();

    // Delete button tooltip should not be visible.
    expect(findTooltipContainer('Delete'), findsNothing);
  });
}
