# Privacy Policy

**Last updated:** 14 May 2026

Splitway is a household expense tracker for iOS. This page explains, in plain language, what data Splitway handles and what we do with it.

The short version: almost everything stays on your iPhone. The one exception is the AI assistant, and that is off by default.

## What data Splitway stores

When you use Splitway, the app stores the following on your device:

- Your display name and avatar (a photo or emoji you picked).
- The household name, invite code, and the list of members.
- Groups you create and which members belong to them.
- Every expense you log, including amount, category, description, date, who paid, and how it was split.
- Settlements (records of one person paying another).
- Budgets and recurring bill templates.
- Receipt photos you scan, compressed and stored on your device.
- Line items parsed from receipts.
- Item rules ("milk is always shared, face wash is always Hamza's") that the app learns over time.
- AI assistant conversation history, capped at the most recent 50 messages.

All of the above lives in Apple's Core Data on your iPhone.

## iCloud sync

Splitway uses Apple iCloud (CloudKit) to sync your data across your own Apple devices and, when you share an invite link, between household members.

We do not run a server. We do not have a copy of your data. Apple stores the data in encrypted form in your iCloud account, and only people you have invited to your household can read it.

If you sign out of iCloud, sync stops. Local data on each device stays where it is.

## What we do not collect

Splitway does not include any of the following:

- Analytics or telemetry of any kind.
- Crash reporting that identifies you personally.
- Advertising SDKs or any third-party tracking.
- Marketing or behavioral profiling.
- A backend service operated by us that holds your data.

The app does not know who you are. Your Apple ID never leaves your device.

## The AI assistant (optional, off by default)

Splitway has an optional AI assistant powered by DeepSeek. The assistant is OFF by default. You explicitly opt in during onboarding or in Settings. You can turn it off at any time.

When the assistant is on, each time you tap a question chip, Splitway sends DeepSeek a small JSON snapshot of your household so it can answer. The snapshot contains:

- Member display names.
- Current month and previous month spending totals.
- Per-category spending for the current and previous month.
- Budgets and how much is spent against each.
- Recurring bills and their next occurrence dates.
- Outstanding balances and simplified payment list.
- The most recent 20 expenses (description, amount, category, date, payer).
- Your question and the recent chat turns for context.

The snapshot does NOT contain:

- Your Apple ID or iCloud account.
- Apple device identifiers.
- Raw receipt images or photos.
- Items, groups, or members you did not include in the household.
- Any data from other apps.

DeepSeek's own privacy policy governs what they do with the request. They typically retain prompts for a limited safety review window. Refer to DeepSeek's policy at platform.deepseek.com for current details.

## Receipt-name cleanup (same opt-in)

If you have the AI assistant enabled, Splitway also uses DeepSeek to clean up abbreviated receipt item names (for example, turning "WHL MLK GAL" into "Whole milk gallon"). When you scan a receipt, the raw item names are sent in a single batched call. Cleaned names are cached locally so the same items do not get re-sent.

If you turn the assistant off, this cleanup stops too.

## How long we keep data

Data lives on your device until you delete it. Specifically:

- The app's local storage persists until you delete the app or use Settings, Developer, Reset app data.
- iCloud data persists for as long as you keep the household, or until you sign out of iCloud and Apple purges it per their own policy.
- Receipt images persist with the rest of the data. A per-receipt retention policy (6 months, 12 months, forever, never) is coming in a future release.
- AI assistant history is capped at the most recent 50 messages. Older messages are deleted automatically. You can clear the entire conversation at any time from the Assistant tab.
- DeepSeek's retention is governed by their policy.

## Your rights and controls

You can at any time:

- Open Settings, Developer, Reset app data to delete every record on your device.
- Delete the Splitway app to remove all local storage.
- Sign out of iCloud to stop syncing across devices.
- Turn off the AI assistant in Settings to stop any external data transmission.
- Clear the conversation in the Assistant tab.
- Contact us to request information about how your data is handled (see Contact below).

## Children

Splitway is not directed at children under 13. The App Store age rating is 4+, but the app is not designed for use by children and we do not knowingly collect data from anyone in that age group.

## Changes to this policy

If we change anything material, we will publish the new version of this policy and announce the change inside the app before it takes effect. The "Last updated" date at the top will reflect the change.

## Contact

Questions about this policy or a data request:

- Email: support@splitway.app
- Mail: (to be added when a registered business address is in place)

Splitway is operated by Mahdi Baig as an independent iOS developer.
