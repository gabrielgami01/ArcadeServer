import Vapor
import Fluent

extension Genre: @unchecked Sendable {}

final class Genre: Model, Content {
    static let schema = "genres"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .name) var name: String
    
    @Children(for: \.$genre) var games: [Game]
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
