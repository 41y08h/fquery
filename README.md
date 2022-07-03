⚡FQuery is a powerful async state management solution for flutter. It caches, updates and fully manages asynchronous data in your flutter apps.

It can be used for managing server state (REST API, GraphQL, etc), local databses like SQLite, or just anything that is async, just give it a `Future` and you are good to go.

## 🌌 Features

- Fully customizable
- No boilerplate code and easy to use
- Data feching logic agnostic
- Automatic caching
- Garbage collection
- Auto refetching stale data
- State data invalidation
- Manual updates

## ❔Problem definition

Let me ask you a simple question, **How do you manage server state in your flutter apps?** Majority developers will answer that they use Riverpod, Bloc, `FutureBuilder`, or any other general purpose state management solution. This usually results in writing a lot of boilerplate code and repeating data fetching, caching, and other logic over and over again.

The thing is, existing state management solutions are very general and are suited for anything that's a global state in you app _and hence the term "general"_, but do not work great when used for asynchronous state like server state, this is because server state is way too different. Server state is -

- Asynchrounous state and requires asynchronous APIs for fetching and updating)
- Stored in a remote location and _can be changed without your knowledge, from just anywhere in the world_ and **this alone means a lot, staying synchronized with the data and making sure that it is not stale**

### How does FQuery tackle this problem?

FQuery is powerd by [flutter_hooks](https://pub.dev/packages/flutter_hooks).
It provides you easy to use hooks. Just tell it where to get the data by giving it a `Future` and the rest is automatic. It can be fully configured to match your needs, you can configure each and every thing.

## 📄 Example

Here's a very simple widget that makes use of the `useQuery` hook -

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

You'll need to install [flutter_hooks](https://pub.dev/packages/flutter_hooks) before you can start using this library.

### Queries

To query data in your widgets, you'll need to extend the widget using `HookWidget` or `StatefulHookWidget`(for stateful widgets). These classes are exported from the [flutter_hooks](https://pub.dev/packages/flutter_hooks) pacakge.

A query instance is a subscription to an asynchronous data stored in the cache. Every query needs -

- A **Query key**, it uniquely identifies the query stored in the cache.
- A `Future` that either resolves or throws an error

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

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
