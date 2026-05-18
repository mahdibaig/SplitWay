# Support FAQ (for splitway.app/support)

The App Store listing requires a working support URL. This is the content that should live there. Plain markdown, designed to be rendered as a static page with a simple "Contact" form or a mailto link at the bottom.

---

# Splitway help

Quick answers to the most common questions. If you don't find what you need, email **support@splitway.app**.

## Setup

### How do I join my partner's or roommate's household?

Open Splitway, tap **Get started**, choose **Join a household**, and enter the 6-character invite code they shared with you. Or tap the iCloud share link they sent in iMessage. Both methods require iCloud to be signed in on your device.

### Do I need a paid Apple Developer account?

No. You need a regular Apple ID signed in to iCloud, and you need to be running iOS 17 or later. That's it.

### Does the app work without iCloud?

Yes, but only on one device. If you sign out of iCloud, your data stays on your iPhone but it can't sync across devices or to other household members. To share a household with someone, both of you need iCloud.

## Expenses

### Can I split a single line on a receipt between specific people?

Yes. After scanning a receipt, tap the assignment chip under any line item. You can pick "Shared by everyone" or any combination of specific people. Splitway will compute each person's share.

### What's the difference between "Equal" and "Excluded"?

Equal splits the expense across every member on the list. Excluded means a specific person is left out. If you log a coffee that's just for you, set the split to Equal and uncheck everyone else. The app handles it as an excluded split automatically.

### Can I edit an expense after I save it?

Yes. Tap any expense in the Expenses tab to open and edit it. Every change is recorded in the expense's edit history so housemates can see what changed. You can also soft-delete an expense and recover it within 30 days.

## Receipts

### Why are my receipt items renamed?

If you turned the AI assistant on, Splitway sends abbreviated line names (like "WHL MLK GAL") to DeepSeek once per scan to convert them to readable names ("Whole milk gallon"). The renamed items show a small "AI" pill. Tap the pill to revert to the raw text.

### The receipt scanner missed a line. What do I do?

Tap "Add" in the line items section of the review screen and type the missing line manually. The parser is generic in v1; store-aware parsers for Costco, H-E-B, Walmart, and Target are coming.

### How do I delete a receipt photo I scanned?

Open the expense, tap the receipt thumbnail, and tap the trash icon. The expense itself stays; only the image is removed.

## Budgets and bills

### How do budget alerts work?

When you set a monthly budget for a category, Splitway sends you a local notification when household spending crosses 80 percent and again at 100 percent. One notification per category per month. You can turn alerts off in Settings, Notifications.

### My recurring bill didn't auto-log. Why?

Fixed-amount bills auto-log on or after the day of month you picked, the next time you open the app. Variable-amount bills don't auto-log; they appear as a "Bills due" banner on Home so you can enter the actual amount.

## AI assistant

### What does the AI assistant know about me?

When you enable it, each tap sends DeepSeek a JSON snapshot of your household: member names, balances, this and last month's spending, budgets, recurring bills, and your 20 most recent expenses. It does not send your Apple ID, raw receipt images, photos, or anything else from outside Splitway.

### How do I turn the AI assistant off?

Open Settings, Preferences, Assistant, and toggle "Enable AI assistant" off. The chat tab will go back to a "turn it on first" state, and no more requests are sent to DeepSeek.

### Why are there no free-form questions?

Free-form questions are easy to misuse and easy to hallucinate. The chip list is curated to cover the questions Splitway can answer well. We may expand it as the app gets more capable.

## Privacy

### Do you have my data?

No. We don't operate a server that stores your data. Everything is on your iPhone and, if you choose, in your own iCloud account. The AI assistant is the only feature that sends data off-device, and only when you opt in.

### Can I export everything?

A CSV export is on the v1 roadmap. For now, you can use Apple's standard backup of your iPhone (which includes Splitway's data) or sign in to iCloud on a Mac with the same Apple ID and use the iCloud Drive interface.

### How do I delete everything?

Open Settings, scroll to Developer, and tap "Reset app data." That wipes the household, members, expenses, settlements, budgets, recurring bills, and AI history on the device. To also remove iCloud copies, sign out of iCloud or remove Splitway from your iCloud drive via Settings, your Apple ID, iCloud.

## Pricing

### What's free vs paid?

The first 14 days are a free trial of Pro features. After that, the free tier covers logging unlimited expenses with all five split types, one group, settle-up, recurring bills, and basic current-month reports. Paid unlocks unlimited groups, full reports with trends and personal view, budgets and alerts, receipt OCR with item review, AI receipt cleanup, the AI assistant, CSV export, and sharing with three or more people.

### Will you ever add a daily expense cap?

No. We promise.

## Contact

Still stuck? Email **support@splitway.app**. We usually reply within a couple of days.
