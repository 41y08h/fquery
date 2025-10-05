![Banner](https://github.com/41y08h/fquery/blob/main/media/Banner.png?raw=true)

⚡Are you ready to supercharge your Flutter app development?

Introducing [fquery](https://github.com/41y08h/fquery) - an easy-to-use, yet efficient and reliable asynchronous state management solution for Flutter! It effortlessly caches, updates, and fully manages asynchronous data in your Flutter apps.

With this powerful tool at your disposal, managing server state (REST API, GraphQL, etc), local databases like SQLite, or anything async has never been easier. Just provide a `Future` and watch the magic unfold.

## Community

<a href="https://discord.gg/udhkduc9sQ" target="_blank" >
  <img src="https://discord.com/api/guilds/1173047378190811257/widget.png?style=banner3" alt="discord server invite" />
</a>
<p/>

![GitHub Repo stars](https://img.shields.io/github/stars/41y08h/fquery?style=social)

The project's growth has been completely organic, it has grown popular in the developer community and is growing by the day, consider starring it if you've found it useful. As a developer, you too can leverage the power of this tool to create a high-quality mobile application that provides an exceptional user experience. So, why not choose it for your next project and take advantage of its powerful features to deliver a seamless experience to your users?

## 🌌 Features

- Easy to use
- Powerful and fully customizable
- No boilerplate code required
- Data fetching logic agnostic
- Automatic caching and garbage collection
- Automatic re-fetching of stale data
- State data invalidation
- Manual updates available
- Dependent queries
- Parallel queries
- Infinite queries
- Mutations

The goal of this library is to make async state management as easy as instantiating a sync variable. It can be used to data fetching from servers or apis or any other async function that you can encounter while developing your apps.

## 📄 Example

Here's a very simple widget that makes use of the `QueryBuilder` widget:

```dart
class TodoWidget extends StatelessWidget {
  const TodoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return QueryBuilder<List<Todo>, Exception>(
      options: QueryOptions(
        queryKey: QueryKey(['todos']),
        queryFn: TodosAPI.getInstance().getAll,
      ),
      builder: (context, todos) {
        if (todos.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (todos.isError) {
          return Center(child: Text(todos.error!.toString()));
        }

        return ListView.builder(
          itemCount: todos.data!.length,
          itemBuilder: (context, index) {
            final todo = todos.data![index];
            return ListTile(
              title: Text(todo.text),
            );
          },
        );
      },
    );
  }
}
```

## 🧑‍💻 Usage

You can use this library by widgets exposed by this library.
If you plan on using `flutter_hooks` then it can work super will with it because it comes with ready-to-use hooks. Refer to the section on [using with `flutter_hooks`](#using-with-flutter_hooks).

Before you start using the magic, you need to wrap you entire app or the widget tree inside which you plan on using this library.

```dart
void main() {
  runApp(
    CacheProvider(
      cache: queryCache,
      child: CupertinoApp(
```

### QueryBuilder

To use this widget you need to specify a query key and a function that fetches the async data. A query key is simply an identifier of your piece of data stored in the `QueryCache`.

You can **leverage caching** by providing the `cacheDuration` parameter in `QueryOptions`, it specifies the duration unused/inactive cache data remains in memory, past the duration the cached data will be garbage collected.

Similarly, **refetching** can be done through `refetchInterval` parameter. It becomes especially useful for data that's constantly changing (e.g. polls).

- `enabled` - specifies if the query fetcher function is automatically called when the widget renders and can be used for _dependent queries_.
- `cacheDuration` - specifies the duration unused/inactive cache data remains in memory; the cached data will be garbage collected after this duration. The longest duration will be used when different values are specified in multiple instances of the query.
- `refetchInterval` - specifies the time interval in which all queries will re-fetch the data, setting it to `null` (default) will turn off re-fetching.
- `refetchOnMount` - specifies the behavior of the query instance when the widget is first built and the data is already available.
  - `RefetchOnMount.always` - will always re-fetch when the widget is built.
  - `RefetchOnMount.stale` - will fetch the data if it is stale (see `staleDuration`).
  - `RefetchOnMount.never` - will never re-fetch.
- `staleDuration` - specifies the duration until the data becomes stale. This value applies to each query instance individually.
- `retryCount` - specifies the number of times the query will retry before showing an error
- `retryDelay` - specifies the delay between each retry

### Dependent Query

A dependent query is a query that depends on another variable for execution, or even any other query. Probably you want to run a query only after some other query, or data in a query that you don't have, e.g. a `Future`, or to fetch data only when a variable takes a certain value, e.g. a `bool` like `isAuthenticated`, for all of this or similar, dependent query can ease your load. To use this, simply pass the `enabled` option.

```dart
QueryBuilder(
  options: QueryOptions(
    queryKey: QueryKey(['users', email]),
    queryFn: getUserByEmail,
  ),
  builder: (context, user) {
    return QueryBuilder(
      options: QueryOptions(
        enabled: user.data?.username,
        queryKey: QueryKey(['posts', email]),
        queryFn: () {
          return getPostsByUsername(user.data.username);
        },
      ),
      builder: (context, posts) {
        if(posts.isFetching) {
          return Text('Waiting to start fetch');
        }
        if(posts.isLoading) {
          return Text('Loading...');
        }
        return Text('foo bar');
      }
    )
  }
)
```

### InfiniteQueryBuilder

Infinite scroll is a very common UI pattern and `fquery` comes with an `InfiniteQueryBuilder` to achieve seamless integration of this pattern. In addition to `queryKey` and `queryFn`, it requires an `initialPageParam` and `getNextPageParam` option.
The query function receives the `pageParam` parameter that can be used to fetch the current page. It can also be used to create bi-directional infinite scroll by using the `getPreviousPageParam`.

Example:

```dart
InfiniteQueryBuilder(
  InfiniteQueryOptions<PageResult, Exception, int>(
    queryKey: QueryKey([
      'infinity',
      {'type': 'scroll'}
    ]),
    queryFn: (page) {
      final infinityAPI = Infinity.getInstance();
      return infinityAPI.get(page);
    },
    initialPageParam: 1,
    getNextPageParam: (lastPage, allPages, lastPageParam, allPageParam) {
      return lastPage.hasMore ? lastPage.page + 1 : null;
    },
    refetchOnMount: RefetchOnMount.never,
  ),
  builder: (context, items) {
    return CupertinoPageScaffold(
```

### Parallel queries

Parallel queries are queries that are executed in parallel.
When the number of parallel queries does not change, there is **no extra effort** to use parallel queries. You can nest builder widgets or put them in a widget like `Column`.

```dart
Column(
  children: [
    QueryBuilder(
      options: QueryOptions(...),
      builder: (context, assets) {
        ...
      },
    ),
    QueryBuilder(
      options: QueryOptions(...),
      builder: (context, profile) {

      },
    ),
  ],
)
```

### QueriesBuilder

If you want to run multiple queries in parallel but they're dynamic in nature, meaning you don't know firsthand the number of queries you want to run (typically in a list scenario), you can make use of this widget.

```dart
// no. of queries are changing according to `text`
QueriesBuilder<Post, Exception>(
  options: List<QueryOptions<Post, Exception>>.generate(
    text,
    (i) => QueryOptions(
      queryKey: QueryKey(['posts', i + 1]),
      queryFn: () => getPost(i + 1),
      refetchOnMount: RefetchOnMount.never,
    ),
  ),
```

### IsFetchingBuilder

It can be used to get the number of queries that are currently in `isFetching` state.

### Query invalidation

This technique can manually mark the cached data as stale and potentially even re-fetch them. This is especially useful when you know that the data has been changed. `QueryCache` has an `invalidateQueries()` method that allows you to do that. To obtain the `QueryCache` instance that you had supplied from the `CacheProvider`, you can use `CacheProvider.get(context)`.

```dart
final cache = CacheProvider.of(context);

// Invalidate every query with a key that starts with `post`
// i.e ['posts'] -> invalidated
// i.e ['posts', 1] -> invalidated
cache.invalidateQueries(['posts']);

// Use `exact: true` to exactly match the query
// i.e ['posts'] -> invalidated
// i.e ['posts', 1] -> not invalidated
queryClient.invalidateQueries(['posts'], exact: true);

```

When a query is invalidated, two things will happen:

- It marks it as stale and this overrides any `staleDuration` configuration passed to the query.
- If the query is being used in a widget, it will be re-fetched, otherwise, it will be re-fetched when it is used by a widget at a later point in time.

### Manual updates

You probably already know how the data is changed and don't want to re-fetch the whole data again. You can set it manually using the `setQueryData()` method on the `QueryCache`. It takes a query key and an updater function. If the query data doesn't exist already in the cache (that's why `previous` is nullable), it'll be created.

```dart
final cache = CacheProvider.get(context);

// The `Type` of returned data must match the `Type` of data
// stored in the cache, otherwise an error will be thrown
queryClient.setQueryData<List<Post>>(['posts'], (previous) {
  return previous?.map((post) {
    return post.copyWith(
      title: "lorem ipsum"
    );
  }).toList() ?? <Post>[]
})
```

### QueryCache

A `QueryCache` is used to interact with the query cache. It is made available throughout the app using a `CacheProvider`. **It can be configured to change the default configurations of the queries.**

```dart
final cache = QueryCache(
  defaultQueryOptions: DefaultQueryOptions(
    cacheDuration: Duration(minutes: 20),
    refetchInterval: Duration(minutes: 5),
    refetchOnMount: RefetchOnMount.always,
    staleDuration: Duration(minutes: 3),
  ),
);

void main() {
  runApp(
    CacheProvider(
      cache: cache,
      child: CupertinoApp(
```

#### `QueryCache.removeQueries`

This method is used to remove any query from the cache. If the query's data is currently being rendered on the screen then it will still show and the query will also be removed from the cache.

### MutationBuilder

Similar to queries, you can also use the `useMutation` hook to mutate data on the server or just anywhere, just return a `Future` in your mutation function and you're good to go.

The following example illustrates almost the full usage of the features that come with mutations. Here we're adding a new todo asynchronously and also doing **optimistic updates**.

### Example

```dart
MutationBuilder<Todo, Exception, String, List<Todo>>(
  todosAPI.add,
  onMutate: (text) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final previousTodos =
        cache.getQueryData<List<Todo>, Exception>(['todos']) ?? [];

    // Optimistically update the todo list
    cache.setQueryData<List<Todo>, Exception>(['todos'],
        (previous) {
      final id = Random().nextInt(pow(10, 6).toInt());
      final newTodo = Todo(id: id, text: text);
      return [...(previous ?? []), newTodo];
    });

    // Pass the original data as context to the next functions
    return previousTodos;
  },
  onError: (err, text, previousTodos) {
    // On failure, revert back to original data
    cache.setQueryData<List<Todo>, Exception>(
      ['todos'],
      (_) => previousTodos as List<Todo>,
    );
  },
  onSettled: (data, error, variables, ctx) {
    // Refetch the query anyways (either error or success)
    // Or we can manually add the returned todo (result) in the onSuccess callback
    cache.invalidateQueries(['todos']);
    todoInputController.clear();
  },
  builder: (context, addTodoMutation) {
    if (todos.isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }
    if (todos.isError) {
      return Center(
        child: Text(todos.error.toString()),
      );
    }
```

To use mutations, you need a mutation function that will receive a variable parameter when you call the `mutate` function. Here in the example, it's the `text` parameter that we're using as a variable that the mutation function will receive.

Type parameters -

- `TData` - type of data that'll be returned from the mutation function.
- `TError` - type of error that'll be thrown when the mutation fails.
- `TVariables` - type of the variable that your mutation function will receive.
- `TContext` - type of the context object you'll pass around in mutation callbacks. It has been illustrated in the example how `onMutate` returns the original list of todos to revert when the mutation fails.

You can also pass callback functions like `onSuccess` or `onError` -

- `onMutate` - this callback will be called before the mutation is executed and is passed with the same variables the mutation function would receive.
- `onSuccess` - this callback will be called if the mutation was successful and receives the result of the mutation as an argument (in addition to the passed variables in the mutation function).
- `onError` - this callback will be called if the mutation wasn't successful and receives the error as an argument (in addition to the passed variables in the mutation function).
- `onSettled` - this callback will be called after the mutation has been executed and will receive both the result (if successful) and error(if unsuccessful), in case of success the error will be null and vice-versa.

## Using with `flutter_hooks`

If you plan on using this package with `flutter_hooks`, you can have a seamless experience as this package comes with ready-to-use hooks that include -

- `useQuery`
- `useInfiniteQuery`
- `useQueries`
- `useMutation` (for mutations)
- `useIsFetching` (to know the number of queries that are currently being fetched)

## Contributing

If you've ever wanted to contribute to open source, and a great cause, now is your chance ✨, feel free to open an issue or submit a PR at the [GitHub repo](https://github.com/41y08h/fquery). See [Contribution guide](CONTRIBUTING.md) for more details.

## Contributors ✨

Thanks go to these wonderful people:

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/41y08h"><img src="https://avatars.githubusercontent.com/u/63099829?v=4?s=100" width="100px;" alt="Piyush"/><br /><sub><b>Piyush</b></sub></a><br /><a href="#bug-41y08h" title="Bug reports">🐛</a> <a href="#code-41y08h" title="Code">💻</a> <a href="#doc-41y08h" title="Documentation">📖</a> <a href="#design-41y08h" title="Design">🎨</a> <a href="#maintenance-41y08h" title="Maintenance">🚧</a> <a href="#review-41y08h" title="Reviewed Pull Requests">👀</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/cynthiakonar"><img src="https://avatars.githubusercontent.com/u/89989829?v=4?s=100" width="100px;" alt="Cynthia"/><br /><sub><b>Cynthia</b></sub></a><br /><a href="#doc-cynthiakonar" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/RajvirSingh1313"><img src="https://avatars.githubusercontent.com/u/63385587?v=4?s=100" width="100px;" alt="Rajvir Singh"/><br /><sub><b>Rajvir Singh</b></sub></a><br /><a href="#design-RajvirSingh1313" title="Design">🎨</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/kollinmurphy"><img src="https://avatars.githubusercontent.com/u/65209071?v=4?s=100" width="100px;" alt="Kollin Murphy"/><br /><sub><b>Kollin Murphy</b></sub></a><br /><a href="#doc-kollinmurphy" title="Documentation">📖</a> <a href="#code-kollinmurphy" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/2coo"><img src="https://avatars.githubusercontent.com/u/40331144?v=4?s=100" width="100px;" alt="Tuco T."/><br /><sub><b>Tuco T.</b></sub></a><br /><a href="#bug-2coo" title="Bug reports">🐛</a> <a href="#code-2coo" title="Code">💻</a> <a href="#ideas-2coo" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://blog.wadackel.me"><img src="https://avatars.githubusercontent.com/u/5393238?v=4?s=100" width="100px;" alt="tsuyoshi wada"/><br /><sub><b>tsuyoshi wada</b></sub></a><br /><a href="#bug-wadackel" title="Bug reports">🐛</a> <a href="#code-wadackel" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/du-nt"><img src="https://avatars.githubusercontent.com/u/61105819?v=4?s=100" width="100px;" alt="du-nt"/><br /><sub><b>du-nt</b></sub></a><br /><a href="#ideas-du-nt" title="Ideas, Planning, & Feedback">🤔</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="http://clynamic.net"><img src="https://avatars.githubusercontent.com/u/11785085?v=4?s=100" width="100px;" alt="clragon"/><br /><sub><b>clragon</b></sub></a><br /><a href="#bug-clragon" title="Bug reports">🐛</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://allcontributors.org) specification.
Contributions of any kind are welcome!
