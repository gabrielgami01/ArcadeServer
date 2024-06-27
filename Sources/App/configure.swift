import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.databases.use(try .postgres(url: "postgres://arcadeuser:arcadbpass@localhost:55000/arcadedb"), as: .psql)

    app.migrations.add(MastersMigration())
    app.migrations.add(GameMigration())
    app.migrations.add(DataMigration())
    app.migrations.add(UserMigration())

    app.views.use(.leaf)

    try routes(app)
    
    let key = try SecurityManager().key
    app.jwt.signers.use(.hs256(key: key), kid: "symmetric", isDefault: true)
    app.jwt.apple.applicationIdentifier = "com.gabrielgarcia.Arcade"
}
