import Vapor
import Fluent

struct MastersController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        let consoles = api.grouped("consoles")
        let jwtSecureConsoles = consoles.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        jwtSecureConsoles.get(use: getAllConsoles)

        let genres = api.grouped("genres")
        let jwtSecureGenres = genres.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        jwtSecureGenres.get(use: getAllGenres)
    }
    
    @Sendable func getAllConsoles(req: Request) async throws -> [Console] {
        try await Console
            .query(on: req.db)
            .all()
    }
    
    @Sendable func getAllGenres(req: Request) async throws -> [Genre] {
        try await Genre
            .query(on: req.db)
            .all()
    }
}

