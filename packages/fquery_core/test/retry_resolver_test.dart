import 'dart:async';

import 'package:test/test.dart';
import 'package:fquery_core/src/retry_resolver.dart';

void main() {
  group('RetryResolver', () {
    test('initializes successfully', () {
      final resolver = RetryResolver();
      expect(resolver, isNotNull);
    });

    test('resolves function on first attempt', () async {
      final resolver = RetryResolver();
      int? result;
      bool onResolveCalled = false;

      await resolver.resolve<int, Exception>(
        () async => 42,
        retryCount: 3,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (value) {
          result = value;
          onResolveCalled = true;
        },
        onError: (_) {},
        onCancel: () {},
      );

      expect(result, 42);
      expect(onResolveCalled, true);
    });

    test('calls onError when all retries exhausted', () async {
      final resolver = RetryResolver();
      dynamic capturedError;

      await resolver.resolve<int, Exception>(
        () async => throw Exception('failed'),
        retryCount: 1,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {},
        onError: (error) {
          capturedError = error;
        },
        onCancel: () {},
      );

      expect(capturedError, isA<Exception>());
      expect(capturedError.toString(), contains('failed'));
    });

    test('retries on error', () async {
      final resolver = RetryResolver();
      int attempts = 0;
      int? result;

      await resolver.resolve<int, Exception>(
        () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('not yet');
          }
          return 42;
        },
        retryCount: 3,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (value) {
          result = value;
        },
        onError: (_) {},
        onCancel: () {},
      );

      expect(attempts, 3);
      expect(result, 42);
    });

    test('respects retryCount limit', () async {
      final resolver = RetryResolver();
      int attempts = 0;

      await resolver.resolve<int, Exception>(
        () async {
          attempts++;
          throw Exception('always fails');
        },
        retryCount: 2,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {},
        onError: (_) {},
        onCancel: () {},
      );

      // retryCount: 2 means initial attempt + 2 retries = 3 total
      expect(attempts, 3);
    });

    test('respects retryDelay between attempts', () async {
      final resolver = RetryResolver();
      final timestamps = <int>[];

      await resolver.resolve<int, Exception>(
        () async {
          timestamps.add(DateTime.now().millisecondsSinceEpoch);
          if (timestamps.length < 3) {
            throw Exception('retry');
          }
          return 42;
        },
        retryCount: 2,
        retryDelay: Duration(milliseconds: 50),
        onResolve: (_) {},
        onError: (_) {},
        onCancel: () {},
      );

      expect(timestamps.length, 3);
      // Check that there was approximately 50ms between attempts
      final firstDelay = timestamps[1] - timestamps[0];
      final secondDelay = timestamps[2] - timestamps[1];

      expect(firstDelay, greaterThanOrEqualTo(50 - 10)); // Allow 10ms tolerance
      expect(secondDelay, greaterThanOrEqualTo(50 - 10));
    });

    test('cancel stops resolution', () async {
      final resolver = RetryResolver();
      int attempts = 0;
      bool onResolveCalled = false;

      // Start resolution in background
      final future = resolver.resolve<int, Exception>(
        () async {
          attempts++;
          await Future.delayed(Duration(milliseconds: 50));
          return 42;
        },
        retryCount: 5,
        retryDelay: Duration(milliseconds: 100),
        onResolve: (_) {
          onResolveCalled = true;
        },
        onError: (_) {},
        onCancel: () {},
      );

      // Cancel almost immediately
      await Future.delayed(Duration(milliseconds: 10));
      resolver.cancel();

      await future;

      expect(onResolveCalled, false);
    });

    test('cancel calls onCancel callback', () async {
      final resolver = RetryResolver();
      bool onCancelCalled = false;

      final future = resolver.resolve<int, Exception>(
        () async {
          await Future.delayed(Duration(milliseconds: 50));
          return 42;
        },
        retryCount: 5,
        retryDelay: Duration(milliseconds: 100),
        onResolve: (_) {},
        onError: (_) {},
        onCancel: () {
          onCancelCalled = true;
        },
      );

      await Future.delayed(Duration(milliseconds: 10));
      resolver.cancel();
      await future;

      expect(onCancelCalled, true);
    });

    test('prevents concurrent resolve calls', () async {
      final resolver = RetryResolver();
      int totalAttempts = 0;

      // Start first resolution
      final future1 = resolver.resolve<int, Exception>(
        () async {
          totalAttempts++;
          await Future.delayed(Duration(milliseconds: 100));
          return 1;
        },
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {},
        onError: (_) {},
        onCancel: () {},
      );

      // Try to start second resolution immediately
      await resolver.resolve<int, Exception>(
        () async {
          totalAttempts++;
          return 2;
        },
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {},
        onError: (_) {},
        onCancel: () {},
      );

      await future1;

      // Second call should be rejected
      expect(totalAttempts, 1);
    });

    test('reset clears running state', () async {
      final resolver = RetryResolver();
      int attempts = 0;

      await resolver.resolve<int, Exception>(
        () async {
          attempts++;
          return 42;
        },
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {},
        onError: (_) {},
        onCancel: () {},
      );

      resolver.reset();

      int secondAttempts = 0;
      await resolver.resolve<int, Exception>(
        () async {
          secondAttempts++;
          return 43;
        },
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {},
        onError: (_) {},
        onCancel: () {},
      );

      expect(attempts, 1);
      expect(secondAttempts, 1);
    });

    test('handles zero retries', () async {
      final resolver = RetryResolver();
      int attempts = 0;

      await resolver.resolve<int, Exception>(
        () async {
          attempts++;
          throw Exception('fail');
        },
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {},
        onError: (_) {},
        onCancel: () {},
      );

      // retryCount: 0 means only one attempt
      expect(attempts, 1);
    });

    test('handles FutureOr function', () async {
      final resolver = RetryResolver();
      int result = 0;

      await resolver.resolve<int, Exception>(
        () => 42, // Sync function returning FutureOr
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (value) {
          result = value;
        },
        onError: (_) {},
        onCancel: () {},
      );

      expect(result, 42);
    });

    test('handles different error types', () async {
      final resolver = RetryResolver();
      Exception? capturedError;

      await resolver.resolve<int, Exception>(
        () async => throw Exception('string error'),
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {},
        onError: (error) {
          capturedError = error as Exception;
        },
        onCancel: () {},
      );

      expect(capturedError, isA<Exception>());
    });

    test('checks isRunning state after cancel', () async {
      final resolver = RetryResolver();

      final future = resolver.resolve<int, Exception>(
        () async {
          await Future.delayed(Duration(milliseconds: 50));
          return 42;
        },
        retryCount: 5,
        retryDelay: Duration(milliseconds: 100),
        onResolve: (_) {},
        onError: (_) {},
        onCancel: () {},
      );

      await Future.delayed(Duration(milliseconds: 10));
      resolver.cancel();
      await future;

      // After cancellation, resolution should complete and reset
      await Future.delayed(Duration(milliseconds: 50));

      // Should be able to resolve again
      int result = 0;
      await resolver.resolve<int, Exception>(
        () async => 99,
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (value) {
          result = value;
        },
        onError: (_) {},
        onCancel: () {},
      );

      expect(result, 99);
    });

    test('onResolve called with correct value', () async {
      final resolver = RetryResolver();
      int? capturedValue;

      await resolver.resolve<int, Exception>(
        () async => 123,
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (value) {
          capturedValue = value;
        },
        onError: (_) {},
        onCancel: () {},
      );

      expect(capturedValue, 123);
    });

    test('onError not called on success', () async {
      final resolver = RetryResolver();
      bool onErrorCalled = false;

      await resolver.resolve<int, Exception>(
        () async => 42,
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {},
        onError: (_) {
          onErrorCalled = true;
        },
        onCancel: () {},
      );

      expect(onErrorCalled, false);
    });

    test('onResolve not called on error', () async {
      final resolver = RetryResolver();
      bool onResolveCalled = false;

      await resolver.resolve<int, Exception>(
        () async => throw Exception('fail'),
        retryCount: 0,
        retryDelay: Duration(milliseconds: 10),
        onResolve: (_) {
          onResolveCalled = true;
        },
        onError: (_) {},
        onCancel: () {},
      );

      expect(onResolveCalled, false);
    });

    test('respects early cancel on first attempt', () async {
      final resolver = RetryResolver();
      bool resolved = false;

      final future = resolver.resolve<int, Exception>(
        () async {
          // This should be checked before execution completes
          await Future.delayed(Duration(milliseconds: 200));
          return 42;
        },
        retryCount: 3,
        retryDelay: Duration(milliseconds: 100),
        onResolve: (_) {
          resolved = true;
        },
        onError: (_) {},
        onCancel: () {},
      );

      // Cancel before the delayed future completes
      await Future.delayed(Duration(milliseconds: 50));
      resolver.cancel();

      await future;

      expect(resolved, false);
    });
  });
}
