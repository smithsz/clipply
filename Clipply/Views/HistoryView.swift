import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    
    var filteredHistory: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.history
        }
        return clipboardManager.history.filter { $0.matches(searchText: searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard history...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // History list
            if filteredHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No clipboard history" : "No results found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredHistory) { item in
                            ClipboardItemRow(
                                item: item,
                                isSelected: selectedItemId == item.id
                            )
                            .onTapGesture {
                                selectAndPaste(item)
                            }
                            .contextMenu {
                                Button {
                                    clipboardManager.togglePin(item: item)
                                } label: {
                                    Label(
                                        item.isPinned ? "Unpin" : "Pin",
                                        systemImage: item.isPinned ? "pin.slash" : "pin"
                                    )
                                }
                                Button {
                                    clipboardManager.copyToClipboard(item: item)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                Divider()
                                Button {
                                    clipboardManager.deleteItem(item: item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            
                            if item.id != filteredHistory.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("\(filteredHistory.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    clipboardManager.clearHistory()
                } label: {
                    Text("Clear History")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(filteredHistory.filter { !$0.isPinned }.isEmpty)
                
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 400, height: 500)
    }
    
    private func selectAndPaste(_ item: ClipboardItem) {
        clipboardManager.copyToClipboard(item: item)
        
        // Play sound if enabled
        if UserDefaults.standard.bool(forKey: "soundEffects") {
            NSSound.beep()
        }
        
        // Close popover
        MenuBarManager.shared.hidePopover()
        
        // Simulate paste (Cmd+V)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            simulatePaste()
        }
    }
    
    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Cmd+V down
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        keyDownEvent?.flags = .maskCommand
        keyDownEvent?.post(tap: .cghidEventTap)
        
        // Cmd+V up
        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUpEvent?.flags = .maskCommand
        keyUpEvent?.post(tap: .cghidEventTap)
    }
    
    private func moveSelection(up: Bool) {
        guard !filteredHistory.isEmpty else { return }
        
        if let currentId = selectedItemId,
           let currentIndex = filteredHistory.firstIndex(where: { $0.id == currentId }) {
            let newIndex = up ? max(0, currentIndex - 1) : min(filteredHistory.count - 1, currentIndex + 1)
            selectedItemId = filteredHistory[newIndex].id
        } else {
            selectedItemId = filteredHistory.first?.id
        }
    }
    
    private func openSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.preview)
                        .lineLimit(3)
                        .font(.system(.body, design: .default))
                    
                    Spacer()
                    
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                
                HStack {
                    Text(item.contentType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let sourceApp = item.sourceApp {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(sourceApp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(item.displayTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
    }
    
    private var iconName: String {
        switch item.content {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
    
    private var iconColor: Color {
        switch item.content {
        case .text: return .blue
        case .image: return .green
        case .file: return .orange
        }
    }
}

#Preview {
    HistoryView()
}
