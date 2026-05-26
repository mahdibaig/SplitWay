import SwiftUI

struct AssistantSettingsView: View {
    @EnvironmentObject private var preferences: AssistantPreferences

    private var proxyConfigured: Bool { AssistantProxyConfig.shared.isConfigured }

    var body: some View {
        List {
            Section {
                Toggle("Enable AI assistant", isOn: $preferences.enabled)
                    .disabled(!proxyConfigured)
            } footer: {
                if proxyConfigured {
                    Text("Your question and a snapshot of household data are sent to the Splitway assistant service. Conversation history is stored on this device only.")
                } else {
                    Text("The assistant service isn't configured in this build. AI features are unavailable until the next app update.")
                        .foregroundStyle(Color.red)
                }
            }

            Section {
                TextField("Model", text: $preferences.model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(!proxyConfigured)
            } header: {
                Text("Advanced")
            } footer: {
                Text("Defaults to deepseek-chat. Most users should leave this alone.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bg.ignoresSafeArea())
        .navigationTitle("Assistant")
        .navigationBarTitleDisplayMode(.inline)
    }
}
