# Phase 1 — Foundation

**Goal:** A working iOS app where two users on different iPhones can create/join a household, set up groups, and see each other appear in real time. No expenses yet — just the plumbing.

**Why this phase first:** CloudKit sharing is the single biggest technical risk. If sharing between devices doesn't work, nothing else matters. We prove it works first with the simplest possible feature (members + groups), then build on top.

**Definition of done:**
- App launches on your iPhone
- You create a household, optionally create groups, get an invite link
- Send link to your wife → she taps it → household appears on her phone
- She can be invited to a group
- Both phones show all members + groups in real time
- Settings screen works (display name, group management, archive member)

**Estimated time:** 6-9 days

---

## 1. Project setup

### 1.1 Create the Xcode project
- New iOS App project
- Product name: `Splitway`
- Interface: SwiftUI
- Storage: Core Data, **"Host in CloudKit" checked**
- Bundle ID: `com.[yourname].splitway`
- Minimum deployment: iOS 17.0

### 1.2 Enable CloudKit
- Signing & Capabilities → + Capability
- **iCloud** (check CloudKit, default container)
- **Background Modes** (Remote notifications)
- **Push Notifications**

### 1.3 Apple Developer account
- Enroll at developer.apple.com ($99/year)
- Sign in to Xcode with developer Apple ID
- Select team in Signing & Capabilities

### 1.4 Core Data setup
- Switch `NSPersistentContainer` to `NSPersistentCloudKitContainer`
- Configure two stores: private (preferences) and shared (household data)

### 1.5 Folder structure
```
Splitway/
├── App/
│   ├── SplitwayApp.swift
│   └── AppCoordinator.swift
├── Models/
│   ├── CoreData/                (.xcdatamodeld + extensions)
│   └── Domain/                  (Swift structs for views)
├── Views/
│   ├── Onboarding/
│   ├── Household/
│   ├── Groups/
│   └── Settings/
├── ViewModels/
├── Services/
│   ├── PersistenceController.swift
│   ├── CloudKitService.swift
│   ├── HouseholdService.swift
│   ├── GroupService.swift
│   └── ShareService.swift
├── Utilities/
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### 1.6 Git setup
- Init repo, first commit
- `.gitignore` from github.com/github/gitignore (Xcode-specific)
- Push to private GitHub repo

---

## 2. Core Data model (Phase 1 subset)

Only entities needed for Phase 1. Others come in later phases.

### `User`
- `id: UUID`
- `appleUserID: String` (CKRecord.ID)
- `displayName: String`
- `avatarEmoji: String?`
- `householdID: UUID`
- `groupID: UUID?` (optional)
- `isArchived: Bool` (default false)
- `archivedAt: Date?`
- `joinedAt: Date`

### `Household`
- `id: UUID`
- `name: String`
- `inviteCode: String`
- `inviteCodeExpiresAt: Date?`
- `createdAt: Date`
- `createdByUserID: UUID`
- `groupsEnabled: Bool` (set during onboarding)

### `Group`
- `id: UUID`
- `householdID: UUID`
- `name: String`
- `colorTag: String?`
- `emoji: String?`
- `memberUserIDs: [UUID]` (denormalized for fast access; also reachable via User.groupID query)
- `createdAt: Date`
- `createdByUserID: UUID`

### Relationships
- `Household` has many `Users` and many `Groups`
- `User` belongs to one `Household`, optionally one `Group`
- `Group` belongs to one `Household`, has many `Users`

### CloudKit considerations
- All three entities in **shared** Core Data store
- `appleUserID` identifies "is this me?" across devices
- `inviteCode` generated client-side, collision-checked via CloudKit query

---

## 3. Services

### 3.1 `PersistenceController`
Wraps `NSPersistentCloudKitContainer`. Two stores: private + shared.
- Initialize container with both stores
- Provide `viewContext` for SwiftUI
- Provide `backgroundContext` for non-UI writes
- Handle CloudKit account status changes

### 3.2 `CloudKitService`
Direct CloudKit operations bypassing Core Data (for sharing).
- Fetch current user's CKRecord.ID
- Check iCloud account status (`CKContainer.accountStatus`)
- Subscribe to CloudKit notifications for shared zone

### 3.3 `HouseholdService`
Business logic for household operations.
- `createHousehold(name:groupsEnabled:)` → creates Household, sets current user as creator/member, generates invite code, creates CKShare
- `joinHousehold(inviteCode:)` → looks up household by code, adds current user as member
- `joinHousehold(via shareURL:)` → handles CKShare invitation
- `archiveMember(userID:)` → sets isArchived
- `updateDisplayName(_:)` → updates current user
- `enableGroups()` / `disableGroups()` → toggles household setting

### 3.4 `GroupService` (new)
Group operations.
- `createGroup(name:colorTag:emoji:)`
- `addUserToGroup(userID:groupID:)`
- `removeUserFromGroup(userID:)` — sets `User.groupID = nil`, doesn't delete user
- `deleteGroup(_:)` — removes Group, sets all members' groupID to nil
- `inviteUserToGroup(userID:groupID:)` — sends in-app invite (Phase 2)
- `renameGroup(_:newName:)`

### 3.5 `ShareService`
CloudKit sharing primitives.
- `createShare(for household:)` → returns CKShare, URL
- `acceptShare(metadata:)` → handle incoming invitation
- Universal Links / Custom URL scheme for share links

---

## 4. Views

### 4.1 Launch flow (`AppCoordinator`)

```
1. iCloud signed in?
   No  → "Please sign in to iCloud" screen
   Yes → continue
2. User record exists locally?
   No  → Onboarding
   Yes → continue
3. User in a household?
   No  → Household setup (create or join)
   Yes → Home screen (Phase 1 = Members & Groups view)
```

### 4.2 Onboarding screens

Refer to mockups (Onboarding section). Phase 1 implements:

- **Welcome** — capybara hero + "Get started"
- **Display name + emoji** — text field + emoji picker
- **Create or join** — two big buttons
- **Create flow:**
  - Name household (with quick-pick chips)
  - Groups Y/N
  - If Yes: skeleton group creation (can defer full group setup to Phase 2 if needed)
  - Show share link + invite code
- **Join flow:**
  - Enter invite code OR auto-handled via Universal Link
  - Confirm join

NOTE: Phase 1 uses default iOS styling. Mockup-driven polish starts Phase 2.

### 4.3 Home screen (Phase 1 = Members & Groups list)

The Phase 1 "home" is just a Members & Groups view — proves CloudKit sync works.

Shows:
- Household name at top
- If groups enabled: list of groups, each with members nested
- If groups disabled: flat list of members
- "Invite member" button
- Settings gear icon

### 4.4 Settings screen (Phase 1 subset)

- Display name (editable)
- Emoji avatar (editable)
- Household name (creator can edit)
- Groups Y/N toggle
- "View invite code" / regenerate
- "Manage groups" (Phase 1: basic CRUD)
- "Leave household" (with confirmation)
- About / version info

---

## 5. CloudKit sharing — the critical bit

### 5.1 How `CKShare` works
- Household creator owns the shared zone
- Creator generates `CKShare` for the zone, URL associated
- Other users tap URL → iOS prompts to accept → access shared zone
- Core Data syncs automatically

### 5.2 Universal Links / share URL handling
- Add `Associated Domains` capability
- For v1, simplest: use CloudKit share URL directly
- Implement `SceneDelegate.windowScene(_:userDidAcceptCloudKitShareWith:)`

### 5.3 Invite code fallback
CloudKit doesn't natively support invite-by-code. Our implementation:
- Each household has 6-digit code on household record
- User enters code → query CloudKit's **public DB** for `HouseholdShareMapping` record mapping `code → shareURL`
- Auto-create mapping when generating share
- Codes expire after 7 days (configurable)

**New CloudKit record type needed:** `HouseholdShareMapping` (public DB)
- `inviteCode: String` (indexed)
- `shareURL: String`
- `householdID: String`
- `expiresAt: Date`

---

## 6. Test plan for Phase 1

Test on real devices in this order:

### Test 1: Single-device flow
- Install on your iPhone
- Onboarding → create household with groups enabled
- Verify: household exists, you're a member, can create a group, add yourself to it
- Force-quit, reopen → state persists

### Test 2: Share link flow
- Create household on your iPhone
- "Send invite link" → iMessage to wife
- Wife taps link → household appears on her phone
- Both phones show both members

### Test 3: Group invitation
- On your phone: create group "Mahmoud family", add yourself
- Invite wife to group (Phase 1: basic flow; full invite UX in Phase 2)
- Wife accepts → both phones show wife in Mahmoud family

### Test 4: Invite code flow
- On your iPhone, view invite code (e.g., "A3F8B2")
- Manually type into a third test account's phone
- Verify same outcome as link flow

### Test 5: Real-time sync
- Both phones on Members screen
- One edits display name → other updates within 5-10 seconds

### Test 6: Offline behavior
- One phone airplane mode → edit display name → bring back online → syncs

### Test 7: Archive flow
- Third member archives → remains in history, no longer in active lists

### Test 8: iCloud signed out
- Sign out of iCloud on test device → app shows "Please sign in" screen, doesn't crash

### Test 9: Groups toggle
- Disable groups → existing groups remain in data but UI shows flat member list
- Re-enable → groups reappear

---

## 7. Common pitfalls

- **Forgetting the iCloud entitlement:** compiles but CloudKit doesn't work
- **Not testing on real devices:** CloudKit sharing limited in simulator
- **Schema not deployed to production:** CloudKit has dev + prod; deploy before App Store
- **Not handling iCloud account changes:** listen for `NSUbiquityIdentityDidChange`
- **Race condition on household creation:** add user as member in same transaction as household creation
- **Group state during sharing:** ensure `groupID` references resolve across devices

---

## 8. Deliverables checklist

By end of Phase 1:

- [ ] Xcode project with CloudKit + Core Data set up
- [ ] Two-store NSPersistentCloudKitContainer (private + shared)
- [ ] User, Household, Group Core Data entities
- [ ] HouseholdShareMapping public CloudKit record
- [ ] PersistenceController, CloudKitService, HouseholdService, GroupService, ShareService
- [ ] Onboarding flow (welcome, name, create/join, groups Y/N)
- [ ] Members & Groups screen
- [ ] Settings screen with group management
- [ ] Share via link working between 2+ real devices
- [ ] Share via invite code working between 2+ real devices
- [ ] Group create/edit/delete/membership working with sync
- [ ] All 9 tests passing
- [ ] Code on GitHub
- [ ] No mockup-driven polish yet — Phase 1 uses default iOS components

---

## 9. What's intentionally NOT in Phase 1

- Expenses (Phase 2)
- Splits (Phase 2)
- Receipts (Phase 4)
- Budgets (Phase 3)
- Notifications (Phase 3)
- Charts (Phase 5)
- AI assistant (Phase 4.5)
- Mockup-driven polish — Phase 1 = functional, ugly is fine

Resist designing yet. Plumbing first.

---

## 10. Handoff to Claude Code

First prompt to Claude Code:

> "I'm building a household expense tracking iOS app. Read MASTER_SPEC.md and PHASE_1_FOUNDATION.md from this repo. We're starting Phase 1 today. Begin by setting up the Xcode project structure as specified in section 1, then implement the Core Data model in section 2. Don't start on UI yet — get the foundation right first. Ask me before making any major decisions not covered in the spec."

Work through phase sections in order. Each section = logical commit point.

---

*End of Phase 1 plan.*
