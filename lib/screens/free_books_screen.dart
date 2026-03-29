import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/free_books_service.dart';
import '../storage/book_storage.dart';
import 'pdf_screen.dart';

class FreeBooksScreen extends StatefulWidget {
  const FreeBooksScreen({super.key});

  @override
  State<FreeBooksScreen> createState() => _FreeBooksScreenState();
}

class _FreeBooksScreenState extends State<FreeBooksScreen> {
  List<Map<String, dynamic>> serverBooks = [];
  bool loading = true;
  Set<String> downloadedIds = {};
  Set<String> downloadingIds = {};
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final data = await FreeBooksService.fetchBooks();
    final saved = await BookStorage.load();

    if (!mounted) return;

    setState(() {
      serverBooks = data;
      downloadedIds = saved.map((b) => b.id).toSet();
      loading = false;
    });
  }

  /// Groups filtered books by category
  Map<String, List<Map<String, dynamic>>> get _groupedBooks {
    final filtered = searchQuery.isEmpty
        ? serverBooks
        : serverBooks.where((b) {
      final title = (b['title'] ?? '').toString().toLowerCase();
      final cat = (b['category'] ?? '').toString().toLowerCase();
      return title.contains(searchQuery.toLowerCase()) ||
          cat.contains(searchQuery.toLowerCase());
    }).toList();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final book in filtered) {
      final cat = book['category'] ?? 'General';
      grouped.putIfAbsent(cat, () => []).add(book);
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Future<void> _openBook(Map<String, dynamic> data) async {
    final id = data['id'];

    setState(() => downloadingIds.add(id));

    try {
      final Book downloaded = await FreeBooksService.downloadBook(data);

      final books = await BookStorage.load();
      final exists = books.any((b) => b.id == downloaded.id);

      if (!exists) {
        books.add(downloaded);
        await BookStorage.save(books);
      }

      final freshBooks = await BookStorage.load();
      final book = freshBooks.firstWhere((b) => b.id == downloaded.id);

      if (!mounted) return;

      setState(() {
        downloadingIds.remove(id);
        downloadedIds.add(id);
      });

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfScreen(book: book)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => downloadingIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open book')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedBooks;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        title: const Text(
          'Free Books',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF3E2723)),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          /// 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              style: const TextStyle(color: Color(0xFF3E2723)),
              decoration: InputDecoration(
                hintText: 'Search books or categories...',
                hintStyle:
                TextStyle(color: Colors.brown.shade300, fontSize: 14),
                prefixIcon:
                const Icon(Icons.search, color: Color(0xFF8B4513)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// 📚 BOOK LIST
          Expanded(
            child: grouped.isEmpty
                ? const Center(
              child: Text(
                'No books found',
                style: TextStyle(color: Color(0xFF8B4513)),
              ),
            )
                : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: grouped.entries.map((entry) {
                final category = entry.key;
                final categoryBooks = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// CATEGORY HEADER
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B4513),
                              borderRadius:
                              BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${categoryBooks.length} books',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// HORIZONTAL BOOK CARDS
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16),
                        itemCount: categoryBooks.length,
                        itemBuilder: (_, i) {
                          final book = categoryBooks[i];
                          final id = book['id'] ?? '';
                          final title =
                              book['title'] ?? 'Untitled';
                          final isDownloaded =
                          downloadedIds.contains(id);
                          final isDownloading =
                          downloadingIds.contains(id);

                          return GestureDetector(
                            onTap: () => _openBook(book),
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(
                                  right: 12, bottom: 4),
                              decoration: BoxDecoration(
                                borderRadius:
                                BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF8B4513),
                                    Color(0xFFB87333),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.brown
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  /// CONTENT
                                  Padding(
                                    padding:
                                    const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        /// BOOK INITIAL
                                        Container(
                                          height: 56,
                                          width: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withOpacity(0.15),
                                            borderRadius:
                                            BorderRadius
                                                .circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              title[0].toUpperCase(),
                                              style:
                                              const TextStyle(
                                                fontSize: 28,
                                                color: Colors.white,
                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const Spacer(),

                                        /// TITLE
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        /// DOWNLOAD BUTTON / STATUS
                                        SizedBox(
                                          width: double.infinity,
                                          child: isDownloading
                                              ? const Center(
                                            child: SizedBox(
                                              height: 20,
                                              width: 20,
                                              child:
                                              CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors
                                                    .white,
                                              ),
                                            ),
                                          )
                                              : Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                vertical: 5),
                                            decoration:
                                            BoxDecoration(
                                              color: isDownloaded
                                                  ? Colors
                                                  .white
                                                  .withOpacity(
                                                  0.25)
                                                  : Colors
                                                  .white,
                                              borderRadius:
                                              BorderRadius
                                                  .circular(
                                                  10),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                              children: [
                                                Icon(
                                                  isDownloaded
                                                      ? Icons
                                                      .check_rounded
                                                      : Icons
                                                      .download_rounded,
                                                  size: 14,
                                                  color: isDownloaded
                                                      ? Colors
                                                      .white
                                                      : const Color(
                                                      0xFF8B4513),
                                                ),
                                                const SizedBox(
                                                    width: 4),
                                                Text(
                                                  isDownloaded
                                                      ? 'Open'
                                                      : 'Download',
                                                  style:
                                                  TextStyle(
                                                    fontSize:
                                                    11,
                                                    fontWeight:
                                                    FontWeight
                                                        .bold,
                                                    color: isDownloaded
                                                        ? Colors
                                                        .white
                                                        : const Color(
                                                        0xFF8B4513),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
          ),
        ],
      ),
    );
  }
}