import Fluent
import Vapor

struct FollowController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "users")
        
        let follow = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        follow.get("listFollowing", use: getFollowing)
        follow.get("listFollowers", use: getFollowers)
        follow.get("isFollowed", ":userID", use: isFollowed)
        follow.post("followUser", use: followUser)
        follow.delete("unfollowUser", ":userID", use: unfollowUser)
    }
    
    @Sendable func getFollowing(req: Request) async throws -> [User.UserResponse] {
        let payload = try req.auth.require(UserPayload.self)
       
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        let users = try await user.$following
            .query(on: req.db)
            .all()
        
        return try User.toUserResponse(users: users)
    }
    
    @Sendable func getFollowers(req: Request) async throws -> [User.UserResponse] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        let users = try await user.$followers
            .query(on: req.db)
            .all()
        
        return try User.toUserResponse(users: users)
    }
    
    @Sendable func isFollowed(req: Request) async throws -> Bool {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let follower = try await User.find(UUID(uuidString: payload.subject.value), on: req.db),
              let followedID = req.parameters.get("userID", as: UUID.self),
              let followed = try await User.find(followedID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        if try await follower.$following.isAttached(to: followed, on: req.db) {
            return true
        } else {
           return false
        }
    }
    
    @Sendable func followUser(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        let userDTO = try req.content.decode(UserDTO.self)
        
        guard let follower = try await User.find(UUID(uuidString: payload.subject.value), on: req.db),
              let followed = try await User.find(userDTO.id, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        try await follower.$following.attach(followed, on: req.db)
        
        return .created
    }
    
    @Sendable func unfollowUser(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let follower = try await User.find(UUID(uuidString: payload.subject.value), on: req.db),
              let followedID = req.parameters.get("userID", as: UUID.self),
              let followed = try await User.find(followedID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        if try await follower.$following.isAttached(to: followed, on: req.db) {
            try await follower.$following.detach(followed, on: req.db)
        } else {
            throw Abort(.notFound, reason: "User is no followed")
        }
        
        return .ok
    }
}
