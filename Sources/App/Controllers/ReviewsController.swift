import Vapor
import Fluent

struct ReviewsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "reviews")
    
        let reviews = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        reviews.get(":gameID", use: getGameReviews)
        reviews.post(use: addReview)
    }
    
    
    @Sendable func getGameReviews(req: Request) async throws -> [Review.Response] {
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
                      
        let reviews = try await game.$reviews
            .query(on: req.db)
            .with(\.$user)
            .sort(\.$createdAt, .descending)
            .all()
        
        return try Review.toResponse(reviews)
    }
    
    @Sendable func addReview(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        let reviewDTO = try req.content.decode(CreateReviewDTO.self)
        guard let game = try await Game.find(reviewDTO.gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        let existingReview = try await user.$reviews
            .query(on: req.db)
            .filter(\.$game.$id == game.requireID())
            .first()
        
        if let _ = existingReview {
            throw Abort(.conflict, reason: "Already have a review for this game")
        } else {
            let review = try Review(title: reviewDTO.title, comment: reviewDTO.comment, rating: reviewDTO.rating, game: game.requireID(), user: user.requireID())
            try await review.create(on: req.db)
            return .created
        }
    }
    

}
