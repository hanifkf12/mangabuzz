import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../model/bookmark/bookmark_model.dart';
import '../../model/history/history_model.dart';

part 'moor_db_provider.g.dart';

class Bookmarks extends Table {
  TextColumn get title => text()();
  TextColumn get mangaEndpoint => text()();
  TextColumn get image => text()();
  TextColumn get author => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get rating => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get totalChapter => integer()();
  BoolColumn get isNew => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {title};
}

class Historys extends Table {
  TextColumn get title => text()();
  TextColumn get mangaEndpoint => text()();
  TextColumn get image => text()();
  TextColumn get author => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get rating => text().nullable()();
  IntColumn get chapterReached => integer().nullable()();
  IntColumn get selectedIndex => integer().nullable()();
  IntColumn get totalChapter => integer().nullable()();
  TextColumn get chapterReachedName => text().nullable()();

  @override
  Set<Column> get primaryKey => {title};
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file);
  });
}

//
// This connection only for testing
//
/*
LazyDatabase _testConnection() {
  return LazyDatabase(() async {
    return VmDatabase.memory();
  });
} */

@UseMoor(tables: [Bookmarks, Historys], daos: [BookmarkDao, HistoryDao])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (Migrator m) {
        return m.createAll();
      }, onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          // we added the dueDate property in the change from version 1
          await m.addColumn(historys, historys.chapterReachedName);
        }
      });
}

//
// DAOs, This is the repo for the database
//

@UseDao(tables: [Bookmarks])
class BookmarkDao extends DatabaseAccessor<MyDatabase> with _$BookmarkDaoMixin {
  final MyDatabase db;

  BookmarkDao(this.db) : super(db);

  //
  // Bookmark Table
  //

  // Get bookmarks table length
  Future<int> getBookmarkLength() async {
    try {
      //Create expression of count
      var countExp = bookmarks.title.count();

      //Moor creates query from Expression so, they don't have value unless you execute it as query.
      //Following query will execute experssion on Table.
      final query = selectOnly(bookmarks)..addColumns([countExp]);
      int result = await query.map((row) => row.read(countExp)).getSingle();

      return result;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get all data from bookmarks table
  Future<List<BookmarkModel>> listAllBookmark() {
    try {
      return (select(bookmarks)).map((rows) {
        return BookmarkModel(
            title: rows.title,
            mangaEndpoint: rows.mangaEndpoint,
            image: rows.image,
            author: rows.author,
            type: rows.type,
            rating: rows.rating,
            description: rows.description,
            totalChapter: rows.totalChapter,
            isNew: rows.isNew);
      }).get();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Emit elements when the watched data changes
  Stream<List<BookmarkModel>> watchAllBookmark() {
    try {
      return select(bookmarks).watch().map((rows) {
        return rows.map((e) {
          return BookmarkModel(
              title: e.title,
              mangaEndpoint: e.mangaEndpoint,
              image: e.image,
              author: e.author,
              type: e.type,
              rating: e.rating,
              description: e.description,
              totalChapter: e.totalChapter,
              isNew: e.isNew);
        }).toList();
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Insert operation
  Future<int> insertBookmark(Bookmark bookmark) {
    try {
      return into(bookmarks).insert(bookmark);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Update operation
  Future updateBookmark(Bookmark bookmark) {
    try {
      return update(bookmarks).replace(bookmark);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Delete operation
  Future<int> deleteBookmark(String title, String mangaEndpoint) {
    try {
      return (delete(bookmarks)
            ..where((tbl) =>
                tbl.title.equals(title) &
                tbl.mangaEndpoint.equals(mangaEndpoint)))
          .go();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get bookmark data by title & mangaEndpoint
  Future<BookmarkModel> getBookmark(String title, String mangaEndpoint) {
    try {
      final query = (select(bookmarks)
        ..where((t) =>
            t.title.equals(title) & t.mangaEndpoint.equals(mangaEndpoint)));

      return query.map((rows) {
        return BookmarkModel(
            title: rows.title,
            mangaEndpoint: rows.mangaEndpoint,
            image: rows.image,
            author: rows.author,
            type: rows.type,
            rating: rows.rating,
            description: rows.description,
            totalChapter: rows.totalChapter,
            isNew: rows.isNew);
      }).getSingle();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Search Operation
  Future<List<BookmarkModel>> searchBookmarkByQuery(String query) {
    try {
      return (select(bookmarks)..where((tbl) => tbl.title.contains(query)))
          .map((rows) {
        return BookmarkModel(
            title: rows.title,
            mangaEndpoint: rows.mangaEndpoint,
            image: rows.image,
            author: rows.author,
            type: rows.type,
            rating: rows.rating,
            description: rows.description,
            totalChapter: rows.totalChapter,
            isNew: rows.isNew);
      }).get();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

@UseDao(tables: [Historys])
class HistoryDao extends DatabaseAccessor<MyDatabase> with _$HistoryDaoMixin {
  final MyDatabase db;

  HistoryDao(this.db) : super(db);

  //
  // History Table
  //

  // Get all data from bookmarks table
  Future<List<HistoryModel>> listAllHistory() {
    try {
      return (select(historys)).map((rows) {
        return HistoryModel(
            title: rows.title,
            mangaEndpoint: rows.mangaEndpoint,
            image: rows.image,
            author: rows.author,
            type: rows.type,
            rating: rows.rating,
            chapterReached: rows.chapterReached,
            selectedIndex: rows.selectedIndex,
            totalChapter: rows.totalChapter,
            chapterReachedName: rows.chapterReachedName);
      }).get();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Emit elements when the watched data changes
  Stream<List<HistoryModel>> watchAllHistory() {
    try {
      return select(historys).watch().map((rows) {
        return rows.map((e) {
          return HistoryModel(
              title: e.title,
              mangaEndpoint: e.mangaEndpoint,
              image: e.image,
              author: e.author,
              type: e.type,
              rating: e.rating,
              chapterReached: e.chapterReached,
              selectedIndex: e.selectedIndex,
              totalChapter: e.totalChapter,
              chapterReachedName: e.chapterReachedName);
        }).toList();
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Insert operation
  Future insertHistory(History history) {
    try {
      return into(historys).insert(history);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Update operation
  Future updateHistory(History history) {
    try {
      return update(historys).replace(history);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Delete operation
  Future deleteHistory(String title, String mangaEndpoint) {
    try {
      return (delete(historys)
            ..where((tbl) =>
                tbl.title.equals(title) &
                tbl.mangaEndpoint.equals(mangaEndpoint)))
          .go();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get history data by title & mangaEndpoint
  Future<HistoryModel> getHistory(String title, String mangaEndpoint) {
    try {
      final query = (select(historys)
        ..where((t) =>
            t.title.equals(title) & t.mangaEndpoint.equals(mangaEndpoint)));

      return query.map((rows) {
        return HistoryModel(
            title: rows.title,
            mangaEndpoint: rows.mangaEndpoint,
            image: rows.image,
            author: rows.author,
            type: rows.type,
            rating: rows.rating,
            chapterReached: rows.chapterReached,
            selectedIndex: rows.selectedIndex,
            totalChapter: rows.totalChapter,
            chapterReachedName: rows.chapterReachedName);
      }).getSingle();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Search Operation
  Future<List<HistoryModel>> searchHistoryByQuery(String query) {
    try {
      return (select(historys)..where((tbl) => tbl.title.contains(query)))
          .map((rows) {
        return HistoryModel(
            title: rows.title,
            mangaEndpoint: rows.mangaEndpoint,
            image: rows.image,
            author: rows.author,
            type: rows.type,
            rating: rows.rating,
            chapterReached: rows.chapterReached,
            selectedIndex: rows.selectedIndex,
            totalChapter: rows.totalChapter,
            chapterReachedName: rows.chapterReachedName);
      }).get();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
