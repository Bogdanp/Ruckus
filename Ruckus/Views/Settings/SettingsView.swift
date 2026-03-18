import AppIntents
import StoreKit
import SwiftUI

struct SettingsView: View {
  @Environment(EditorSettings.self) private var settings

  var body: some View {
    SheetNavigation(title: "Settings", titleDisplayMode: .large) {
      List {
        Section {
          NavigationLink {
            EditorSettingsView()
          } label: {
            Label("Editor", systemImage: "textformat")
              .labelStyle(SettingsLabelStyle(backgroundColor: .indigo))
          }
        }
        Section {
          NavigationLink {
            DocumentationView()
          } label: {
            Label("Documentation", systemImage: "book.fill")
              .labelStyle(SettingsLabelStyle(backgroundColor: .orange))
          }
        }
        Section {
          Button(action: requestReview) {
            Label("Leave a Review", systemImage: "star.fill")
              .labelStyle(SettingsLabelStyle(backgroundColor: .yellow))
          }
          Link(destination: URL(string: "https://testflight.apple.com/join/dgRamw3P")!) {
            Label("Join the Beta", systemImage: "paperplane.fill")
              .labelStyle(SettingsLabelStyle(backgroundColor: .mint))
          }
          NavigationLink {
            SupportView()
          } label: {
            Label("Support", systemImage: "lifepreserver")
              .labelStyle(SettingsLabelStyle(backgroundColor: .accentColor))
          }
          NavigationLink {
            AboutView()
          } label: {
            Label("About", systemImage: "info")
              .labelStyle(SettingsLabelStyle(backgroundColor: .blue))
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        VStack(spacing: 12) {
          ShortcutsLink()
          Text("Version \(appVersion)")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
      }
    }
  }

  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    return "\(version) (\(build))"
  }

  private func requestReview() {
    guard let scene = UIApplication.shared.connectedScenes
      .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    else { return }
    AppStore.requestReview(in: scene)
  }
}

struct SettingsLabelStyle: LabelStyle {
  let backgroundColor: Color

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 8) {
      configuration.icon
        .font(.system(size: 14))
        .frame(width: 24, height: 24)
        .foregroundStyle(.white)
        .background(gradient, in: RoundedRectangle(cornerSize: .init(width: 8, height: 8)))
      configuration.title
    }
  }

  private var gradient: LinearGradient {
    .init(
      colors: [
        backgroundColor.mix(with: .white, by: 0.15),
        backgroundColor
      ],
      startPoint: .top,
      endPoint: .bottom
    )
  }
}
