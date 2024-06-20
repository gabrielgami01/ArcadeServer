import Vapor
import Fluent
import JWT

final class AppAPIKeyAuthenticator: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        guard let header = request.headers["App-APIKey"].first,
              header == "tokensito" else {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "users")
        
        let create = api.grouped(AppAPIKeyAuthenticator())
        create.post("create", use: createUser)
    }
    
    @Sendable func createUser(req: Request) async throws -> HTTPStatus {
        try User.validate(content: req)
        let user = try req.content.decode(User.self)
        let existingUser = try await User.query(on: req.db)
            .group(.or) { group in
                group
                    .filter(\.$username == user.username)
                    .filter(\.$email == user.email)
            }
            .first()
        guard existingUser == nil else { throw Abort(.badRequest, reason: "Error procesing request.") }
        
        user.password = try Bcrypt.hash("\(user.username)@\(user.password)")
        try await user.create(on: req.db)
        // Enviar email
        // try await EmailController.shared.sendEmail(req: req, to: user.email)
        return .created
    }
}
