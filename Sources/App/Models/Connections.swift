import Vapor
import Fluent

extension Connections: @unchecked Sendable {}

final class Connections: Model, Content {
    static let schema = "connections"
    
    @ID(key: .id) var id: UUID?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    @Parent(key: .follower)var follower: User
    @Parent(key: .followed)var followed: User

    init() {}

    init(id: UUID? = nil, createdAt: Date? = nil, follower: User.IDValue, followed: User.IDValue) {
        self.id = id
        self.createdAt = createdAt
        self.$follower.id = follower
        self.$followed.id = followed
    }
}

extension Connections {
    struct Response: Content {
        let id: UUID
        let user: User.Response
        let createdAt: Date
    }
    
    enum FollowType {
        case follower, following
    }
    
    var toFollowerResponse: Response {
        get throws {
            try Response(id: requireID(),
                         user: follower.toResponse,
                         createdAt: createdAt ?? .distantPast
            )
        }
    }
    
    var toFollowedResponse: Response {
        get throws {
            try Response(id: requireID(),
                         user: followed.toResponse,
                         createdAt: createdAt ?? .distantPast
            )
        }
    }
    
    static func toResponse(_ array: [Connections], type: FollowType) throws -> [Response] {
        var responses = [Response]()
        
        if type == .follower {
            for item in array {
                let response = try item.toFollowerResponse
                responses.append(response)
            }
        } else {
            for item in array {
                let response = try item.toFollowedResponse
                responses.append(response)
            }
        }
        
        return responses
    }
}
