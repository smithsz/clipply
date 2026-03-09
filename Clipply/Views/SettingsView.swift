import SwiftUI

struct SettingsView: View {
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 40
    @AppStorage("persistHistory") private var persistHistory = true
    @AppStorage("clearHistoryOnQuit") private var clearHistoryOnQuit = false
    @AppStorage("preventDuplicates") private var preventDuplicates = true
    @AppStorage("ignorePasswords") private var ignorePasswords = true
    @AppStorage("maxCharacterLength") private var maxCharacterLength = 500
    @AppStorage("soundEffects") private var soundEffects = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    @State private var excludedApps: [String] = []
    @State private var newAppName = ""
    @State private var showingExportDialog = false
    @State private var showingImportDialog = false
    
    var body: some View {
        TabView {
            // General Settings
            Form {
                Section(header: Text("History")) {
                    HStack {
                        Text("Maximum items:")
                        Slider(value: Binding(
                            get: { Double(maxHistoryItems) },
                            set: { maxHistoryItems = Int($0) }
                        ), in: 10...99, step: 1)
                        Text("\(maxHistoryItems)")
                            .frame(width: 30)
                    }
                    
                    Toggle("Persist history between launches", isOn: $persistHistory)
                    Toggle("Clear history on quit", isOn: $clearHistoryOnQuit)
                    Toggle("Prevent duplicate consecutive items", isOn: $preventDuplicates)
                }
                
                Section(header: Text("Content")) {
                    HStack {
                        Text("Max character length:")
                        TextField("500", text: Binding(
                            get: { String(maxCharacterLength) },
                            set: { maxCharacterLength = Int($0) ?? 500 }
                        ))
                        .frame(width: 80)
                    }
                    Toggle("Ignore copied passwords", isOn: $ignorePasswords)
                        .help("Attempts to detect and ignore password-like strings")
                }
                
                Section(header: Text("Behavior")) {
                    Toggle("Sound effects", isOn: $soundEffects)
                    Toggle("Launch at login", isOn: $launchAtLogin)
                }
                
                Section(header: Text("Data Management")) {
                    HStack {
                        Button("Export History") {
                            exportHistory()
                        }
                        Button("Import History") {
                            importHistory()
                        }
                        Spacer()
                        Button("Clear All History") {
                            clearAllHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // Hotkey Settings
            Form {
                Section(header: Text("Global Hotkey")) {
                    Text("Current hotkey: ⇧⌘V")
                        .font(.title3)
                    
                    Text("Press the key combination you want to use:")
                        .foregroundColor(.secondary)
                    
                    HotkeyRecorderView()
                    
                    Text("The hotkey will open the clipboard history popup from any application.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Permissions")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessibility Access Required")
                            .font(.headline)
                        Text("Clipply needs accessibility permissions to register global hotkeys.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Open System Preferences") {
                            openAccessibilityPreferences()
                        }
                    }
                }
            }
            .padding()
            .tabItem {
                Label("Hotkey", systemImage: "keyboard")
            }
            
            // Excluded Apps Settings
            Form {
                Section(header: Text("Excluded Applications")) {
                    Text("Clipboard monitoring will be disabled for these applications:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    List {
                        ForEach(excludedApps, id: \.self) { app in
                            HStack {
                                Text(app)
                                Spacer()
                                Button {
                                    removeFromExcludedList(app)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: 200)
                    
                    HStack {
                        TextField("Application name", text: $newAppName)
                        Button("Add") {
                            addToExcludedList()
                        }
                        .disabled(newAppName.isEmpty)
                    }
                }
            }
            .padding()
            .tabItem {
                Label("Excluded Apps", systemImage: "hand.raised")
            }
            
            // About
            Form {
                Section(header: Text("")) {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 64))
                            .foregroundColor(.accentColor)
                        
                        Text("Clipply")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0")
                            .foregroundColor(.secondary)
                        
                        Text("A powerful clipboard manager for macOS")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.vertical)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Features:")
                                .fontWeight(.semibold)
                            Text("• Automatic clipboard history tracking")
                            Text("• Global hotkey access (⇧⌘V)")
                            Text("• Pin frequently used items")
                            Text("• Search and filter history")
                            Text("• Support for text, images, and files")
                            Text("• Customizable settings")
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            loadExcludedApps()
        }
    }
    
    private func loadExcludedApps() {
        excludedApps = UserDefaults.standard.stringArray(forKey: "excludedApps") ?? []
    }
    
    private func addToExcludedList() {
        guard !newAppName.isEmpty else { return }
        excludedApps.append(newAppName)
        UserDefaults.standard.set(excludedApps, forKey: "excludedApps")
        newAppName = ""
    }
    
    private func removeFromExcludedList(_ app: String) {
        excludedApps.removeAll { $0 == app }
        UserDefaults.standard.set(excludedApps, forKey: "excludedApps")
    }
    
    private func exportHistory() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "clipply-history.json"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try StorageManager.shared.exportHistory(to: url)
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
    
    private func importHistory() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let items = try StorageManager.shared.importHistory(from: url)
                    ClipboardManager.shared.history = items
                    StorageManager.shared.saveHistory()
                } catch {
                    print("Import failed: \(error)")
                }
            }
        }
    }
    
    private func clearAllHistory() {
        ClipboardManager.shared.clearAll()
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        // This would require SMLoginItemSetEnabled or ServiceManagement framework
        // For now, just store the preference
        print("Launch at login: \(enabled)")
    }
    
    private func openAccessibilityPreferences() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}

struct HotkeyRecorderView: View {
    @State private var isRecording = false
    @State private var recordedKey = "⇧⌘V"
    
    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
            HStack {
                Text(isRecording ? "Press keys..." : recordedKey)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                
                if isRecording {
                    Button("Cancel") {
                        isRecording = false
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
