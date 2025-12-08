import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquery/src/use_observable.dart';
import 'package:fquery_core/fquery_core.dart';

class TestObservable with Observable {}

// Test widget that uses the actual useObservable hook
class TestWidgetWithUseObservable extends HookWidget {
  final TestObservable observable;
  final void Function(String) log;

  const TestWidgetWithUseObservable({
    super.key,
    required this.observable,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    log('Build');
    useObservable(observable);
    return const SizedBox();
  }
}

void main() {
  group('useObservable dispose issue', () {
    testWidgets(
      'should not crash when observable notifies after widget is disposed',
      (tester) async {
        final observable = TestObservable();
        final logs = <String>[];
        void log(String msg) {
          debugPrint(msg);
          logs.add(msg);
        }

        // Show the widget
        await tester.pumpWidget(
          MaterialApp(
            home: TestWidgetWithUseObservable(
              observable: observable,
              log: log,
            ),
          ),
        );

        log('--- Removing widget ---');
        // Remove the widget (dispose)
        await tester.pumpWidget(
          const MaterialApp(
            home: SizedBox(),
          ),
        );

        log('--- Notifying observers after dispose ---');
        // This should NOT crash even though widget is disposed
        observable.notifyObservers();

        await tester.pump();

        log('--- Test completed without error ---');
        expect(logs, contains('--- Test completed without error ---'));
      },
    );

    testWidgets(
      'should not crash when listener is called but widget is already unmounted',
      (tester) async {
        var listenerCallCount = 0;

        // Custom observable that keeps listener even after unsubscribe
        // to simulate race condition
        final listeners = <Function>[];

        await tester.pumpWidget(
          MaterialApp(
            home: HookBuilder(
              builder: (context) {
                final rebuild = useState(0);
                final mounted = useRef(true);

                useEffect(() {
                  mounted.value = true;

                  void listener() {
                    listenerCallCount++;
                    debugPrint('Listener called, mounted: ${mounted.value}');
                    if (mounted.value) {
                      rebuild.value++;
                    }
                  }

                  listeners.add(listener);

                  return () {
                    mounted.value = false;
                    // Note: we intentionally don't remove from listeners
                    // to simulate race condition
                  };
                }, []);

                return const SizedBox();
              },
            ),
          ),
        );

        // Remove widget
        await tester.pumpWidget(
          const MaterialApp(home: SizedBox()),
        );

        // Call listener directly (simulating race condition)
        debugPrint('Calling listener after dispose...');
        for (final listener in listeners) {
          listener();
        }

        await tester.pump();

        // Listener was called but should not crash
        expect(listenerCallCount, 1);
        debugPrint('Test completed without error');
      },
    );
  });
}
