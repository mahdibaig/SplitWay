import SwiftUI

struct AssistantSettingsView: View {
    @EnvironmentObject private var preferences: AssistantPreferences

    var body: some View {
        List {
            Section {
                Toggle("Enable AI assistant", isOn: $preferences.enabled)
            } footer: {
                Text("Your question and a snapshot of household data are sent to DeepSeek to generate the answer. Conversation history is stored on this device only.")
            }

            Section {
                SecureField("DeepSeek API key", text: $preferences.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.password)
                TextField("Model", text: $preferences.model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("DeepSeek")
            } footer: {
                Text("Get a key at platform.deepseek.com. Model defaults to deepseek-chat. Change it if DeepSeek renames their V4 endpoint.")
            }

            Section {
                Link("DeepSeek pricing & docs",
                     destination: URL(string: "https://platform.deepseek.com/")!)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("Assistant")
        .navigationBarTitleDisplayMode(.inline)
    }
}
