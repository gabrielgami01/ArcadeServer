import Vapor
import Fluent

struct GenreController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "genres")
        let jwtSecure = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        
        jwtSecure.get(use: getAllGenres)
    }
    
    @Sendable func getAllGenres(req: Request) async throws -> [Genre] {
        try await Genre
            .query(on: req.db)
            .all()
    }

}
