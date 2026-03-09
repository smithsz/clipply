# Clipply (Clipboard Manager Application)

Create a native macOS clipboard manager application with the following specifications.

## Core Functionality

1. **Clipboard Monitoring**: Continuously monitor the system clipboard and automatically store each copied item (text, images, files) in a history list
2. **History Storage**: Maintain a configurable history of clipboard items (default: 40 items, max: 99)
3. **Menu Bar Integration**: Display as a menu bar application with an icon that provides quick access to the clipboard history
4. **Global Hotkey**: Implement a customizable keyboard shortcut (default: `Shift+Cmd+V`) to instantly open the clipboard history popup
5. **Quick Paste**: Allow users to select any item from history to paste it into the active application

## User Interface

- Clean, minimal menu bar icon
- Popup window showing clipboard history when activated
- Search/filter functionality within the history list
- Display preview of each clipboard item (truncated text or thumbnail for images)
- Show timestamp for each clipboard entry
- Keyboard navigation (arrow keys, Enter to select)

## Advanced Features

- **Pinned Items**: Allow users to "pin" frequently used items to keep them at the top
- **Blacklist**: Option to exclude certain applications from clipboard monitoring
- **Persistence**: Configurable option to save clipboard history between app restarts
- **Item Management**: Right-click context menu to delete individual items or clear all history
- **Duplicate Detection**: Optionally prevent storing duplicate consecutive items
- **Character Limit**: Set maximum character length for stored text items

## Settings/Preferences

- Number of items to remember (slider: 10-99)
- Custom global hotkey configuration
- Launch at login option
- Clear history on quit (toggle)
- Appearance settings (light/dark mode support)
- Sound effects toggle
- Ignore copied passwords option

## Technical Requirements

- **Language**: Swift with SwiftUI or AppKit
- **macOS version**: Support macOS 11.0 (Big Sur) and later
- **Permissions**: Request accessibility permissions for global hotkey
- **Performance**: Minimal CPU/memory footprint when idle
- **Security**: Handle sensitive data appropriately (passwords, private info)

## Data Structure

```swift
struct ClipboardItem {
    let id: UUID
    let content: ClipboardContent // enum: text, image, file
    let timestamp: Date
    let isPinned: Bool
    let preview: String
}
```

## Key Implementation Details

1. Use `NSPasteboard` to monitor clipboard changes
2. Implement `NSStatusItem` for menu bar presence
3. Use `NSEvent.addGlobalMonitorForEvents` for hotkey detection
4. Store history in UserDefaults or local file (JSON/SQLite)
5. Implement efficient search using `NSPredicate` or similar
6. Handle memory management for large clipboard items

## User Experience

- Instant response time (<100ms) when opening history
- Smooth animations for popup appearance
- Visual feedback when item is selected
- Graceful handling of large items (images, files)
- Clear visual distinction between text, images, and files

## Optional Enhancements

- iCloud sync between Macs
- Snippet organization with folders/tags
- Text transformation tools (uppercase, lowercase, trim)
- Export/import clipboard history
- Statistics (most used items, clipboard activity)

## Development Guidelines

Build this as a production-ready application with clean code architecture, proper error handling, and comprehensive unit tests. Include a simple onboarding flow for first-time users explaining the hotkey and basic features.
