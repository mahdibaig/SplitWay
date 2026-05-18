import CoreData
import Foundation

/// Entity → Domain conversions. Domain → Entity is done in repository writes
/// (an entity belongs to a specific context, so it's not constructed standalone).

extension HouseholdEntity {
    func toDomain() -> Household? {
        guard
            let id = id,
            let createdAt = createdAt,
            let createdByUserID = createdByUserID
        else { return nil }

        return Household(
            id: HouseholdID(id),
            name: name ?? "",
            inviteCode: inviteCode ?? "",
            inviteCodeExpiresAt: inviteCodeExpiresAt,
            groupsEnabled: groupsEnabled,
            createdAt: createdAt,
            createdByUserID: UserID(createdByUserID)
        )
    }
}

extension UserEntity {
    func toDomain() -> HouseholdMember? {
        guard let id = id, let joinedAt = joinedAt else { return nil }

        return HouseholdMember(
            id: UserID(id),
            displayName: displayName ?? "",
            avatarEmoji: avatarEmoji,
            avatarImageData: avatarImageData,
            groupID: group?.id.map(GroupID.init),
            joinedAt: joinedAt,
            isArchived: isArchived
        )
    }
}

extension GroupEntity {
    func toDomain() -> HouseholdGroup? {
        guard
            let id = id,
            let createdAt = createdAt,
            let createdByUserID = createdByUserID
        else { return nil }

        return HouseholdGroup(
            id: GroupID(id),
            name: name ?? "",
            emoji: emoji,
            colorTag: colorTag,
            createdAt: createdAt,
            createdByUserID: UserID(createdByUserID)
        )
    }
}

extension ExpenseEntity {
    func toDomain() -> Expense? {
        guard
            let id = id,
            let householdID = household?.id,
            let loggedByUserID = loggedByUserID,
            let createdAt = createdAt,
            let updatedAt = updatedAt,
            let date = date,
            let categoryRaw = category,
            let category = ExpenseCategory(rawValue: categoryRaw),
            let splitJSON = splitRuleJSON,
            let split = try? CoreDataJSON.decode(SplitRule.self, from: splitJSON)
        else { return nil }

        let history: [EditRecord]
        if let raw = editHistoryJSON, let decoded = try? CoreDataJSON.decode([EditRecord].self, from: raw) {
            history = decoded
        } else {
            history = []
        }

        let items: [LineItem]
        if let raw = lineItemsJSON, let decoded = try? CoreDataJSON.decode([LineItem].self, from: raw) {
            items = decoded
        } else {
            items = []
        }

        return Expense(
            id: id,
            householdID: HouseholdID(householdID),
            loggedByUserID: UserID(loggedByUserID),
            amount: amount as Decimal? ?? .zero,
            currency: currency ?? "USD",
            category: category,
            description: descriptionText ?? "",
            merchant: merchant,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
            splitRule: split,
            editHistory: history,
            isSettled: isSettled,
            notes: notes,
            isRecurringInstance: isRecurringInstance,
            recurringTemplateID: recurringTemplateID,
            receiptImageData: receiptImageData,
            lineItems: items,
            softDeletedAt: softDeletedAt
        )
    }
}

extension ChatMessageEntity {
    func toDomain() -> ChatMessage? {
        guard
            let id = id,
            let householdID = household?.id,
            let content = content,
            let createdAt = createdAt,
            let roleRaw = role,
            let role = ChatRole(rawValue: roleRaw)
        else { return nil }

        return ChatMessage(
            id: id,
            householdID: HouseholdID(householdID),
            role: role,
            content: content,
            createdAt: createdAt
        )
    }
}

extension SharedItemRuleEntity {
    func toDomain() -> SharedItemRule? {
        guard
            let id = id,
            let householdID = household?.id,
            let normalizedItemName = normalizedItemName,
            let ruleTypeRaw = ruleTypeRaw,
            let createdAt = createdAt,
            let lastUsedAt = lastUsedAt
        else { return nil }

        let ruleType: SharedItemRuleType
        switch ruleTypeRaw {
        case "alwaysShared":
            ruleType = .alwaysShared
        case "alwaysAssignedTo":
            guard let uid = assignedUserID else { return nil }
            ruleType = .alwaysAssignedTo(userID: uid)
        default:
            return nil
        }

        let cat: ExpenseCategory?
        if let raw = category, let parsed = ExpenseCategory(rawValue: raw) {
            cat = parsed
        } else {
            cat = nil
        }

        return SharedItemRule(
            id: id,
            householdID: HouseholdID(householdID),
            normalizedItemName: normalizedItemName,
            category: cat,
            ruleType: ruleType,
            confidence: Int(confidence),
            lastUsedAt: lastUsedAt,
            createdAt: createdAt
        )
    }
}

extension RecurringTemplateEntity {
    func toDomain() -> RecurringTemplate? {
        guard
            let id = id,
            let householdID = household?.id,
            let createdAt = createdAt,
            let updatedAt = updatedAt,
            let nextOccurrence = nextOccurrence,
            let createdByUserID = createdByUserID,
            let categoryRaw = category,
            let category = ExpenseCategory(rawValue: categoryRaw)
        else { return nil }

        let resolvedAmount: Decimal?
        if isVariableAmount {
            resolvedAmount = nil
        } else {
            resolvedAmount = amount as Decimal? ?? .zero
        }

        return RecurringTemplate(
            id: id,
            householdID: HouseholdID(householdID),
            description: descriptionText ?? "",
            category: category,
            amount: resolvedAmount,
            isVariableAmount: isVariableAmount,
            dayOfMonth: Int(dayOfMonth),
            nextOccurrence: nextOccurrence,
            isActive: isActive,
            createdByUserID: UserID(createdByUserID),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension BudgetEntity {
    func toDomain() -> Budget? {
        guard
            let id = id,
            let householdID = household?.id,
            let createdAt = createdAt,
            let updatedAt = updatedAt,
            let categoryRaw = category,
            let category = ExpenseCategory(rawValue: categoryRaw)
        else { return nil }

        return Budget(
            id: id,
            householdID: HouseholdID(householdID),
            category: category,
            monthlyLimit: monthlyLimit as Decimal? ?? .zero,
            currency: currency ?? "USD",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension SettlementEntity {
    func toDomain() -> Settlement? {
        guard
            let id = id,
            let householdID = household?.id,
            let fromUserID = fromUserID,
            let toUserID = toUserID,
            let createdByUserID = createdByUserID,
            let settledAt = settledAt
        else { return nil }

        return Settlement(
            id: id,
            householdID: HouseholdID(householdID),
            fromUserID: UserID(fromUserID),
            toUserID: UserID(toUserID),
            amount: amount as Decimal? ?? .zero,
            currency: currency ?? "USD",
            method: method,
            note: note,
            settledAt: settledAt,
            createdByUserID: UserID(createdByUserID)
        )
    }
}

/// JSON helper for Codable values stored in Core Data string attributes.
enum CoreDataJSON {
    static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()

    static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    static func encode<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func decode<T: Decodable>(_ type: T.Type, from raw: String) throws -> T {
        let data = Data(raw.utf8)
        return try decoder.decode(type, from: data)
    }
}
