import SwiftUI
import UniformTypeIdentifiers

/// Three-step flow: pick a CSV file -> review the parsed preview -> commit.
/// Lives under Settings -> Money so it doesn't crowd the main tabs.
struct SplitwiseImportView: View {
    @EnvironmentObject private var membersService: MembersService
    @EnvironmentObject private var services: ServiceContainer

    @State private var preview: SplitwiseImportService.Preview?
    @State private var showFileImporter = false
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var commitResult: SplitwiseImportService.CommitResult?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.cardGap) {
                if let result = commitResult {
                    successCard(result)
                } else if let preview {
                    previewBlocks(preview)
                } else {
                    introCard
                    pickButton
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.cardLabel)
                        .foregroundStyle(Color.warn)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.vertical, 16)
        }
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("Import from Splitwise")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .text, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .task { await membersService.refresh() }
    }

    // MARK: - Intro state

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bring your history over").font(.cardTitle).foregroundStyle(Color.text1)
            Text("Splitway can read the CSV that Splitwise lets you export from your account. Each row becomes a Splitway expense with the same date, description, amount, and an equal split among the people on that row.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
            Text("Two things to know:")
                .font(.cardLabel.weight(.medium))
                .foregroundStyle(Color.text1)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                bullet("Non-equal splits in Splitwise get imported as equal splits. You can edit any expense afterward.")
                bullet("Member names in the CSV need to match members in your Splitway household. We'll show you what matched and what didn't.")
            }
        }
        .padding(Spacing.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundStyle(Color.brand)
            Text(text).font(.cardLabel).foregroundStyle(Color.text2)
        }
    }

    private var pickButton: some View {
        Button {
            errorMessage = nil
            showFileImporter = true
        } label: {
            Label("Choose CSV file", systemImage: "doc.badge.arrow.up")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                .foregroundStyle(Color.ctaText)
        }
    }

    // MARK: - Preview state

    @ViewBuilder
    private func previewBlocks(_ preview: SplitwiseImportService.Preview) -> some View {
        summaryCard(preview)
        memberMatchCard(preview)
        if !preview.warnings.isEmpty {
            warningsCard(preview)
        }
        actionButtons(preview)
    }

    private func summaryCard(_ preview: SplitwiseImportService.Preview) -> some View {
        let dateRange: String = {
            guard let range = preview.dateRange else { return "" }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: range.start)) to \(formatter.string(from: range.end))"
        }()
        return VStack(alignment: .leading, spacing: 6) {
            Text("Found").font(.cardLabel).foregroundStyle(Color.text2)
            Text("\(preview.rowCount) expense\(preview.rowCount == 1 ? "" : "s")")
                .font(.cardTitle)
                .foregroundStyle(Color.text1)
            Text("Total \(CurrencyFormat.usd(preview.totalAmount))")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
            if !dateRange.isEmpty {
                Text(dateRange).font(.caption).foregroundStyle(Color.text3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private func memberMatchCard(_ preview: SplitwiseImportService.Preview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Members").font(.cardLabel).foregroundStyle(Color.text2)
            ForEach(preview.splitwiseMemberNames, id: \.self) { name in
                HStack {
                    if let userID = preview.matches[name],
                       let member = membersService.members.first(where: { $0.id == userID }) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.success)
                        Text(name).foregroundStyle(Color.text1)
                        Spacer()
                        Text("→ \(member.displayName)")
                            .font(.caption).foregroundStyle(Color.text2)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color.warn)
                        Text(name).foregroundStyle(Color.text1)
                        Spacer()
                        Text("Unmatched").font(.caption).foregroundStyle(Color.warn)
                    }
                }
                .font(.cardLabel)
            }
            if !preview.unmatched.isEmpty {
                Text("Rows that involve unmatched members will be skipped on import. Add those members to your household first, or rename them, then re-pick the CSV.")
                    .font(.caption)
                    .foregroundStyle(Color.text3)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.surface, in: .rect(cornerRadius: Radius.card))
    }

    private func warningsCard(_ preview: SplitwiseImportService.Preview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes").font(.cardLabel).foregroundStyle(Color.text2)
            ForEach(preview.warnings, id: \.self) { warning in
                Text(warning).font(.caption).foregroundStyle(Color.text3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPad)
        .background(Color.warnSoft, in: .rect(cornerRadius: Radius.card))
    }

    @ViewBuilder
    private func actionButtons(_ preview: SplitwiseImportService.Preview) -> some View {
        VStack(spacing: 8) {
            Button {
                Task { await commit(preview) }
            } label: {
                Group {
                    if isImporting { ProgressView().tint(Color.ctaText) }
                    else { Text("Import \(preview.rowCount) expense\(preview.rowCount == 1 ? "" : "s")") }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                .foregroundStyle(Color.ctaText)
            }
            .disabled(isImporting)

            Button("Pick a different file") {
                preview.warnings.isEmpty ? () : ()
                self.preview = nil
                self.errorMessage = nil
                showFileImporter = true
            }
            .font(.cardLabel)
            .foregroundStyle(Color.text2)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Success state

    private func successCard(_ result: SplitwiseImportService.CommitResult) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.success)
            Text("Done").font(.serifTitle).foregroundStyle(Color.text1)
            Text("\(result.inserted) imported. \(result.skipped) skipped.")
                .font(.cardLabel)
                .foregroundStyle(Color.text2)
            Text("Open the Expenses tab to see them.")
                .font(.caption)
                .foregroundStyle(Color.text3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Flow

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        commitResult = nil
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // The picker hands us a security-scoped URL.
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            do {
                preview = try services.splitwiseImportService.parse(fileURL: url)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
                preview = nil
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func commit(_ preview: SplitwiseImportService.Preview) async {
        isImporting = true
        defer { isImporting = false }
        do {
            let result = try await services.splitwiseImportService.commit(preview: preview)
            commitResult = result
            self.preview = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
