import 'package:flutter/material.dart';
import 'package:github_trending/token.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

/// Wraps an application with the `graphql_flutter` client.
class GraphQLClientProvider extends StatelessWidget {
  GraphQLClientProvider({Key? key, required this.child}) : super(key: key) {
    final String token = TokenLoader.getToken();

    final HttpLink httpLink = HttpLink(
      'https://api.github.com/graphql',
    );

    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    final Link link = authLink.concat(httpLink);

    client = ValueNotifier(
      GraphQLClient(
        link: link,
        cache: GraphQLCache(store: HiveStore()),
      ),
    );
  }

  final Widget child;
  late final ValueNotifier<GraphQLClient> client;

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: child,
    );
  }
}