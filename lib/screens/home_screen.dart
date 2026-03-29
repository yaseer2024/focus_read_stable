import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/book.dart';
import '../storage/book_storage.dart';
import '../storage/reading_time_storage.dart';
import 'pdf_screen.dart';
import 'free_books_screen.dart';
import 'upload_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static free book previews shown in the shelf strip
// ─────────────────────────────────────────────────────────────────────────────
class _FreeBookPreview {
  final String title;
  final String author;
  final Color color;
  final Color textColor;

  const _FreeBookPreview({
    required this.title,
    required this.author,
    required this.color,
    required this.textColor,
  });
}

const List<_FreeBookPreview> _kFreeBookPreviews = [
  _FreeBookPreview(
    title: 'Moby Dick',
    author: 'Herman Melville',
    color: Color(0xFF1E3A5F),
    textColor: Color(0xFF7EB8F7),
  ),
  _FreeBookPreview(
    title: 'Dracula',
    author: 'Bram Stoker',
    color: Color(0xFF3D1A1A),
    textColor: Color(0xFFF5A0A0),
  ),
  _FreeBookPreview(
    title: 'Pride & Prejudice',
    author: 'Jane Austen',
    color: Color(0xFF1B3A2D),
    textColor: Color(0xFF7ECAAA),
  ),
  _FreeBookPreview(
    title: 'Frankenstein',
    author: 'Mary Shelley',
    color: Color(0xFF2D1B4E),
    textColor: Color(0xFFB09FEC),
  ),
  _FreeBookPreview(
    title: 'War & Peace',
    author: 'Leo Tolstoy',
    color: Color(0xFF2E2A10),
    textColor: Color(0xFFD4B86A),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Book> books = [];
  bool isLoading = true;

  static const int dailyGoalMinutes = 20;
  int readTodayMinutes = 0;
  bool _goalCelebrated = false;

  late AnimationController _confettiController;
  List<_ConfettiParticle> _particles = [];

  int globalStreak = 0;
  bool streakAtRisk = false;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _confettiController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _particles = []);
      }
    });

    _loadBooks();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    final loaded = await BookStorage.load();

    int totalToday = 0;
    for (final b in loaded) {
      final t = await ReadingTimeStorage.getTodayMinutes(b.id);
      totalToday += t;
    }

    int maxStreak = 0;
    for (final b in loaded) {
      if (b.streak > maxStreak) maxStreak = b.streak;
    }

    final today = DateTime.now();
    bool atRisk = false;

    for (final b in loaded) {
      if (b.streak > 0 && b.lastReadDate != null) {
        final last = DateTime.tryParse(b.lastReadDate!);
        if (last != null) {
          final diff = today.difference(last).inDays;
          if (diff >= 1) atRisk = true;
        }
      }
    }

    setState(() {
      books = loaded;
      readTodayMinutes = totalToday;
      globalStreak = maxStreak;
      streakAtRisk = atRisk;
      isLoading = false;
    });

    _checkGoal();
  }

  void _checkGoal() {
    if (readTodayMinutes >= dailyGoalMinutes && !_goalCelebrated) {
      _goalCelebrated = true;
      _launchConfetti();
    }
  }

  void _launchConfetti() {
    final colors = [
      Colors.amber,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.red,
    ];

    final particles = List.generate(60, (i) {
      return _ConfettiParticle(
        color: colors[i % colors.length],
        x: 0.1 + (i % 10) * 0.08,
        delay: i * 0.015,
        size: 6.0 + (i % 4) * 2,
      );
    });

    setState(() => _particles = particles);
    _confettiController.forward(from: 0);
  }

  Map<String, List<Book>> _groupBooks(List<Book> books) {
    final Map<String, List<Book>> grouped = {};
    for (var book in books) {
      String category = book.category.trim();
      if (category.isEmpty) category = 'General';
      category = category.toLowerCase();
      category = category[0].toUpperCase() + category.substring(1);
      grouped.putIfAbsent(category, () => []).add(book);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Future<void> _deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2235),
        title: const Text('Remove Book',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${book.title}" from your library?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await BookStorage.removeBook(book.id);
      await _loadBooks();
    }
  }

  void _openFreeBooks() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FreeBooksScreen()),
    );
    await _loadBooks();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _progressLabel() {
    if (readTodayMinutes >= dailyGoalMinutes) return 'Daily goal reached! 🎉';
    final remaining = dailyGoalMinutes - readTodayMinutes;
    return '$remaining min left to reach your goal';
  }

  Color _bookColor(String title) {
    final colors = [
      const Color(0xFF1E3A5F),
      const Color(0xFF2D1B4E),
      const Color(0xFF1B3A2D),
      const Color(0xFF3D1A1A),
      const Color(0xFF1A3040),
      const Color(0xFF2E2A10),
    ];
    return colors[title.length % colors.length];
  }

  IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('sci') || c.contains('tech'))
      return Icons.science_outlined;
    if (c.contains('hist')) return Icons.account_balance_outlined;
    if (c.contains('fiction') || c.contains('novel'))
      return Icons.auto_stories_outlined;
    if (c.contains('self') || c.contains('personal'))
      return Icons.self_improvement_outlined;
    if (c.contains('business') || c.contains('finance'))
      return Icons.trending_up_outlined;
    if (c.contains('health') || c.contains('med'))
      return Icons.health_and_safety_outlined;
    return Icons.menu_book_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final groupedBooks = _groupBooks(books);
    final goalProgress =
    (readTodayMinutes / dailyGoalMinutes).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      floatingActionButton: _buildFAB(),
      body: Stack(
        children: [
          SafeArea(
            child: isLoading
                ? const Center(
                child:
                CircularProgressIndicator(color: Colors.amber))
                : CustomScrollView(
              slivers: [
                // ── HEADER ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Focus Read',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Streak badge
                        AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 400),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: globalStreak == 0
                                ? Colors.grey[850]
                                : streakAtRisk
                                ? Colors.red[900]
                                : Colors.orange[800],
                            borderRadius:
                            BorderRadius.circular(20),
                            boxShadow: globalStreak > 0
                                ? [
                              BoxShadow(
                                color: Colors.orange
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              )
                            ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥',
                                  style: TextStyle(fontSize: 15)),
                              const SizedBox(width: 4),
                              Text(
                                '$globalStreak day${globalStreak != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── DAILY GOAL CARD ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141E30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Today's Reading",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$readTodayMinutes / $dailyGoalMinutes min',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: goalProgress,
                              backgroundColor: Colors.white12,
                              color: goalProgress >= 1.0
                                  ? Colors.greenAccent
                                  : Colors.amber,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _progressLabel(),
                            style: TextStyle(
                              color: goalProgress >= 1.0
                                  ? Colors.greenAccent
                                  : Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── MY LIBRARY (or inline empty state) ──────────────
                if (books.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildInlineEmptyState(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, index) {
                        final entry = groupedBooks.entries
                            .elementAt(index);
                        final category = entry.key;
                        final list = entry.value;

                        return Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            // Category header
                            Padding(
                              padding:
                              const EdgeInsets.fromLTRB(
                                  20, 8, 20, 12),
                              child: Row(
                                children: [
                                  Icon(
                                    _categoryIcon(category),
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight:
                                      FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 8,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius:
                                      BorderRadius.circular(
                                          10),
                                    ),
                                    child: Text(
                                      '${list.length}',
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Book cards row
                            SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(
                                    left: 16, right: 8),
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final book = list[i];
                                  return _BookCard(
                                    book: book,
                                    cardColor:
                                    _bookColor(book.title),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PdfScreen(
                                                  book: book),
                                        ),
                                      );
                                      await _loadBooks();
                                    },
                                    onDelete: () =>
                                        _deleteBook(book),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
                        );
                      },
                      childCount: groupedBooks.length,
                    ),
                  ),

                // ── FREE BOOKS SHELF STRIP ───────────────────────────
                SliverToBoxAdapter(
                  child: _buildFreeBookStrip(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),

          // ── CONFETTI OVERLAY ─────────────────────────────────────────────
          if (_particles.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                        particles: _particles,
                        progress: _confettiController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── INLINE EMPTY STATE ─────────────────────────────────────────────────────
  Widget _buildInlineEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF141E30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.menu_book_outlined,
                color: Colors.grey[700], size: 48),
            const SizedBox(height: 12),
            const Text(
              'Your library is empty',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload a PDF you own, or start with a free classic below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── FREE BOOKS SHELF STRIP ─────────────────────────────────────────────────
  Widget _buildFreeBookStrip() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Free Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _openFreeBooks,
                  child: Row(
                    children: const [
                      Text(
                        'See all',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.amber, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Book cover previews + "See all" card
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 8),
              // +1 for the trailing "Explore all" card
              itemCount: _kFreeBookPreviews.length + 1,
              itemBuilder: (_, i) {
                if (i == _kFreeBookPreviews.length) {
                  return _buildExploreAllCard();
                }
                return _FreeBookPreviewCard(
                  preview: _kFreeBookPreviews[i],
                  onTap: _openFreeBooks,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreAllCard() {
    return GestureDetector(
      onTap: _openFreeBooks,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF141E30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.explore_outlined, color: Colors.amber, size: 28),
            SizedBox(height: 10),
            Text(
              'Explore\nall books',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      backgroundColor: Colors.amber,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: const Text('Add Book',
          style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadScreen()),
        );
        await _loadBooks();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FREE BOOK PREVIEW CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FreeBookPreviewCard extends StatelessWidget {
  final _FreeBookPreview preview;
  final VoidCallback onTap;

  const _FreeBookPreviewCard({
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10, bottom: 4),
        decoration: BoxDecoration(
          color: preview.color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Texture
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(painter: _BookTexturePainter()),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spine accent bar
                  Container(
                    width: 3,
                    height: 32,
                    decoration: BoxDecoration(
                      color: preview.textColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    preview.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  Text(
                    preview.author,
                    style: TextStyle(
                      color: preview.textColor,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Free',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOK CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final Book book;
  final Color cardColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.cardColor,
    required this.onTap,
    required this.onDelete,
  });

  double get _readProgress => book.progress.clamp(0.0, 1.0);

  String get _progressText {
    if (book.totalPages <= 0) return 'Not started';
    final pct = (_readProgress * 100).round();
    if (pct == 0) return 'Not started';
    if (pct >= 100) return 'Completed ✓';
    return 'Page ${book.lastPage + 1} of ${book.totalPages}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Texture
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(painter: _BookTexturePainter()),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white60,
                      size: 22,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _readProgress,
                      backgroundColor: Colors.white12,
                      color: _readProgress >= 1.0
                          ? Colors.greenAccent
                          : Colors.amber,
                      minHeight: 4,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _progressText,
                    style: TextStyle(
                      color: _readProgress >= 1.0
                          ? Colors.greenAccent
                          : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Streak badge
            if (book.streak > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔥${book.streak}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED TEXTURE PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _BookTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width; i += 16) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BookTexturePainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFETTI
// ─────────────────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final Color color;
  final double x;
  final double delay;
  final double size;

  const _ConfettiParticle({
    required this.color,
    required this.x,
    required this.delay,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  const _ConfettiPainter(
      {required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t =
      ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = p.x * size.width;
      final y = t * size.height;

      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress;
}