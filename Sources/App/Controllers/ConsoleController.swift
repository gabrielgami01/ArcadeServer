import Vapor
import Fluent

struct ConsoleController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "consoles")
        let jwtSecure = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        
        jwtSecure.get(use: getAllConsoles)
    }
    
    @Sendable func getAllConsoles(req: Request) async throws -> [Console] {
        try await Console
            .query(on: req.db)
            .all()
    }
}
