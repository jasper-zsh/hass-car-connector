// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  RemoteConfigRepository? _remoteConfigRepositoryInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `RemoteConfig` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `type` TEXT NOT NULL, `config` TEXT NOT NULL, `enabled` INTEGER NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  RemoteConfigRepository get remoteConfigRepository {
    return _remoteConfigRepositoryInstance ??=
        _$RemoteConfigRepository(database, changeListener);
  }
}

class _$RemoteConfigRepository extends RemoteConfigRepository {
  _$RemoteConfigRepository(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _remoteConfigInsertionAdapter = InsertionAdapter(
            database,
            'RemoteConfig',
            (RemoteConfig item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'type': item.type,
                  'config': item.config,
                  'enabled': item.enabled ? 1 : 0
                }),
        _remoteConfigUpdateAdapter = UpdateAdapter(
            database,
            'RemoteConfig',
            ['id'],
            (RemoteConfig item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'type': item.type,
                  'config': item.config,
                  'enabled': item.enabled ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<RemoteConfig> _remoteConfigInsertionAdapter;

  final UpdateAdapter<RemoteConfig> _remoteConfigUpdateAdapter;

  @override
  Future<List<RemoteConfig>> findAll() async {
    return _queryAdapter.queryList('SELECT * FROM RemoteConfig',
        mapper: (Map<String, Object?> row) => RemoteConfig(
            name: row['name'] as String,
            type: row['type'] as String,
            config: row['config'] as String,
            enabled: (row['enabled'] as int) != 0));
  }

  @override
  Future<List<RemoteConfig>> findEnabled() async {
    return _queryAdapter.queryList(
        'SELECT * FROM RemoteConfig WHERE enabled = true',
        mapper: (Map<String, Object?> row) => RemoteConfig(
            name: row['name'] as String,
            type: row['type'] as String,
            config: row['config'] as String,
            enabled: (row['enabled'] as int) != 0));
  }

  @override
  Future<int> insertRemoteConfig(RemoteConfig remoteConfig) {
    return _remoteConfigInsertionAdapter.insertAndReturnId(
        remoteConfig, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateRemoteConfig(RemoteConfig remoteConfig) async {
    await _remoteConfigUpdateAdapter.update(
        remoteConfig, OnConflictStrategy.abort);
  }
}
