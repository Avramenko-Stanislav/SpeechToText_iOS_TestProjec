import Foundation
import ChatDataKit
import CoreData

public protocol ChatDataStorageService: AnyObject, Sendable {
  func fetchAllChats() async throws -> [ChatRow]
  func fetchChat(chatID: String) async throws -> ChatRow
  func createChat(title: String?) async throws -> ChatRow
  func upsertChat(chatID: String?, title: String?, transcript: String) async throws -> ChatRow
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

  public func fetchChat(chatID: String) async throws -> ChatRow {
    let id = trimmedNonEmpty(chatID)
    guard let id else { throw CoreDataRepoError.invalidChatID }

    try await dataStack.ready()
    let context = makeContext()

    return try await context.perform { [weak self] in
      guard let self else {
        throw CoreDataRepoError.storesNotLoaded
      }

      let request = self.makeFetchRequest(chatID: id)
      guard let object = try context.fetch(request).first else {
        throw CoreDataRepoError.chatNotFound(id)
      }

      guard let row = self.makeRow(from: object, fallbackID: id) else {
        throw CoreDataRepoError.chatNotFound(id)
      }
      return row
    }
  }

  public func upsertChat(chatID: String?, title: String?, transcript: String) async throws -> ChatRow {
    let text = trimmedNonEmpty(transcript)

    guard let text else {
      throw CoreDataRepoError.textMissing
    }

    try await dataStack.ready()

    let id = trimmedNonEmpty(chatID) ?? UUID().uuidString
    let now = Date()
    let resolvedTitle = normalizedTitle(from: title, fallback: Constants.defaultChatTitle)


    let context = makeContext()
    return try await context.perform { [weak self] in
      guard let self else {
        throw CoreDataRepoError.storesNotLoaded
      }

      let request = self.makeFetchRequest(chatID: id)

      let chat: NSManagedObject
      if let existing = try context.fetch(request).first {
        chat = existing
      } else {
        chat = NSEntityDescription.insertNewObject(forEntityName: Constants.entityName, into: context)
        chat.setValue(id, forKey: Key.id)
      }

      chat.setValue(resolvedTitle, forKey: Key.title)
      chat.setValue(text, forKey: Key.lastMessagePreview)
      chat.setValue(now, forKey: Key.updatedAt)

      try context.save()

      return ChatRow(
        id: id,
        title: resolvedTitle,
        lastMessagePreview: text,
        updatedAt: now
      )
    }
  }

  public func createChat(title: String?) async throws -> ChatRow {
    try await dataStack.ready()

    let context = makeContext()
    return try await context.perform { [weak self] in
      guard let self else {
        throw CoreDataRepoError.storesNotLoaded
      }

      let resolvedTitle = normalizedTitle(from: title, fallback: Constants.defaultNewChatTitle)
      let id = UUID().uuidString
      let now = Date()

      let object = NSEntityDescription.insertNewObject(forEntityName: Constants.entityName, into: context)
      object.setValue(id, forKey: Key.id)
      object.setValue(resolvedTitle, forKey: Key.title)
      object.setValue(nil, forKey: Key.lastMessagePreview)
      object.setValue(now, forKey: Key.updatedAt)

      try context.save()

      return ChatRow(id: id, title: resolvedTitle, lastMessagePreview: nil, updatedAt: now)
    }
  }

  private func makeFetchRequest(chatID: String) -> NSFetchRequest<NSManagedObject> {
    let request = NSFetchRequest<NSManagedObject>(entityName: Constants.entityName)

    request.fetchLimit = 1
    request.predicate = NSPredicate(format: Constants.predicateByIDFormat, Key.id, chatID)

    return request
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
  static let defaultNewChatTitle = "New Chat"
  static let predicateByIDFormat = "%K == %@"

}

private enum Key {
  static let id = "id"
  static let title = "title"
  static let lastMessagePreview = "lastMessagePreview"
  static let updatedAt = "updatedAt"
}
