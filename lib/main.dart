import 'package:flutter/material.dart';
import 'package:github_trending/client_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  await initHiveForFlutter();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String language = "";
  final List<String> items = [
    '',
    'C',
    'C++',
    'C#',
    'CSS',
    'HTML',
    'Java',
    'JavaScript',
    'Objective-C',
    'Objective-C++',
    'Python',
    'Rust',
  ];

  @override
  Widget build(BuildContext context) {
    return GraphQLClientProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GitHub Trending GraphQL',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.black,
          ),
        ),
        home: Scaffold(
          backgroundColor: Colors.black,
          bottomSheet: DropdownButton<String>(
            isExpanded: true,
            value: language,
            icon: const Icon(Icons.arrow_downward),
            iconSize: 24,
            onChanged: (String? newValue) {
              setState(() {
                language = newValue!;
              });
            },
            items: items.map<DropdownMenuItem<String>>((String val) {
              return DropdownMenuItem<String>(
                  value: val,
                  child: val.isEmpty ? const Text('All Languages') : Text(val));
            }).toList(),
            selectedItemBuilder: (BuildContext context) {
              return items.map<Widget>((String item) {
                return Center(
                    child: Text(
                  (item.isNotEmpty ? item : "All languages"),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500),
                ));
              }).toList();
            },
          ),
          body: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: Content(language: language),
          ),
        ),
      ),
    );
  }
}

class Content extends StatelessWidget {
  const Content({Key? key, required this.language}) : super(key: key);

  final String language;

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(queryRepositories),
        variables: {
          "query":
              "stars:>1000 forks:>100 created:>2021-01-01 sort:stars ${language.isNotEmpty ? "language:$language" : ""}",
        },
        pollInterval: const Duration(minutes: 1),
      ),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        if (result.hasException) {
          return Center(
            child: Column(
              children: <Widget>[
                Text("Error: ${result.exception}"),
                TextButton(onPressed: refetch, child: const Text("Try Again")),
              ],
            ),
          );
        }

        if (result.isLoading) {
          return Center(
              child: Text(
            'Searching $language Repos...',
            style: const TextStyle(fontSize: 24),
          ));
        }

        List repositories = result.data!['search']['nodes'];

        return ListView.builder(
            padding: const EdgeInsets.only(
              top: 26,
              bottom: 50,
            ),
            itemCount: repositories.length,
            itemBuilder: (context, index) {
              final repository = repositories[index];
              final bool hasLang = repository['languages']['edges'].isNotEmpty;
              final String name = repository['name'];
              final String owner = repository['owner']['login'];
              final String description = repository['description'] ?? "";

              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RepoView(
                              repoName: name,
                              repoOwner: owner,
                            ))),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  color: const Color(0xff303030),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(name,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(owner,
                            style: const TextStyle(
                                color: Color(0xffc0c0c0),
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text(description,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w400)),
                        const SizedBox(height: 6),
                        Row(children: [
                          if (hasLang)
                            Text(
                                "${repository['languages']['edges'][0]['node']['name']}",
                                style: TextStyle(
                                    color: Color(int.parse("0xff" +
                                        repository['languages']['edges'][0]
                                                ['node']['color']
                                            .toString()
                                            .substring(1))),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text("${repository['forkCount']} ⑂",
                              style: const TextStyle(
                                  color: Color(0xffc0c0c0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text("${repository['stargazerCount']} ✰",
                              style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ]),
                ),
              );
            });
      },
    );
  }
}

class RepoView extends StatelessWidget {
  const RepoView({Key? key, required this.repoName, required this.repoOwner})
      : super(key: key);

  final String repoName;
  final String repoOwner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff303030),
      body: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Query(
                options: QueryOptions(
                    document: gql(querySingleRepo),
                    variables: {
                      "repoName": repoName,
                      "repoOwner": repoOwner
                    }),
                builder: (QueryResult result,
                    {Refetch? refetch, FetchMore? fetchMore}) {

                  if (result.hasException) {
                    return Center(
                      child: TextButton(
                          onPressed: refetch, child: const Text("Try Again")),
                    );
                  }

                  if (result.isLoading) {
                    return Container(
                      padding: const EdgeInsets.only(top: 250),
                      alignment: Alignment.center,
                      child: const Text(
                        'Loading Repo...',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.deepPurple,
                        ),
                      ),
                    );
                  }

                  final repository = result.data!['repository'];
                  final String createdAt =
                      repository['createdAt'].toString().substring(0, 10);
                  final String updatedAt =
                      repository['updatedAt'].toString().substring(0, 10);
                  final String description = repository['description'];
                  final int forkCount = repository['forkCount'];
                  final int stargazerCount = repository['stargazerCount'];
                  final bool hasLang =
                      repository['languages']['edges'].isNotEmpty;
                  final String languages = repository['languages']['edges']
                      .map((edge) => edge['node']['name'])
                      .toList()
                      .join(", ");
                  final int branchCount = repository['refs']['totalCount'];
                  final int releaseCount = repository['releases']['totalCount'];

                  return Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.only(top: 50, left: 16, right: 16),
                      child: Column(children: <Widget>[
                        FittedBox(
                          child: Text(repoName,
                              style: const TextStyle(
                                  fontSize: 38, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 4),
                        Text("By $repoOwner",
                            style: const TextStyle(
                                color: Color(0xffc0c0c0),
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text("Branches: $branchCount    Releases: $releaseCount",
                            style: const TextStyle(
                                color: Color(0xffc0c0c0),
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),
                        Text(description,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400)),
                        const Spacer(),
                        Row(children: [
                          Text("Updated $updatedAt"),
                          const Spacer(),
                          Text("Created $createdAt"),
                        ]),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(children: [
                          if (hasLang)
                            (Expanded(
                                child: Text(
                              languages,
                              overflow: TextOverflow.ellipsis,
                            )))
                          else
                            const Spacer(),
                          Text("$forkCount ⑂",
                              style: const TextStyle(
                                  color: Color(0xffc0c0c0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text("$stargazerCount ✰",
                              style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ]),
                    ),
                  );
                }),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                      vertical: 13, horizontal: 32),
                  decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: const Text("Back", style: TextStyle(color: Colors.white),
                )),
              ),
            ]),
      ),
    );
  }
}

const String queryRepositories = """
  query queryRepositories(\$query: String!) {
    search(first: 10, type: REPOSITORY, query: \$query) { 
      nodes {
        ... on Repository {
          name
          owner {
            login
          }
          languages(orderBy: {field: SIZE, direction: DESC}, first: 1) {
            edges {
              node {
                color
                name
              }
            }
          }
          description
          forkCount
          stargazerCount
        }
      }
    }
  }
""";

const String querySingleRepo = """
  query querySingleRepo(\$repoName: String! \$repoOwner: String!) {
    repository(name:\$repoName owner:\$repoOwner) {
      createdAt
      updatedAt
      description
      forkCount
      stargazerCount
      languages(orderBy: {field: SIZE, direction: DESC}, first: 6) {
        edges {
          node {
            color
            name
          }
        }
      }
      refs(first: 0, refPrefix: "refs/heads/") {
        totalCount
      }
      releases {
        totalCount
      }
    }
  }
""";
