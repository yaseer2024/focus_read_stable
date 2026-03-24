import 'package:flutter/material.dart';

import '../models/book.dart';
import '../storage/book_storage.dart';
import 'pdf_screen.dart';
import 'free_books_screen.dart';
import 'upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final loaded = await BookStorage.load();
    setState(() {
      books = loaded;
      isLoading = false;
    });
  }

  /// 🎬 GROUP BOOKS BY CATEGORY (SAFE)
  Map<String, List<Book>> groupBooks(List<Book> books) {
    final Map<String, List<Book>> grouped = {};

    for (var book in books) {
      final category =
      (book.category.isEmpty) ? "General" : book.category;

      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(book);
    }

    return grouped;
  }

  Future<void> _deleteBook(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete book'),
        content: Text('Delete "${book.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await BookStorage.removeBook(book.id);
      await _loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedBooks = groupBooks(books);

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),

      /// 🔝 APPBAR
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        title: const Text(
          'Focus Read',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
        actions: [
          /// 🌍 FREE BOOKS
          IconButton(
            icon: const Icon(Icons.public, color: Color(0xFF3E2723)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FreeBooksScreen(),
                ),
              );
              await _loadBooks();
            },
          ),
        ],
      ),

      /// 📚 BODY
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
          ? const Center(
        child: Text(
          "No books yet 📚\nTap + to add",
          textAlign: TextAlign.center,
        ),
      )
          : ListView(
        children: groupedBooks.entries.map((entry) {
          final category = entry.key;
          final categoryBooks = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 📌 CATEGORY TITLE
              Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723),
                  ),
                ),
              ),

              /// 🎬 HORIZONTAL LIST (NETFLIX STYLE)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryBooks.length,
                  itemBuilder: (_, i) {
                    final book = categoryBooks[i];
                    final progress =
                    book.progress.clamp(0.0, 1.0);

                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PdfScreen(book: book),
                          ),
                        );
                        await _loadBooks();
                      },
                      onLongPress: () => _deleteBook(book),

                      child: Container(
                        width: 140,
                        margin:
                        const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(16),
                          gradient:
                          const LinearGradient(
                            colors: [
                              Color(0xFF8B4513),
                              Color(0xFFB87333),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            /// 📘 COVER
                            Expanded(
                              child: Center(
                                child: Text(
                                  book.title[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            /// 📄 TITLE
                            Padding(
                              padding:
                              const EdgeInsets.all(8),
                              child: Text(
                                book.title,
                                maxLines: 2,
                                overflow:
                                TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            /// 📊 PROGRESS BAR
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                              Colors.black26,
                              color:
                              const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),

      /// ➕ UPLOAD BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B4513),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UploadScreen(),
            ),
          );
          await _loadBooks();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}