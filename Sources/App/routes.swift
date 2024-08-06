import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UsersController())
    try app.register(collection: GamesController())
    try app.register(collection: ReviewsController())
    try app.register(collection: ScoresController())
    try app.register(collection: ChallengesController())
}
