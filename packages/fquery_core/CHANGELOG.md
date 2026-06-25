## 3.0.0

- Initial version.

## 3.0.1

- Fix query cache notifications

## 3.0.2

- Fix `invalidateQueries` method to remove redundant loop

## 3.1.0

- Add public API docs
- Fix `maxPages` parameter not being assigned
- Fix retry resolver attempts count
- Added new `isReadOnly` paramter to out-out of observers subscribing to cache.
- Fix refetch routine didn't work for infinite queries (it only fetched it again and appended it, fixes [#61](https://github.com/41y08h/fquery/issues/61))
- Fix retry didn't work for initial data fetch errors. See [#60](https://github.com/41y08h/fquery/issues/60)
