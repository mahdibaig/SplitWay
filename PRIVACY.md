# Splitway Privacy Policy

_Last updated: [fill in date before publishing]_

Splitway ("the app," "we," "us") is a household expense-splitting app. This
policy explains what data Splitway handles and how. Plain version: we don't
sell your data, we don't run ads, we don't track you across other apps or
websites, and you don't need an account to use Splitway.

## What stays on your device

Your households, expenses, line items, balances, budgets, recurring bills,
payment handles, and assistant chat history are stored **locally on your
device** using Apple's Core Data.

## iCloud sync (optional, Apple)

If you're signed in to iCloud, Splitway syncs your data to **your own
private iCloud account** using Apple CloudKit, so it stays in step across
your devices and (when you share a household) with the people you invite.
This data lives in your iCloud, governed by
[Apple's Privacy Policy](https://www.apple.com/legal/privacy/). We cannot
read your iCloud data. If you're not signed in to iCloud, the app still
works fully on-device.

## AI features (what leaves the device, and when)

Two optional features send data to a backend proxy we operate (on
Cloudflare), which forwards it to an AI provider and returns the result.
Nothing is sent unless you use these features:

- **Receipt scanning.** When you scan or import a receipt, the receipt
  **image** is sent to OpenAI (GPT-4o mini) to read the line items, prices,
  and categories. The image is processed to generate the result and is not
  used to train models or build a profile.
- **AI assistant.** When you ask the assistant a question, your question
  plus a **summary of your household spending** (amounts, categories,
  member display names) is sent to DeepSeek to generate the answer.

We do **not** send your name, email, Apple ID, iCloud identity, contacts,
location, or device identifiers with these requests. There is no login.
Requests are authenticated with a shared app key, not a personal account.

Sub-processors for these features: **Cloudflare** (proxy/transport),
**OpenAI** (receipt scanning), **DeepSeek** (assistant). Each processes the
data only to return a result.

## What we do NOT do

- No advertising and no ad networks.
- No third-party analytics or tracking SDKs.
- No selling or sharing of your data for marketing.
- No cross-app or cross-site tracking (App Tracking Transparency: we don't
  track).

## Payments

Subscriptions (Splitway Pro) are handled entirely by **Apple** through the
App Store. We never see your card or payment details. Payment-app handles
you enter (Venmo, Cash App, PayPal, Zelle) are stored on your device /
iCloud and are only used to open the relevant app when you settle up.

## Camera and photos

The camera is used only to scan receipts when you choose to. Photos you pick
from your library are used only to read that receipt. Splitway does not
browse, upload, or retain your photo library.

## Data retention and deletion

- Receipt images can be auto-deleted on a schedule you control in Settings.
- "Reset app data" in Settings permanently deletes your local data and
  returns the app to first launch.
- Deleting the app removes its on-device data. iCloud data follows Apple's
  iCloud deletion behavior.
- The AI proxy does not retain request contents beyond what's needed to
  return a response; AI providers' retention follows their own policies
  (OpenAI, DeepSeek) for abuse monitoring.

## Children

Splitway is not directed to children under 13 and does not knowingly
collect data from them.

## Changes

We may update this policy; the "Last updated" date will change. Material
changes will be noted in the app or release notes.

## Contact

Questions about this policy or your data: **[your support email]**.
