import Vapor
import Fluent

struct ReviewsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "reviews")
    
        let reviews = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        reviews.get("listByGame", ":gameID", use: getGameReviews)
        reviews.post("add", use: addReview)
    }
    
    @Sendable func getGameReviews(req: Request) async throws -> [Review.Response] {
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        let reviews = try await game.$usersReviews
            .$pivots
            .query(on: req.db)
            .with(\.$user)
            .sort(\.$createdAt, .descending)
            .all()
        
        return try Review.toResponse(reviews: reviews)
    }
    
    @Sendable func addReview(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        let reviewDTO = try req.content.decode(CreateReviewDTO.self)
        guard let game = try await Game.find(reviewDTO.gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
                
        try await user.$gamesReviews.attach(game, method: .ifNotExists, on: req.db) { pivot in
            pivot.title = reviewDTO.title
            pivot.rating = reviewDTO.rating
            if let comment = reviewDTO.comment {
                pivot.comment = comment
            }
        }
        return .created
    }
}
