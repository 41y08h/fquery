import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquery/src/use_observable.dart';
import 'package:fquery_core/fquery_core.dart';

class TestObservable with Observable {}

class TestWidget extends HookWidget {
  final TestObservable observable;
  final void Function()? onBuild;

  const TestWidget({
    super.key,
    required this.observable,
    this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    onBuild?.call();
    useObservable(observable);
    return const SizedBox();
  }
}

void main() {
  group('useObservable', () {
    testWidgets('should rebuild widget when observable notifies',
        (tester) async {
      final observable = TestObservable();
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            observable: observable,
            onBuild: () => buildCount++,
          ),
        ),
      );

      expect(buildCount, 1);

      observable.notifyObservers();
      await tester.pump();

      expect(buildCount, 2);
    });

    testWidgets(
        'should not rebuild widget when observable notifies after widget is disposed',
        (tester) async {
      final observable = TestObservable();
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            observable: observable,
            onBuild: () => buildCount++,
          ),
        ),
      );

      expect(buildCount, 1);

      // Remove the widget (dispose)
      await tester.pumpWidget(
        const MaterialApp(home: SizedBox()),
      );

      // Notify after dispose - should be ignored without error
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) => errors.add(details);

      observable.notifyObservers();
      await tester.pump();

      FlutterError.onError = FlutterError.dumpErrorToConsole;

      // Should not have triggered any Flutter errors
      expect(errors, isEmpty);
      // Build count should remain 1 (no rebuild after dispose)
      expect(buildCount, 1);
    });
  });
}
