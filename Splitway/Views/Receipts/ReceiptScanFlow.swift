import SwiftUI
import PhotosUI

/// Full-screen flow for scanning a receipt. Three steps:
///   1. Pick: PhotosPicker so this works on simulator (custom camera ships later).
///   2. Processing: Vision OCR + parser run.
///   3. Review: edit/assign line items, save as a real Expense.
struct ReceiptScanFlow: View {
    /// Called after the receipt's expense is successfully saved. The parent
    /// (Add Expense sheet) uses this to dismiss itself so the user lands back
    /// on the originating tab instead of an empty Add Expense form.
    var onDidSaveExpense: (() -> Void)? = nil

    @EnvironmentObject private var receiptScanService: ReceiptScanService
    @EnvironmentObject private var membersService: MembersService
    @EnvironmentObject private var expenseService: ExpenseService
    @Environment(\.dismiss) private var dismiss

    enum Step {
        case pick
        case processing
        case review
        case done
    }

    @State private var step: Step = .pick
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var draft: ReceiptDraft?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                switch step {
                case .pick:
                    pickStep
                case .processing:
                    processingStep
                case .review:
                    if let draft, let image = pickedImage {
                        ReceiptReviewView(
                            draft: draft,
                            image: image,
                            members: membersService.members.filter { !$0.isArchived },
                            onSave: handleSave,
                            onCancel: { step = .pick }
                        )
                    } else {
                        ProgressView()
                    }
                case .done:
                    Color.bg
                }
            }
            .navigationTitle("Scan receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await membersService.refresh() }
            .onChange(of: photoItem) { _, newItem in
                Task { await loadPickedPhoto(newItem) }
            }
        }
    }

    private var pickStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Color.brand)

            VStack(spacing: 8) {
                Text("Scan a receipt")
                    .font(.serifTitle)
                    .foregroundStyle(Color.text1)
                Text("Pick a photo from your library. We'll pull out the line items and let you assign each one.")
                    .font(.body)
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenH)
            }

            Spacer()

            VStack(spacing: 12) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose from library", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                        .foregroundStyle(Color.ctaText)
                }

                Text("Custom camera with frame guides is coming in a later push. For now, drop a receipt image into the iOS Photos app.")
                    .font(.caption)
                    .foregroundStyle(Color.text3)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, 24)
        }
    }

    private var processingStep: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.brand)
            Text("Reading your receipt…")
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
            Text("Apple Vision is recognizing the text on-device.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
        }
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        step = .processing
        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                errorMessage = "Couldn't read that image."
                step = .pick
                return
            }
            pickedImage = image
            let result = await receiptScanService.scan(image: image)
            draft = result
            step = .review
        } catch {
            errorMessage = error.localizedDescription
            step = .pick
        }
    }

    private func handleSave(items: [ReviewItem], category: ExpenseCategory, description: String, date: Date) async {
        guard let draft else { return }
        do {
            _ = try await receiptScanService.saveExpense(
                from: draft,
                items: items,
                category: category,
                description: description,
                date: date,
                activeMembers: membersService.members
            )
            await expenseService.refresh()
            dismiss()
            // Tell the parent (Add Expense sheet) we're done so it can close
            // too and the user lands back on the originating tab.
            onDidSaveExpense?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
