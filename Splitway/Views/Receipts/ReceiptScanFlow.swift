import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

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
    @State private var showCamera: Bool = false
    @State private var showFileImporter: Bool = false

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
            .fullScreenCover(isPresented: $showCamera) {
                DocumentScannerView(
                    onScanned: { image in
                        showCamera = false
                        Task { await processCapturedImage(image) }
                    },
                    onCancel: { showCamera = false }
                )
                .ignoresSafeArea()
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
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
                Text("Use the camera for the best results, or pick an existing photo from your library.")
                    .font(.body)
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenH)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    Label("Scan with camera", systemImage: "camera.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                        .foregroundStyle(Color.ctaText)
                }

                HStack(spacing: 12) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Photo library", systemImage: "photo.on.rectangle")
                            .font(.cardLabel.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.surface, in: .rect(cornerRadius: Radius.pill))
                            .foregroundStyle(Color.text1)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.pill)
                                    .stroke(Color.borderSubtle, lineWidth: 1)
                            )
                    }

                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Files (PDF, image)", systemImage: "doc")
                            .font(.cardLabel.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.surface, in: .rect(cornerRadius: Radius.pill))
                            .foregroundStyle(Color.text1)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.pill)
                                    .stroke(Color.borderSubtle, lineWidth: 1)
                            )
                    }
                }

                Text("Tip: for paper receipts, the camera auto-crops and flattens. For Sam's Club, Costco, Apple, or any digital PDF you've saved, use Files.")
                    .font(.caption)
                    .foregroundStyle(Color.text3)
                    .multilineTextAlignment(.center)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.warn)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
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
            Text("Sending to the scanner. This takes a few seconds.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
        }
    }

    /// Shared post-image-source handler. Called from the photo library,
    /// the live camera (VNDocumentCameraViewController), AND the Files
    /// import path so the rest of the flow doesn't care where the image
    /// came from. Everything funnels through the same cloud OCR endpoint.
    private func processCapturedImage(_ image: UIImage) async {
        step = .processing
        pickedImage = image
        let result = await receiptScanService.scan(image: image)
        draft = result
        step = .review
    }

    /// Handles the result of the `.fileImporter` modifier. Renders a PDF
    /// page or loads an image, then funnels into the shared processing
    /// path. Errors surface inline on the pick step.
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let image = try DocumentImportService.loadImage(from: url)
                Task { await processCapturedImage(image) }
            } catch {
                errorMessage = error.localizedDescription
                step = .pick
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            step = .pick
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

    private func handleSave(items: [ReviewItem], category: ExpenseCategory, description: String, date: Date, taxAndFees: Decimal) async {
        guard let draft else { return }
        do {
            _ = try await receiptScanService.saveExpense(
                from: draft,
                items: items,
                category: category,
                description: description,
                date: date,
                taxAndFees: taxAndFees,
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
