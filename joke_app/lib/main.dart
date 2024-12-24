import 'package:flutter/material.dart';
import 'jokeService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import Connectivity package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jokes App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      home: JokeListPage(),
    );
  }
}

class JokeListPage extends StatefulWidget {
  const JokeListPage({super.key});

  @override
  _JokeListPageState createState() => _JokeListPageState();
}

class _JokeListPageState extends State<JokeListPage> {
  final JokeService _jokeService = JokeService();
  List<Map<String, dynamic>> _jokesRaw = [];
  List<Map<String, dynamic>> _filteredJokes = [];
  bool _isLoading = false;
  bool _isOffline = false; // Flag for offline status
  String _selectedCategory = 'All'; // Default category filter

  @override
  void initState() {
    super.initState();
    _loadCachedJokes();
    _checkConnectivity(); // Check connectivity when the page loads
  }

  Future<void> _fetchJokes() async {
    if (_isOffline) {
      return; // Prevent fetching if the device is offline
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final jokes = await _jokeService.fetchJokesRaw();
      if (mounted) {
        setState(() {
          _jokesRaw = jokes.length >= 5 ? jokes.take(5).toList() : jokes;
          _filterJokes(); // Apply filter after fetching jokes
        });
        await _cacheJokes(_jokesRaw); // Cache the fetched jokes
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch jokes: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCachedJokes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jokesJson = prefs.getString('cached_jokes');

    if (jokesJson != null) {
      setState(() {
        _jokesRaw = List<Map<String, dynamic>>.from(json.decode(jokesJson));
        _filterJokes(); // Apply filter after loading cached jokes
      });
    }
  }

  Future<void> _cacheJokes(List<Map<String, dynamic>> jokes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jokesJson = json.encode(jokes);
    await prefs.setString('cached_jokes', jokesJson);
  }

  // Function to check connectivity
  Future<void> _checkConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
      });
    } else {
      setState(() {
        _isOffline = false;
      });
    }
  }

  // Function to handle liking a joke (simple toggle)
  void _likeJoke(int index) {
    setState(() {
      _filteredJokes[index]['liked'] =
          !_filteredJokes[index].containsKey('liked')
              ? true
              : !_filteredJokes[index]['liked'];
    });
  }

  // Function to handle deleting a joke
  void _deleteJoke(int index) {
    setState(() {
      _filteredJokes.removeAt(index);
    });
  }

  // Function to filter jokes by category
  void _filterJokes() {
    _filteredJokes = List.from(_jokesRaw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laugh Zone',
          style: TextStyle(color: Colors.white), // Set the title color to white
        ),
        backgroundColor: Color.fromARGB(255, 77, 1, 86), // Dark Green
        actions: [
          // Dropdown to select category filter
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedCategory = value;
                _filterJokes(); // Apply filter when category is selected
              });
            },
            itemBuilder: (BuildContext context) {
              return ['All', 'Single Joke', 'Funny', 'Puns']
                  .map((String category) {
                return PopupMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 64.0, 16.0, 16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment(0.8, 1),
            colors: <Color>[
              Color.fromARGB(255, 72, 3, 75),
              Color.fromARGB(255, 151, 4, 164),
              Color.fromARGB(255, 127, 54, 109),
              Color.fromARGB(255, 223, 129, 186),
            ],
            tileMode: TileMode.mirror,
          ),
        ),
        child: Column(
          children: [
            Center(
              child: Text(
                'Have fun!',
                style: TextStyle(
                  color: Colors.white, // Updated color to white
                  fontWeight: FontWeight.w900,
                  fontFamily: 'ComicSans',
                  fontSize: 40,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Icon(Icons.sentiment_very_satisfied,
                size: 50.0, color: const Color.fromARGB(255, 67, 2, 47)),
            const SizedBox(height: 16.0),
            Text(
              'Enjoy a collection of fun jokes to brighten your day.',
              style:
                  TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 28.0),
            _isOffline
                ? const Text(
                    'You are offline. Please check your internet connection.',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : ElevatedButton(
                    onPressed: _isLoading ? null : _fetchJokes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color.fromARGB(255, 47, 1, 38), // Green 400
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      elevation: 10,
                    ),
                    child: const Text(
                      'Get Jokes',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _filteredJokes.isEmpty
                        ? const Center(
                            child: Text(
                              'No jokes fetched yet.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black45,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredJokes.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final joke = _filteredJokes[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      joke['type'] == 'single'
                                          ? 'Single Joke'
                                          : joke['category'],
                                      style: TextStyle(
                                        color: Color.fromARGB(
                                            255, 191, 5, 198), // Dark Green
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      joke['type'] == 'single'
                                          ? joke['joke']
                                          : '${joke['setup']}\n\n${joke['delivery']}',
                                      style: const TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(height: 12.0),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            joke.containsKey('liked') &&
                                                    joke['liked']
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _likeJoke(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _deleteJoke(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
