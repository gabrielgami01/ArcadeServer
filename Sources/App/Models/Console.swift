import Vapor
import Fluent

extension Console: @unchecked Sendable {}

final class Console: Model, Content {
    static let schema = "consoles"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .name) var name: String
    
    @Children(for: \.$console) var games: [Game]
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
