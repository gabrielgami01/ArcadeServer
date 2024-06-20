import Vapor

final class SecurityManager {
    let key: SymmetricKey
    
    init() throws {
        let working = DirectoryConfiguration.detect().workingDirectory
        let url = URL(fileURLWithPath: working).appending(path: "symmetric.key")
        do {
            let keyData = try Data(contentsOf: url)
            self.key = SymmetricKey(data: keyData)
        } catch {
            let key = SymmetricKey(size: .bits256)
            let keyData = Data(key.withUnsafeBytes({ Array($0) }))
            do {
                try keyData.write(to: url, options: .atomic)
                self.key = key
            } catch {
                let logger = Logger(label: "SECURITY")
                logger.error("Error generando la clave simétrica.")
                throw Abort(.badRequest)
            }
        }
    }
}
