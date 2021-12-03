import 'package:flutter/material.dart';
import 'package:github_trending/client_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  await initHiveForFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GraphQLClientProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GitHub Trending GraphQL',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const GitHubTrendingList(),
      ),
    );
  }
}

class GitHubTrendingList extends StatefulWidget {
  const GitHubTrendingList({Key? key}) : super(key: key);

  @override
  State<GitHubTrendingList> createState() => _GitHubTrendingListState();
}

class _GitHubTrendingListState extends State<GitHubTrendingList> {
  String readRepositories = """
    query ReadRepositories(\$nRepositories: Int!) {
      viewer {
        repositories(last: \$nRepositories) {
          nodes {
            id
            name
            viewerHasStarred
          }
        }
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Content(queryString: readRepositories,),
    );
  }
}

class Content extends StatelessWidget {
  const Content({Key? key, required this.queryString}) : super(key: key);

  final String queryString;

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(queryString),
        variables: {
          'nRepositories': 50,
        },
        pollInterval: const Duration(seconds: 10),
      ),
      // fetchMore() is used for pagination
      builder: (QueryResult result, { Refetch? refetch, FetchMore? fetchMore }) {
        if (result.hasException) {
          return Text(result.exception.toString());
        }

        if (result.isLoading) {
          return const Text('Loading');
        }

        // it can be either Map or List
        List repositories = result.data!['viewer']['repositories']['nodes'];

        return ListView.builder(
            itemCount: repositories.length,
            itemBuilder: (context, index) {
              final repository = repositories[index];

              return Text(repository['name']);
            });
      },
    );
  }
}
