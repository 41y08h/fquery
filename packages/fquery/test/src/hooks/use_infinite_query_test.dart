import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useInfiniteQuery', () {
    group('hasPreviousPage/hasNextPage calculation', () {
      ({bool hasNextPage, bool hasPreviousPage}) calculatePageFlags({
        required List<String> pages,
        required List<int> pageParams,
        required int? Function(String, List<String>, int, List<int>)
            getNextPageParam,
        int? Function(String, List<String>, int, List<int>)?
            getPreviousPageParam,
      }) {
        final firstPage = pages.first;
        final lastPage = pages.last;
        final firstPageParam = pageParams.first;
        final lastPageParam = pageParams.last;

        final nextPageParam = getNextPageParam(
          lastPage,
          pages,
          lastPageParam,
          pageParams,
        );

        final previousPageParam = getPreviousPageParam?.call(
          firstPage,
          pages,
          firstPageParam,
          pageParams,
        );

        return (
          hasNextPage: nextPageParam != null,
          hasPreviousPage: previousPageParam != null,
        );
      }

      group('hasPreviousPage', () {
        test('returns false when getPreviousPageParam is not provided', () {
          final result = calculatePageFlags(
            pages: ['Page 1'],
            pageParams: [1],
            getNextPageParam: (lastPage, allPages, lastParam, allParams) {
              return lastParam < 3 ? lastParam + 1 : null;
            },
            getPreviousPageParam: null,
          );

          expect(result.hasPreviousPage, isFalse);
        });

        test('returns true when getPreviousPageParam returns a value', () {
          final result = calculatePageFlags(
            pages: ['Page 5'],
            pageParams: [5],
            getNextPageParam: (lastPage, allPages, lastParam, allParams) {
              return lastParam < 10 ? lastParam + 1 : null;
            },
            getPreviousPageParam: (firstPage, allPages, firstParam, allParams) {
              return firstParam > 1 ? firstParam - 1 : null;
            },
          );

          expect(result.hasPreviousPage, isTrue);
        });

        test('returns false when getPreviousPageParam returns null', () {
          final result = calculatePageFlags(
            pages: ['Page 1'],
            pageParams: [1],
            getNextPageParam: (lastPage, allPages, lastParam, allParams) {
              return lastParam < 10 ? lastParam + 1 : null;
            },
            getPreviousPageParam: (firstPage, allPages, firstParam, allParams) {
              return firstParam > 1 ? firstParam - 1 : null;
            },
          );

          expect(result.hasPreviousPage, isFalse);
        });

        test('uses first page param for calculation', () {
          final result = calculatePageFlags(
            pages: ['Page 1', 'Page 2', 'Page 3'],
            pageParams: [1, 2, 3],
            getNextPageParam: (lastPage, allPages, lastParam, allParams) {
              return lastParam < 10 ? lastParam + 1 : null;
            },
            getPreviousPageParam: (firstPage, allPages, firstParam, allParams) {
              return firstParam > 1 ? firstParam - 1 : null;
            },
          );

          // firstPageParam is 1, so no previous page
          expect(result.hasPreviousPage, isFalse);
        });
      });

      group('hasNextPage', () {
        test('returns true when getNextPageParam returns a value', () {
          final result = calculatePageFlags(
            pages: ['Page 1'],
            pageParams: [1],
            getNextPageParam: (lastPage, allPages, lastParam, allParams) {
              return lastParam < 3 ? lastParam + 1 : null;
            },
          );

          expect(result.hasNextPage, isTrue);
        });

        test('returns false when getNextPageParam returns null', () {
          final result = calculatePageFlags(
            pages: ['Page 3'],
            pageParams: [3],
            getNextPageParam: (lastPage, allPages, lastParam, allParams) {
              return lastParam < 3 ? lastParam + 1 : null;
            },
          );

          expect(result.hasNextPage, isFalse);
        });

        test('uses last page param for calculation', () {
          final result = calculatePageFlags(
            pages: ['Page 1', 'Page 2'],
            pageParams: [1, 2],
            getNextPageParam: (lastPage, allPages, lastParam, allParams) {
              return lastParam < 3 ? lastParam + 1 : null;
            },
          );

          // lastPageParam is 2, which is < 3
          expect(result.hasNextPage, isTrue);
        });
      });
    });
  });
}
