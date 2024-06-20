import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.databases.use(try .postgres(url: "postgres://arcadeuser:arcadbpass@localhost:55000/arcadedb"), as: .psql)

    app.migrations.add(ConsoleMigration())
    app.migrations.add(GenreMigration())
    app.migrations.add(GameMigration())
    app.migrations.add(MaestrosMigration())

    app.views.use(.leaf)

    try routes(app)
}
