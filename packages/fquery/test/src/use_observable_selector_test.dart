import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquery/src/use_observable_selector.dart';
import 'package:fquery_core/fquery_core.dart';

class TestObservable with Observable {
  int counter = 0;

  void increment() {
    counter++;
    notifyObservers();
  }
}

class TestWidget extends HookWidget {
  final TestObservable observable;
  final void Function(int value)? onBuild;

  const TestWidget({
    super.key,
    required this.observable,
    this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    final value = useObservableSelector(observable, () => observable.counter);
    onBuild?.call(value);
    return Text('$value');
  }
}

void main() {
  group('useObservableSelector', () {
    testWidgets('should update value when observable notifies', (tester) async {
      final observable = TestObservable();
      var lastValue = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            observable: observable,
            onBuild: (value) => lastValue = value,
          ),
        ),
      );

      expect(lastValue, 0);

      observable.increment();
      await tester.pump();

      expect(lastValue, 1);
    });

    testWidgets(
        'should not crash when observable notifies after widget is disposed',
        (tester) async {
      final observable = TestObservable();

      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(observable: observable),
        ),
      );

      // Remove the widget (dispose)
      await tester.pumpWidget(
        const MaterialApp(home: SizedBox()),
      );

      // Notify after dispose - should be ignored without error
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) => errors.add(details);

      observable.increment();
      await tester.pump();

      FlutterError.onError = FlutterError.dumpErrorToConsole;

      // Should not have triggered any Flutter errors
      expect(errors, isEmpty);
    });

    testWidgets(
        'should not crash when observable notifies during build (setState called during build)',
        (tester) async {
      final observable = TestObservable();

      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) => errors.add(details);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              TestWidget(observable: observable),
              Builder(builder: (context) {
                observable.increment();
                return const SizedBox();
              }),
            ],
          ),
        ),
      );

      await tester.pump();

      FlutterError.onError = FlutterError.dumpErrorToConsole;

      expect(errors, isEmpty);
    });
  });
}
