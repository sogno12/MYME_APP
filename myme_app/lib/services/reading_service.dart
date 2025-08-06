import '../models/book.dart';
import '../models/reading_session.dart';

class ReadingService {
  static final ReadingService _instance = ReadingService._internal();
  factory ReadingService() => _instance;
  ReadingService._internal();

  final List<Book> _books = [];
  final List<ReadingSession> _sessions = [];

  List<Book> get books => List.unmodifiable(_books);
  List<ReadingSession> get sessions => List.unmodifiable(_sessions);

  void addBook(Book book) {
    _books.add(book);
  }

  void updateBook(Book updatedBook) {
    final index = _books.indexWhere((book) => book.id == updatedBook.id);
    if (index != -1) {
      _books[index] = updatedBook;
    }
  }

  void deleteBook(String bookId) {
    _books.removeWhere((book) => book.id == bookId);
    _sessions.removeWhere((session) => session.bookId == bookId);
  }

  Book? getBook(String bookId) {
    try {
      return _books.firstWhere((book) => book.id == bookId);
    } catch (e) {
      return null;
    }
  }

  void addReadingSession(ReadingSession session) {
    _sessions.add(session);
    
    final book = getBook(session.bookId);
    if (book != null) {
      final updatedBook = book.copyWith(
        currentPage: session.endPage,
        status: session.endPage >= book.totalPages 
            ? ReadingStatus.completed 
            : ReadingStatus.reading,
        calculatedEndDate: session.endPage >= book.totalPages 
            ? session.readingDate 
            : null,
        calculatedStartDate: book.calculatedStartDate ?? session.readingDate,
      );
      updateBook(updatedBook);
    }
  }

  List<ReadingSession> getSessionsForBook(String bookId) {
    return _sessions.where((session) => session.bookId == bookId).toList()
      ..sort((a, b) => b.readingDate.compareTo(a.readingDate));
  }

  int getLastPageForBook(String bookId) {
    final sessions = getSessionsForBook(bookId);
    if (sessions.isEmpty) return 0;
    return sessions.first.endPage;
  }

  int calculatePagesRead(String bookId, int newEndPage) {
    final lastPage = getLastPageForBook(bookId);
    return newEndPage - lastPage;
  }

  void updateReadingSession(ReadingSession updatedSession) {
    final index = _sessions.indexWhere((session) => session.id == updatedSession.id);
    if (index != -1) {
      _sessions[index] = updatedSession;
      _recalculateBookProgress(updatedSession.bookId);
    }
  }

  void deleteReadingSession(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    final bookId = session.bookId;
    _sessions.removeWhere((session) => session.id == sessionId);
    _recalculateBookProgress(bookId);
  }

  void _recalculateBookProgress(String bookId) {
    final book = getBook(bookId);
    if (book == null) return;

    final sessions = getSessionsForBook(bookId);
    
    if (sessions.isEmpty) {
      final updatedBook = book.copyWith(
        currentPage: 0,
        status: ReadingStatus.toRead,
        calculatedStartDate: null,
        calculatedEndDate: null,
      );
      updateBook(updatedBook);
    } else {
      sessions.sort((a, b) => a.readingDate.compareTo(b.readingDate));
      final latestSession = sessions.last;
      final earliestSession = sessions.first;
      
      final updatedBook = book.copyWith(
        currentPage: latestSession.endPage,
        calculatedStartDate: earliestSession.readingDate,
        status: latestSession.endPage >= book.totalPages 
            ? ReadingStatus.completed 
            : ReadingStatus.reading,
        calculatedEndDate: latestSession.endPage >= book.totalPages 
            ? latestSession.readingDate 
            : null,
      );
      updateBook(updatedBook);
    }
  }
}