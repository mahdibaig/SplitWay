# Privacy Nutrition Label (App Store Connect)

Apple's privacy nutrition label has three sections: Data Used to Track You, Data Linked to You, Data Not Linked to You. Splitway's answers follow.

## Data Used to Track You

**None.** Splitway does not track users across apps and websites owned by other companies, and does not share any data with data brokers.

## Data Linked to You

**None.** Splitway does not collect or store any personally identifiable data on our servers, because we don't have servers. All identifiable data (your display name, your household members, your expenses) lives on your device and, optionally, in your own iCloud account.

## Data Not Linked to You

Only one item, and only when you opt in.

### User Content
- **What's collected:** Your typed or chip-selected questions and a JSON snapshot of your household financial state (member display names, balances, current and previous month spending, budgets, recent expenses).
- **When:** Only when the AI assistant is enabled (off by default) and only at the moment you tap a question chip.
- **Where it goes:** DeepSeek's API, to generate a response. (Future: through a thin proxy we operate, which does not retain data.)
- **Linked to you:** No. We don't have an account system. The snapshot does not include your Apple ID, iCloud account, or any device identifier.
- **Used for tracking:** No.

### Diagnostics
- **None collected by us.** We do not run crash reporters or analytics. Apple's built-in App Store Connect crash logs may exist per their own platform policies; those are not under our control.

## Privacy Practices Summary

**Data collected:** None on our infrastructure. Your data lives on your device or in your iCloud account.

**Tracking:** None.

**Third-party SDKs:** None that exfiltrate data. The app uses Apple frameworks (Vision, Core Data, CloudKit, Swift Charts, UserNotifications, StoreKit, PhotosUI, Security/Keychain) and one network client that talks to DeepSeek when the user opts in.

**App Tracking Transparency prompt:** Not shown. The app does not track.

## Notes for App Store Connect entry

When filling out the privacy questionnaire:

1. "Does this app collect data?" -> **Yes** (because of the AI assistant opt-in)
2. Select "User Content -> Other User Content"
3. For "Used to track you": **No**
4. For "Linked to your identity": **No**
5. Reason: "App Functionality" (the data is required to answer your question)
6. After saving, the public label will read "Data Not Linked to You: User Content."

If we ever ship with the AI assistant default-on or with the proxy storing logs, this answer changes. Revisit before any such change.
