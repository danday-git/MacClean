import Foundation

struct TopSpaceConsumer: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let path: URL
    let size: Int64
    let categoryDescription: String
    let isFolder: Bool
    var subItems: [TopSpaceConsumer]
    
    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        size: Int64,
        categoryDescription: String,
        isFolder: Bool = true,
        subItems: [TopSpaceConsumer] = []
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.categoryDescription = categoryDescription
        self.isFolder = isFolder
        self.subItems = subItems
    }
}
