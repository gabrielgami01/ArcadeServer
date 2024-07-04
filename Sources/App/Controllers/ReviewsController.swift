import Vapor
import Fluent

struct ReviewsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "reviews")
        let reviews = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        
        reviews.group("") { review in
            review.post(use: addReview)
        }
        reviews.get(":gameID", use: getGameReviews)
        
    }
    
    @Sendable func getGameReviews(req: Request) async throws -> [Review.ReviewResponse] {
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        let reviews = try await game.$usersReviews
            .$pivots
            .query(on: req.db)
            .with(\.$user)
            .all()
        
        return try Review.toReviewResponse(reviews: reviews)
    }
    
    @Sendable func addReview(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        let reviewDTO = try req.content.decode(CreateReviewDTO.self)
        
        guard let game = try await Game.find(reviewDTO.gameID, on: req.db),
              let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
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
