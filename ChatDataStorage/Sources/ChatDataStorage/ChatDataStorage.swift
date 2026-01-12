import Foundation
import ChatDataKit
import CoreData

public protocol ChatDataStorageService: AnyObject, Sendable {
  func fetchAllChats() async throws -> [ChatRow]
}

public final class ChatDataStorageManager: ChatDataStorageService {
  private let dataStack: CoreDataStack

  public init(dataStack: CoreDataStack) {
    self.dataStack = dataStack
  }

  public func fetchAllChats() async throws -> [ChatRow] {
    try await dataStack.ready()

    let context = makeContext()
    return try await context.perform { [weak self] in
      guard let self else { return [] }

      let request = NSFetchRequest<NSManagedObject>(entityName: Constants.entityName)
      request.sortDescriptors = [NSSortDescriptor(key: Key.updatedAt, ascending: false)]

      let items = try context.fetch(request)
      return items.compactMap { [weak self] in
        self?.makeRow(from: $0)
      }
    }
  }
  
  private func makeContext() -> NSManagedObjectContext {
    dataStack.container.newBackgroundContext()
  }

  private func makeRow(from object: NSManagedObject, fallbackID: String? = nil) -> ChatRow? {
    let id = (object.value(forKey: Key.id) as? String).flatMap(trimmedNonEmpty) ?? fallbackID
    guard let id, !id.isEmpty else { return nil }

    let title = normalizedTitle(
      from: object.value(forKey: Key.title) as? String,
      fallback: Constants.defaultChatTitle
    )

    let preview = object.value(forKey: Key.lastMessagePreview) as? String
    let updatedAt = (object.value(forKey: Key.updatedAt) as? Date) ?? .distantPast

    return ChatRow(id: id, title: title, lastMessagePreview: preview, updatedAt: updatedAt)
  }

  private func trimmedNonEmpty(_ value: String?) -> String? {
    guard let value else { return nil }

    let trimmingValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmingValue.isEmpty ? nil : trimmingValue
  }

  private func normalizedTitle(from title: String?, fallback: String) -> String {
    trimmedNonEmpty(title) ?? fallback
  }
}

private enum Constants {
  static let entityName = "ChatEntity"
  static let defaultChatTitle = "Chat"
}

private enum Key {
  static let id = "id"
  static let title = "title"
  static let lastMessagePreview = "lastMessagePreview"
  static let updatedAt = "updatedAt"
}
