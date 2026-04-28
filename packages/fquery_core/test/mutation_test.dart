import 'package:test/test.dart';
import 'package:fquery_core/src/mutation.dart';

void main() {
  group('Mutation', () {
    test('idle status by default', () {
      final mutation = Mutation<int, Exception>();
      expect(mutation.status, MutationStatus.idle);
      expect(mutation.isIdle, true);
      expect(mutation.isPending, false);
      expect(mutation.isSuccess, false);
      expect(mutation.isError, false);
    });

    test('copyWith updates status', () {
      final mutation1 = Mutation<int, Exception>(
        status: MutationStatus.idle,
      );
      final mutation2 = mutation1.copyWith(
        status: MutationStatus.pending,
      );

      expect(mutation1.status, MutationStatus.idle);
      expect(mutation2.status, MutationStatus.pending);
    });

    test('copyWith updates data', () {
      final mutation1 = Mutation<int, Exception>();
      final mutation2 = mutation1.copyWith(data: 42);

      expect(mutation1.data, null);
      expect(mutation2.data, 42);
    });

    test('copyWith updates error', () {
      final error = Exception('test error');
      final mutation1 = Mutation<int, Exception>();
      final mutation2 = mutation1.copyWith(error: error);

      expect(mutation1.error, null);
      expect(mutation2.error, error);
    });

    test('copyWith updates submittedAt', () {
      final now = DateTime.now();
      final mutation1 = Mutation<int, Exception>();
      final mutation2 = mutation1.copyWith(submittedAt: now);

      expect(mutation1.submittedAt, null);
      expect(mutation2.submittedAt, now);
    });

    test('success status sets isSuccess to true', () {
      final mutation = Mutation<int, Exception>(
        status: MutationStatus.success,
        data: 42,
      );

      expect(mutation.isSuccess, true);
      expect(mutation.isPending, false);
      expect(mutation.isError, false);
      expect(mutation.isIdle, false);
    });

    test('error status sets isError to true', () {
      final mutation = Mutation<int, Exception>(
        status: MutationStatus.error,
        error: Exception('error'),
      );

      expect(mutation.isError, true);
      expect(mutation.isPending, false);
      expect(mutation.isSuccess, false);
      expect(mutation.isIdle, false);
    });

    test('pending status sets isPending to true', () {
      final mutation = Mutation<int, Exception>(
        status: MutationStatus.pending,
      );

      expect(mutation.isPending, true);
      expect(mutation.isSuccess, false);
      expect(mutation.isError, false);
      expect(mutation.isIdle, false);
    });

    test('copyWith preserves other fields', () {
      final error = Exception('original error');
      final now = DateTime.now();
      final mutation1 = Mutation<int, Exception>(
        data: 10,
        error: error,
        status: MutationStatus.error,
        submittedAt: now,
      );

      final mutation2 = mutation1.copyWith(
        data: 20,
      );

      expect(mutation2.data, 20);
      expect(mutation2.error, error);
      expect(mutation2.status, MutationStatus.error);
      expect(mutation2.submittedAt, now);
    });
  });

  group('MutationStatus enum', () {
    test('has all expected values', () {
      expect(MutationStatus.values.length, 4);
      expect(MutationStatus.values, contains(MutationStatus.idle));
      expect(MutationStatus.values, contains(MutationStatus.pending));
      expect(MutationStatus.values, contains(MutationStatus.success));
      expect(MutationStatus.values, contains(MutationStatus.error));
    });
  });

  group('MutationDispatchAction enum', () {
    test('has all expected values', () {
      expect(MutationDispatchAction.values.length, 4);
      expect(MutationDispatchAction.values, contains(MutationDispatchAction.reset));
      expect(MutationDispatchAction.values, contains(MutationDispatchAction.mutate));
      expect(MutationDispatchAction.values, contains(MutationDispatchAction.error));
      expect(MutationDispatchAction.values, contains(MutationDispatchAction.success));
    });
  });

  group('MutationResult', () {
    test('constructs with default values', () {
      final result = MutationResult<int, Exception, String>(
        mutate: (_) async {},
        mutateAsync: (_) async => null,
        reset: () {},
      );

      expect(result.status, MutationStatus.idle);
      expect(result.isIdle, true);
      expect(result.isPending, false);
      expect(result.isSuccess, false);
      expect(result.isError, false);
      expect(result.data, null);
      expect(result.error, null);
      expect(result.submittedAt, null);
      expect(result.variables, null);
    });

    test('constructs with custom values', () {
      final now = DateTime.now();
      final error = Exception('test');

      final result = MutationResult<int, Exception, String>(
        status: MutationStatus.error,
        data: 42,
        error: error,
        submittedAt: now,
        variables: 'test-var',
        mutate: (_) async {},
        mutateAsync: (_) async => null,
        reset: () {},
      );

      expect(result.status, MutationStatus.error);
      expect(result.data, 42);
      expect(result.error, error);
      expect(result.submittedAt, now);
      expect(result.variables, 'test-var');
      expect(result.isError, true);
      expect(result.isPending, false);
      expect(result.isSuccess, false);
      expect(result.isIdle, false);
    });

    test('pending status sets correct flags', () {
      final result = MutationResult<int, Exception, String>(
        status: MutationStatus.pending,
        mutate: (_) async {},
        mutateAsync: (_) async => null,
        reset: () {},
      );

      expect(result.isIdle, false);
      expect(result.isPending, true);
      expect(result.isSuccess, false);
      expect(result.isError, false);
    });

    test('success status sets correct flags', () {
      final result = MutationResult<int, Exception, String>(
        status: MutationStatus.success,
        data: 100,
        mutate: (_) async {},
        mutateAsync: (_) async => null,
        reset: () {},
      );

      expect(result.isIdle, false);
      expect(result.isPending, false);
      expect(result.isSuccess, true);
      expect(result.isError, false);
    });

    test('mutate function is callable', () async {
      int? passedVar;
      final result = MutationResult<int, Exception, String>(
        mutate: (v) async {
          passedVar = int.parse(v);
        },
        mutateAsync: (_) async => null,
        reset: () {},
      );

      await result.mutate('42');
      expect(passedVar, 42);
    });

    test('mutateAsync function is callable', () async {
      final result = MutationResult<int, Exception, String>(
        mutate: (_) async {},
        mutateAsync: (v) async => int.parse(v),
        reset: () {},
      );

      final data = await result.mutateAsync('42');
      expect(data, 42);
    });

    test('reset function is callable', () {
      bool resetCalled = false;
      final result = MutationResult<int, Exception, String>(
        mutate: (_) async {},
        mutateAsync: (_) async => null,
        reset: () {
          resetCalled = true;
        },
      );

      result.reset();
      expect(resetCalled, true);
    });
  });

  group('MutationOptions', () {
    test('constructs with required parameters', () {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
      );

      expect(options.mutationFn('test'), isA<Future<int>>());
    });

    test('constructs with all callbacks', () {
      bool onMutateCalled = false;
      bool onSuccessCalled = false;
      bool onErrorCalled = false;
      bool onSettledCalled = false;

      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
        onMutate: (vars) async {
          onMutateCalled = true;
        },
        onSuccess: (data, vars, ctx) {
          onSuccessCalled = true;
        },
        onError: (error, vars, ctx) {
          onErrorCalled = true;
        },
        onSettled: (data, error, vars, ctx) {
          onSettledCalled = true;
        },
      );

      expect(options.onMutate, isNotNull);
      expect(options.onSuccess, isNotNull);
      expect(options.onError, isNotNull);
      expect(options.onSettled, isNotNull);
    });

    test('mutationFn is executed', () async {
      String? passedVar;
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async {
          passedVar = vars;
          return 42;
        },
      );

      final result = await options.mutationFn('test-var');
      expect(result, 42);
      expect(passedVar, 'test-var');
    });

    test('onMutate callback is optional', () {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
        onMutate: null,
      );

      expect(options.onMutate, null);
    });

    test('onSuccess callback is optional', () {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
        onSuccess: null,
      );

      expect(options.onSuccess, null);
    });

    test('onError callback is optional', () {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
        onError: null,
      );

      expect(options.onError, null);
    });

    test('onSettled callback is optional', () {
      final options = MutationOptions<int, Exception, String, void>(
        mutationFn: (vars) async => 42,
        onSettled: null,
      );

      expect(options.onSettled, null);
    });

    test('supports context type parameter', () {
      final options = MutationOptions<int, Exception, String, Map<String, dynamic>>(
        mutationFn: (vars) async => 42,
        onSuccess: (data, vars, ctx) {
          expect(ctx, isA<Map<String, dynamic>?>());
        },
      );

      expect(options, isNotNull);
    });
  });
}
