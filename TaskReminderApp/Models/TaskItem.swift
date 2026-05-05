import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var dueDate: Date
    var imageData: Data?

    init(id: UUID = UUID(), name: String, dueDate: Date, imageData: Data? = nil) {
        self.id = id
        self.name = name
        self.dueDate = dueDate
        self.imageData = imageData
    }
}
