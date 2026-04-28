import 'dart:async';

import 'package:test/test.dart';
import 'package:fquery_core/src/mutation.dart';
import 'package:fquery_core/src/mutation_observer.dart';

void main() {
  group('MutationObserver', () {
    test('initializes with idle status', () {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      expect(observer.mutation.isIdle, true);
      expect(observer.mutation.data, null);
      expect(observer.mutation.error, null);
    });

    test('dispose clears subscribers', () {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      int notified = 0;
      observer.subscribe(1, () => notified++);

      observer.dispose();
      observer.notifyObservers();

      expect(notified, 0);
    });

    test('mutate changes status to pending immediately', () async {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      // Start mutation
      final future = observer.mutate('test');

      // Should be pending immediately
      expect(observer.mutation.isPending, true);

      await future;
    });

    test('mutate success updates data and status', () async {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('test');

      expect(observer.mutation.isSuccess, true);
      expect(observer.mutation.data, 42);
      expect(observer.mutation.error, null);
    });

    test('mutate error updates error and status', () async {
      final testError = Exception('mutation failed');
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => throw testError,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('test');

      expect(observer.mutation.isError, true);
      expect(observer.mutation.error, testError);
      expect(observer.mutation.data, null);
    });

    test('mutate stores variables', () async {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('test-var');

      expect(observer.vars, 'test-var');
    });

    test('mutate calls onMutate callback', () async {
      bool onMutateCalled = false;

      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
        onMutate: (vars) async {
          onMutateCalled = true;
        },
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('test');

      expect(onMutateCalled, true);
    });

    test('mutate calls onSuccess callback on success', () async {
      int? callbackData;
      String? callbackVars;

      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
        onSuccess: (data, vars, ctx) {
          callbackData = data;
          callbackVars = vars;
        },
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('test-var');

      expect(callbackData, 42);
      expect(callbackVars, 'test-var');
    });

    test('mutate calls onError callback on error', () async {
      Exception? callbackError;
      String? callbackVars;

      final testError = Exception('failed');
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => throw testError,
        onError: (error, vars, ctx) {
          callbackError = error;
          callbackVars = vars;
        },
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('test-var');

      expect(callbackError, testError);
      expect(callbackVars, 'test-var');
    });

    test('mutate calls onSettled after success', () async {
      int? settledData;
      Exception? settledError;
      String? settledVars;

      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
        onSettled: (data, error, vars, ctx) {
          settledData = data;
          settledError = error;
          settledVars = vars;
        },
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('test-var');

      expect(settledData, 42);
      expect(settledError, null);
      expect(settledVars, 'test-var');
    });

    test('mutate calls onSettled after error', () async {
      int? settledData;
      Exception? settledError;
      String? settledVars;

      final testError = Exception('failed');
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => throw testError,
        onSettled: (data, error, vars, ctx) {
          settledData = data;
          settledError = error;
          settledVars = vars;
        },
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('test-var');

      expect(settledData, null);
      expect(settledError, testError);
      expect(settledVars, 'test-var');
    });

    test('mutate with context parameter', () async {
      Map<String, dynamic>? contextFromMutate;
      Map<String, dynamic>? contextFromSuccess;

      final options = MutationOptions<int, Exception, String, Map<String, dynamic>>(
        mutationFn: (vars) async => 42,
        onMutate: (vars) async {
          return {'id': 'test-context'};
        },
        onSuccess: (data, vars, ctx) {
          contextFromSuccess = ctx;
        },
      );

      final observer = MutationObserver<int, Exception, String, Map<String, dynamic>>(
        options: options,
      );

      await observer.mutate('test');

      expect(contextFromSuccess, isNotNull);
      expect(contextFromSuccess?['id'], 'test-context');
    });

    test('reset clears state', () async {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('test');
      expect(observer.mutation.isSuccess, true);

      observer.reset();

      expect(observer.mutation.isIdle, true);
      expect(observer.mutation.data, null);
      expect(observer.mutation.error, null);
    });

    test('mutate rejects concurrent calls', () async {
      int mutationCount = 0;

      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async {
          await Future.delayed(Duration(milliseconds: 100));
          mutationCount++;
          return 42;
        },
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      // Start first mutation
      final future1 = observer.mutate('test1');

      // Try to start second mutation immediately (should be rejected)
      await observer.mutate('test2');

      await future1;

      // Should only have executed once
      expect(mutationCount, 1);
    });

    test('mutateAsync returns data on success', () async {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      final result = await observer.mutateAsync('test');

      expect(result, 42);
      expect(observer.mutation.isSuccess, true);
    });

    test('mutateAsync throws error on failure', () async {
      final testError = Exception('mutation failed');
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => throw testError,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      expect(
        () => observer.mutateAsync('test'),
        throwsException,
      );
    });

    test('mutateAsync calls callbacks in correct order', () async {
      final callOrder = <String>[];

      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async {
          callOrder.add('mutationFn');
          return 42;
        },
        onMutate: (vars) async {
          callOrder.add('onMutate');
        },
        onSuccess: (data, vars, ctx) {
          callOrder.add('onSuccess');
        },
        onSettled: (data, error, vars, ctx) {
          callOrder.add('onSettled');
        },
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutateAsync('test');

      expect(callOrder, ['onMutate', 'mutationFn', 'onSuccess', 'onSettled']);
    });

    test('notifies observers when mutation updates', () async {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      int notificationCount = 0;
      observer.subscribe(1, () {
        notificationCount++;
      });

      await observer.mutate('test');

      expect(notificationCount, greaterThan(0));
    });

    test('notifies observers on reset', () async {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      int notificationCount = 0;
      observer.subscribe(1, () {
        notificationCount++;
      });

      observer.reset();

      expect(notificationCount, greaterThan(0));
    });

    test('mutateAsync rejects concurrent calls', () async {
      int mutationCount = 0;

      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async {
          await Future.delayed(Duration(milliseconds: 100));
          mutationCount++;
          return 42;
        },
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      // Start first mutation
      final future1 = observer.mutateAsync('test1');

      // Try to start second mutation immediately (should be rejected)
      final future2 = observer.mutateAsync('test2');

      await future1;
      final result2 = await future2;

      // Second call should return null (rejected)
      expect(result2, null);
      expect(mutationCount, 1);
    });

    test('handles sync mutation function', () async {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => int.parse(vars),
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      await observer.mutate('42');

      expect(observer.mutation.data, 42);
      expect(observer.mutation.isSuccess, true);
    });

    test('preserves submittedAt timestamp', () async {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      final observer = MutationObserver<int, Exception, String, void>(
        options: options,
      );

      final timeBefore = DateTime.now();
      await observer.mutate('test');
      final timeAfter = DateTime.now();

      expect(observer.mutation.submittedAt, isNotNull);
      expect(
        observer.mutation.submittedAt!.isAfter(timeBefore.subtract(Duration(seconds: 1))),
        true,
      );
      expect(
        observer.mutation.submittedAt!.isBefore(timeAfter.add(Duration(seconds: 1))),
        true,
      );
    });
  });
}
