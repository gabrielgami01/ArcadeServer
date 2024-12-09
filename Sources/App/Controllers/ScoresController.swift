import Fluent
import Vapor
import NIO

struct ScoresController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "scores")
        
        let scores = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        scores.get(":gameID", use: getGameScores)
        scores.get("ranking", ":gameID", use: getGameRanking)
        scores.post(use: addScore)
    }
    
    @Sendable func getGameScores(req: Request) async throws -> [Score.Response] {
        let user = try await getUser(req: req)
        
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        let scores = try await user.$scores
            .query(on: req.db)
            .filter(\.$game.$id == game.requireID())
            .sort(\.$createdAt, .descending)
            .all()
        
        return try Score.toResponse(scores)
    }
    
    @Sendable func getGameRanking(req: Request) async throws -> [Score.RankingScore] {
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        let scores = try await game.$scores
            .query(on: req.db)
            .with(\.$user)
            .filter(\.$status == .verified)
            .sort(\.$value, .descending)
            .all()
        
        return try Score.toRankingScore(scores)
    }
    
    @Sendable func addScore(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        let scoreDTO = try req.content.decode(CreateScoreDTO.self)
        guard let _ = try await Game.find(scoreDTO.gameID, on: req.db)  else {
            throw Abort(.notFound, reason: "Game not found")
        }
                
        let score = try Score(status: .unverified, game: scoreDTO.gameID, user: user.requireID())
        try await score.create(on: req.db)
        
        let scoreID = try score.requireID()
        
        let directory = DirectoryConfiguration.detect().publicDirectory
        let imageDirectory = URL(fileURLWithPath: directory.appending("scores"), isDirectory: true)
        
        try FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true, attributes: nil)

        let filename = "\(scoreID).jpg"
        let fileURL = imageDirectory.appendingPathComponent(filename)

        let byteBuffer = ByteBuffer(data: scoreDTO.image)

        try await req.fileio.writeFile(byteBuffer, at: fileURL.path)

        return .created
    }
}

extension ByteBuffer {
    static func from(data: Data) -> ByteBuffer {
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        return buffer
    }
}
