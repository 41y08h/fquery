![Banner](https://github.com/41y08h/fquery/blob/main/media/Banner.png?raw=true)

⚡Are you ready to supercharge your Flutter app development?

Introducing [fquery](https://github.com/41y08h/fquery) - an easy-to-use, yet efficient and reliable asynchronous state management solution for Flutter! It effortlessly caches, updates, and fully manages asynchronous data in your Flutter apps.

With this powerful tool at your disposal, managing server state (REST API, GraphQL, etc), local databases like SQLite, or anything async has never been easier. Just provide a `Future` and watch the magic unfold.

### Community

<a href="https://discord.gg/udhkduc9sQ" target="_blank" >
  <img src="https://discord.com/api/guilds/1173047378190811257/widget.png?style=banner3" alt="discord server invite" />
</a>

## Trusted & Used by

### UC San Diego

![UC San Diego](https://github.com/41y08h/fquery/blob/main/media/ucsd-banner.png?raw=true)

The University of California, San Diego has shifted to [fquery](https://github.com/41y08h/fquery/), _moving away from traditional state management solutions like provider, bloc, etc,_ as the backbone of their [mobile application](https://mobile.ucsd.edu/), which has over 30,000 users and serves as the app used by the generations of students.
With fquery's efficient and easy-to-use async state management, the developers are now enjoying the comfort of seamless state management by refactoring spaghetti blocks of codes, even files with 200 lines to just 20 lines. They also noticed a significant reduction of time in the hot reload.

All of this is only to have more time, and an easy-to-manage structure to develop the features that matter the most. They are confident that the codebase will continue to be manageable, and provide the team with a better structure.

### Stargazers and others

![GitHub Repo stars](https://img.shields.io/github/stars/41y08h/fquery?style=social)

The project's growth has almost been completely organic, it has grown popular in the developer community and is growing by the day, consider starring it if you've found it useful.

As a developer, you too can leverage the power of this tool to create a high-quality mobile application that provides an exceptional user experience. [fquery](https://github.com/41y08h/fquery/) is a reliable and efficient solution that has already been proven successful in UC San Diego's app. So, why not choose it for your next project and take advantage of its powerful features to deliver a seamless experience to your users?

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

## ❔Defining the problem

Have you ever wondered **how to effectively manage server state in your Flutter apps**? Many developers resort to using Riverpod, Bloc, `FutureBuilder``, or any other general-purpose state management solution. However, these solutions often lead to writing repetitive code that handles data fetching, caching, and other logic.

The truth is, that general-purpose state management solutions are not the best choice when it comes to handling asynchronous server state. This is due to the **unique nature of server state - it is asynchronous and requires specific APIs for fetching and updating**. Additionally, the server state is stored in a remote location, which means **it can be modified without your knowledge from anywhere in the world**. This alone requires a lot of effort to keep the data synchronized and ensure that it is up-to-date.

### How does ⚡fquery tackle this problem?

[fquery](https://github.com/41y08h/fquery) is powered by [flutter_hooks](https://pub.dev/packages/flutter_hooks). It is very similar to [swr](https://github.com/vercel/swr) and [react-query](https://github.com/tanstack/query). With fquery, you can make use of easy-to-use hooks to retrieve data from a Future and the rest of the process is automated. [fquery](https://github.com/41y08h/fquery) is highly configurable, allowing you to customize it to meet your specific needs. You can configure every aspect of it to make it work optimally for your use case.

## 📄 Example

Here's a very simple widget that makes use of the `useQuery` hook:

```dart
class Posts extends HookWidget {
  const Posts({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final posts = useQuery(['posts'], getPosts);

    return Builder(
      builder: (context) {
        if (posts.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (posts.isError) {
          return Center(child: Text(posts.error!.toString()));
        }

        return ListView.builder(
          itemCount: posts.data!.length,
          itemBuilder: (context, index) {
            final post = posts.data![index];
            return ListTile(
              title: Text(post.title),
            );
          },
        );
      },
    );
  }
}
```

## 🧑‍💻 Usage

You can either install [flutter_hooks](https://pub.dev/packages/flutter_hooks) before using this library or use the widgets like `QueryBuilder` and `MutationBuilder` that comes with fquery. You'll need to wrap
your entire app inside a `QueryClientProvider` and you are good to go.

```dart
void main() {
  runApp(
    QueryClientProvider(
      queryClient: queryClient,
      child: CupertinoApp(
```

### Queries

To query data in your widgets, you can either extend your widget using `HookWidget` or `StatefulHookWidget` (for stateful widgets) or use the `QueryBuilder` widget, see below. These classes are exported from the [flutter_hooks](https://pub.dev/packages/flutter_hooks) package.

A query instance is a subscription to asynchronous data stored in the cache. Every query needs -

- A **Query key**, uniquely identifies the query stored in the cache.
- A `Future` that either resolves or throws an error

The same query key can be used in multiple instances of the `useQuery` hook and the data will be shared throughout the app.

```dart
Future<List<Post>> getPosts() async {
  final res = await Dio().get('https://jsonplaceholder.typicode.com/posts');
  return (res.data as List)
      .map((e) => Post.fromJson(e as Map<String, dynamic>))
      .toList();
}

class Posts extends HookWidget {
  const Posts({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final posts = useQuery(['posts'], getPosts);
```

The returned value of the `useQuery` hook is an instance of `UseQueryResult` and contains all the information related to that query. A `Builder` widget comes in handy when rendering the results.

```dart
// The query has no data to display
if (posts.isLoading) {
  return const Center(child: CircularProgressIndicator());
}

// An error has occurred
if (posts.isError) {
  return Center(child: Text(posts.error!.toString()));
}

// Success, data is ready to display
return ListView.builder(
  itemCount: posts.data!.length,
  itemBuilder: (context, index) {
    final post = posts.data![index];
    return ListTile(
      title: Text(post.title),
    );
  },
);
```

### Query without `flutter_hooks`

You can have queries without extending your widget with `HookWidget`. Just use the `QueryBuilder` widget and you're good to go.

The `QueryBuilder` takes 3 required arguments, first one is the query key, second one is query function and the third one is a named parameter, `builder`.

```dart
QueryBuilder<List<Todo>, Error>(
  const ['todos'],
  todosAPI.getAll,
  refetchOnMount: RefetchOnMount.never,
  refetchInterval: const Duration(seconds: 10),
  enabled: isEnabled.value,
  builder: (context, todos) {
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

    ...
```

### Query configuration

A query is fully customizable to match your needs, these configurations can be passed as named parameters into the `useQuery` hook

```dart
// These are default configurations
final posts = useQuery(
  ['posts'],
  getPosts,
  enabled: true,
  cacheDuration: const Duration(minutes: 5),
  refetchInterval: null // The query will not re-fetch by default,
  refetchOnMount: RefetchOnMount.stale,
  staleDuration: const Duration(seconds: 10),
  retryCount: 3,
  retryDelay: const Duration(seconds: 1, milliseconds: 500)
);
```

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
final user = useQuery(['users', email], getUserByEmail);

// This query will not execute until the above is successful and the username is available
final username = user.data?.username;
final posts = useQuery(['posts', ], getPosts, enabled: !username);


final isAuthenticated = session != null;
final keys = useQuery(['keys', session.id], enabled: isAuthenticated)
```

### Infinite queries

Infinite scroll is a very common UI pattern and fquery comes with a `useInfiniteQuery` hook to handle those needs. In addition to `queryKey` and `queryFn`,
it requires an `initialPageParam` and `getNextPageParam` option.
The query function receives the `pageParam` parameter
that can be used to fetch the current page.

It can also be used to create bi-directional infinite scroll by using the `getPreviousPageParam`.

Example:

```dart
final items = useInfiniteQuery<PageResult, Error, int>(
  ['infinity'],
  (page) => infinityAPI.get(page),
  initialPageParam: 1,
  getNextPageParam: ((lastPage, allPages, lastPageParam, allPageParam) {
    return lastPage.hasMore ? lastPage.page + 1 : null;
  }),
);
```

### Parallel queries

Parallel queries are queries that are executed in parallel.
When the number of parallel queries does not change, there is **no extra effort** to use parallel queries.

```dart
// These will execute in parallel
final posts = useQuery(['posts'], getProfile)
final comments = useQuery(['comments'], getProfile)
```

### Dynamic Parallel queries

If the number of queries you need to execute is changing from render to render, you cannot use manual querying since that would violate the rules of hooks. Instead fquery provides the `useQueries` hook for that purpose.

```dart
// See how the number of queries are changing with `text.value`
final posts = useQueries<Post, Error>(
  List<UseQueriesOptions<Post, Error>>.generate(text.value,
  (i) => UseQueriesOptions(
    queryKey: ['posts', i + 1],
    fetcher: () => getPost(i + 1),
    refetchOnMount: RefetchOnMount.never,
  ),
));
```

### Global fetching indicators

If you want to know the number of all the queries that are being fetched at the moment, you can use the `useIsFetching` hook provided by the library.

```dart
// `fetchingCount` is an int
final fetchingCount = useIsFetching();
```

### Query invalidation

This technique can manually mark the cached data as stale and potentially even re-fetch them. This is especially useful when you know that the data has been changed. `QueryClient` (see [below](#queryclient)) has an `invalidateQueries()` method that allows you to do that. **You can make use of the `useQueryClient` hook to obtain the instance of `QueryClient`** that you passed with `QueryClientProvider`.

```dart
final queryClient = useQueryClient();

// Invalidate every query with a key that starts with `post`
queryClient.invalidateQueries(['posts']);

// here, both queries will be invalidated
final posts = useQuery(['posts'], getPosts);
final post = useQuery(['posts', 1], getPosts);


// Use `exact: true` to exactly match the query
queryClient.invalidateQueries(['posts'], exact: true);

// here, only this will invalidate
final posts = useQuery(['posts'], getPosts);
```

When a query is invalidated, two things will happen:

- It marks it as stale and this overrides any `staleDuration` configuration passed to `useQuery`.
- If the query is being used in a widget, it will be re-fetched, otherwise, it will be re-fetched when it is used by a widget at a later point in time.

### Manual updates

You probably already know how the data is changed and don't want to re-fetch the whole data again. You can set it manually using the `setQueryData()` method on the `QueryClient`. It takes a query key and an updater function. If the query data doesn't exist already in the cache (that's why `previous` is nullable), it'll be created.

```dart
final queryClient = useQueryClient();

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

### QueryClient

A `QueryClient` is used to interact with the query cache. It is made available throughout the app using a `QueryClientProvider`. **It can be configured to change the default configurations of the queries.**

```dart
final queryClient = QueryClient(
  defaultQueryOptions: DefaultQueryOptions(
    cacheDuration: Duration(minutes: 20),
    refetchInterval: Duration(minutes: 5),
    refetchOnMount: RefetchOnMount.always,
    staleDuration: Duration(minutes: 3),
  ),
);

void main() {
  runApp(
    QueryClientProvider(
      queryClient: queryClient,
      child: CupertinoApp(
```

## Mutations

Similar to queries, you can also use the `useMutation` hook to mutate data on the server or just anywhere, just return a `Future` in your mutation function and you're good to go.

The following example illustrates almost the full usage of the features that come with mutations. Here we're adding a new todo asynchronously and also doing **optimistic updates**.

### Example

```dart
final addTodoMutation = useMutation<Todo, Exception, String, List<Todo>>(
        todosAPI.add, onMutate: (text) async {
      final previousTodos =
          queryClient.getQueryData<List<Todo>>(['todos']) ?? [];

      // Optimistically update the todo list
      queryClient.setQueryData<List<Todo>>(['todos'], (previous) {
        final id = Random().nextInt(pow(10, 6).toInt());
        final newTodo = Todo(id: id, text: text);
        return [...(previous ?? []), newTodo];
      });

      // Pass the original data as context to the next functions
      return previousTodos;
    }, onError: (err, text, previousTodos) {
      // On failure, revert to original data
      queryClient.setQueryData<List<Todo>>(
        ['todos'],
        (_) => previousTodos as List<Todo>,
      );
    }, onSettled: (data, error, variables, ctx) {
      // Refetch the query anyway (either error or success)
      // Or we can manually add the returned todo (result) in the onSuccess callback
      client.invalidateQueries(['todos']);
      todoInputController.clear();
    });
```

### Usage

To use mutations, you need a mutation function that will receive a variable parameter when you call the `mutate` function. Here in the example, it's the `text` parameter that we're using as a variable that the mutation function will receive.

Like queries, to use mutations you can either extend the widget using `HookWidget` or `StatefulHookWidget` (for stateful widgets) or use the `MutationBuilder` widget, see below.

The `useMutation` hook takes 4 type arguments -

- `TData` - type of data that'll be returned from the mutation function.
- `TError` - type of error that'll be thrown when the mutation fails.
- `TVariables` - type of the variable that your mutation function will receive.
- `TContext` - type of the context object you'll pass around in mutation callbacks. It has been illustrated in the example how `onMutate` returns the original list of todos to revert when the mutation fails.

You can also pass callback functions like `onSuccess` or `onError` -

- `onMutate` - this callback will be called before the mutation is executed and is passed with the same variables the mutation function would receive.
- `onSuccess` - this callback will be called if the mutation was successful and receives the result of the mutation as an argument (in addition to the passed variables in the mutation function).
- `onError` - this callback will be called if the mutation wasn't successful and receives the error as an argument (in addition to the passed variables in the mutation function).
- `onSettled` - this callback will be called after the mutation has been executed and will receive both the result (if successful) and error(if unsuccessful), in case of success the error will be null and vice-versa.

The `useMutation` hook will return [UseMutationResult] which has everything associated with the mutation.

```dart
final TData? data;
final TError? error;
final bool isIdle;
final bool isPending;
final bool isSuccess;
final bool isError;
final MutationStatus status;
final Future<void> Function(TVariables) mutate;
final DateTime? submittedAt;
final void Function() reset;
final TVariables? variables;
```

### Mutation without `flutter_hooks`

You can have queries without extending your widget with `HookWidget`. Just use the `QueryBuilder` widget and you're good to go.

The `MutationBuilder` takes 2 required arguments, first one is the mutation function and second one is a named parameter, `builder`.

```dart
MutationBuilder((id) async {
  await todosAPI.delete(todo.id);
  return id;
}, onSuccess: (id, _, ctx) {
  client.setQueryData<List<Todo>>(
    ['todos'],
    (previous) {
      if (previous == null) return [];
      return previous.where((e) {
        return (e.id != id);
      }).toList();
    },
  );
}, builder: (context, mutation) {
  return CupertinoButton(
  ...
```

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
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://allcontributors.org) specification.
Contributions of any kind are welcome!
