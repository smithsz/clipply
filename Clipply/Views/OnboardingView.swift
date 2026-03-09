import SwiftUI

struct OnboardingView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingPage(
                    icon: "doc.on.clipboard",
                    title: "Welcome to Clipply",
                    description: "Your powerful clipboard manager for macOS. Never lose copied content again!",
                    page: 0
                )
                .tag(0)
                
                // Page 2: Hotkey
                OnboardingPage(
                    icon: "keyboard",
                    title: "Quick Access",
                    description: "Press ⇧⌘V (Shift+Command+V) anytime to open your clipboard history.",
                    page: 1
                )
                .tag(1)
                
                // Page 3: Features
                VStack(spacing: 20) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Key Features")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "pin.fill", text: "Pin important items")
                        FeatureRow(icon: "magnifyingglass", text: "Search your history")
                        FeatureRow(icon: "photo", text: "Support for text, images & files")
                        FeatureRow(icon: "lock.fill", text: "Privacy-focused design")
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(2)
                
                // Page 4: Permissions
                VStack(spacing: 20) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Accessibility Access")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Clipply needs accessibility permissions to register the global hotkey (⇧⌘V).")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button("Open System Preferences") {
                        openAccessibilityPreferences()
                    }
                    .buttonStyle(DefaultButtonStyle())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    
                    Text("You can skip this and enable it later in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(3)
            }
            .tabViewStyle(DefaultTabViewStyle())
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }
                
                Spacer()
                
                if currentPage < 3 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(DefaultButtonStyle())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                } else {
                    Button("Get Started") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(DefaultButtonStyle())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 400)
    }
    
    private func openAccessibilityPreferences() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let page: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(description)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
