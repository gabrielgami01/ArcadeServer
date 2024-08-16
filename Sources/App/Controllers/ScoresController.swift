import Fluent
import Vapor
import NIO

struct ScoresController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "scores")
        let scores = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        
        scores.post(use: addScore)
        scores.get(":gameID", use: getGameScores)
    }
    
    @Sendable func addScore(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        let scoreDTO = try req.content.decode(CreateScoreDTO.self)
        
        guard let game = try await Game.find(scoreDTO.gameID, on: req.db),
              let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
                
        try await user.$gamesScores.attach(game, method: .always, on: req.db)
        
        let scoreID = try await user.$gamesScores
            .$pivots
            .query(on: req.db)
            .sort(.createdAt)
            .first()?
            .id
        
        let directory = DirectoryConfiguration.detect().publicDirectory
        let imageDirectory = URL(fileURLWithPath: directory.appending("scores"), isDirectory: true)
        
        // Crea el directorio si no existe
        try FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true, attributes: nil)

        let filename = (scoreID?.uuidString ?? "undefined") + ".jpg"
        let fileURL = imageDirectory.appendingPathComponent(filename)

        // Convierte los datos del archivo a ByteBuffer
        let byteBuffer = ByteBuffer(data: scoreDTO.image)

        // Escribe los datos de la imagen al archivo
        try await req.fileio.writeFile(byteBuffer, at: fileURL.path)

        return .created
    }
    
    @Sendable func getGameScores(req: Request) async throws -> [Score.ScoreResponse] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db),
              let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        let scores = try await user.$gamesScores
            .$pivots
            .query(on: req.db)
            .filter(\.$game.$id == game.requireID())
            .all()
        
        return try Score.toScoreResponse(scores: scores)
    }
}

extension ByteBuffer {
    static func from(data: Data) -> ByteBuffer {
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        return buffer
    }
}
