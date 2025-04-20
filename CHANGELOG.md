## 1.0.0-beta.1

- Beta of initial version.

## 1.0.0-beta.2

- Fix example project directory
- Add API docs
- Add documentation in README.md
- Fix some APIs

## 1.0.0-beta.3

- Fix typos in documentation
- Add banner in README.md

## 1.0.0-beta.3+1

- Fix banner image path in README.md

## 1.0.0-beta.4

- Bug fix: enable option not working when changed to true
- Bug fix: when the child widget calls the same query the parent has, it triggers the rebuilding parent widget, and both stopped
- Docs: Improve it, add new sections - users, contributors, dependent query, and more
- Update dependencies

## 1.0.0-beta.5

- Fix insecure (http) link in README

## 1.1.0-beta.1

- New feature: Mutations

## 1.2.0-beta.1

- New feature: `QueryBuilder` widget, can be used without extending the widget with `HookWidget`
- New feature: `MutationBuilder` widget, can be used without extending the widget with `HookWidget`
- New feature: `useQueries` hook, can be used to have dynamic parallel queries
- New feature: `useIsFetching` hook, can be used to get the number of queries that are being fetched
- New feature: `retryCount` and `retryDelay` option is now available with `useQuery`/`useQueries`
- Bug fix: query didn't cancel when it was being fetched and enabled option changed to false
- Bug fix: indefinite loading state when there is an error and invalidate is called

## 1.3.0-beta.1

- New feature: Infinite queries with `useInfiniteQuery`

## 1.3.1-beta.1

- Bug fix: Rebuild error when navigating between screens with the same useQuery

## 1.3.1-beta.2

- Remove unused import in code

## 1.3.2-beta.2

- Bug fix (re-fix): Rebuild error when navigating between screens with the same useQuery

## 1.4.0-beta.1

- Bug fixes
- Expose `isInvalidated` and `isRefetchEror` in result of `useQuery` and `useInfiniteQuery`

## 1.5.0-beta.1

- Bug fix: retry count and retry delay parameters not working
- Bug fix: default values not working for retry count and retry delay
- New feature: `QueryClientBuilder` widget
- New feature: `QueryClient.removeQueries` method
- Bug fix: `QueryClient.setQueryData` to build new query if it doesn't exist
- Bug fixes: general

## 1.5.2-beta.1

- Bug fix: Pending `Timer`s which caused errors in tests
- Bug fix: Query function was being called twice
- Bug fix: Retry count: 0 not working

## 1.5.3-beta.1

- New feature: `InfiniteQueryBuilder` widget, can be used without extending the widget with `HookWidget`
