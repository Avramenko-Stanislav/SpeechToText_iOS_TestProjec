//
//  CoreDataStack.swift
//  ChatDataStorage
//
//  Created by Stanislav on 12.01.2026.
//

import CoreData

@MainActor
public final class CoreDataStack {
  public static let shared = CoreDataStack()

  // MARK: - Properties

  public let container: NSPersistentContainer
  private let readyTask: Task<Void, Error>

  // MARK: - Init

  public init(inMemory: Bool = false) {
    let model = CoreDataStack.makeModel()
    let container = NSPersistentContainer(
      name: Constants.modelName,
      managedObjectModel: model
    )

    if inMemory {
      let description = NSPersistentStoreDescription()
      description.type = NSInMemoryStoreType
      container.persistentStoreDescriptions = [description]
    }

    self.container = container
    self.readyTask = Task {
      try await withCheckedThrowingContinuation { cont in
        container.loadPersistentStores { _, error in
          if let error {
            cont.resume(throwing: error)
          } else {
            cont.resume(returning: ())
          }
        }
      }
    }

    configureViewContext(container.viewContext)
  }

  // MARK: - Public

  public func ready() async throws {
    try await readyTask.value
  }

  // MARK: - Context configuration

  private func configureViewContext(_ context: NSManagedObjectContext) {
    context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    context.automaticallyMergesChangesFromParent = true
  }

  // MARK: - Programmatic model

  private static func makeModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    model.entities = [makeChatEntity()]

    return model
  }

  private static func makeChatEntity() -> NSEntityDescription {
    let entity = NSEntityDescription()
    entity.name = Constants.chatEntityName
    entity.managedObjectClassName = Constants.managedObjectClassName

    let id = makeAttribute(
      name: Constants.attributeID,
      type: .stringAttributeType,
      isOptional: false,
      isIndexed: true
    )

    let title = makeAttribute(
      name: Constants.attributeTitle,
      type: .stringAttributeType,
      isOptional: false,
      isIndexed: false
    )

    let lastMessagePreview = makeAttribute(
      name: Constants.attributeLastMessagePreview,
      type: .stringAttributeType,
      isOptional: true,
      isIndexed: false
    )

    let updatedAt = makeAttribute(
      name: Constants.attributeUpdatedAt,
      type: .dateAttributeType,
      isOptional: false,
      isIndexed: true
    )

    entity.properties = [id, title, lastMessagePreview, updatedAt]
    return entity
  }

  private static func makeAttribute(
    name: String,
    type: NSAttributeType,
    isOptional: Bool,
    isIndexed: Bool
  ) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()

    attribute.name = name
    attribute.attributeType = type
    attribute.isOptional = isOptional
    attribute.isIndexed = isIndexed

    return attribute
  }
}

private enum Constants {
  static let modelName = "SpeechToText"
  static let chatEntityName = "ChatEntity"
  static let managedObjectClassName = "NSManagedObject"

  static let attributeID = "id"
  static let attributeTitle = "title"
  static let attributeLastMessagePreview = "lastMessagePreview"
  static let attributeUpdatedAt = "updatedAt"
}
