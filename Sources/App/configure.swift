import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import JWT
import Queues
import QueuesRedisDriver


// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
//    app.logger.logLevel = .debug
    
    app.routes.defaultMaxBodySize = "10mb"
    
    app.databases.use(try .postgres(url: "postgres://arcadeuser:arcadbpass@localhost:55000/arcadedb"), as: .psql)

    app.migrations.add(EnumMigration())
    app.migrations.add(GameMigration())
    app.migrations.add(UserMigration())
    app.migrations.add(FavoriteGameMigration())
    app.migrations.add(ReviewMigration())
    app.migrations.add(ScoreMigration())
    app.migrations.add(ChallengeMigration())
    app.migrations.add(UserChallengeMigration())
    app.migrations.add(UserEmblemsMigration())
    app.migrations.add(UserConnectionsMigration())
    
    app.migrations.add(DataMigration())
    
    app.views.use(.leaf)

    try routes(app)
    
    let pool = RedisConfiguration.PoolOptions(maximumConnectionCount: .maximumActiveConnections(15),
                                              connectionRetryTimeout: .milliseconds(500))
    let redisConfig = try RedisConfiguration(url: "redis://127.0.0.1:6379", pool: pool)
    app.redis.configuration = redisConfig
    app.queues.use(.redis(redisConfig))
    
    app.queues.schedule(CheckChallengeJob())
        .minutely()
        .at(1)
    
    try app.queues.startScheduledJobs()
    
    let key = try SecurityManager().key
    app.jwt.signers.use(.hs256(key: key), kid: "symmetric", isDefault: true)
    app.jwt.apple.applicationIdentifier = "com.gabrielgarcia.Arcade"
}
