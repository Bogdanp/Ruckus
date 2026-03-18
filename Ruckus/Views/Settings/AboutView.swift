import SwiftUI

struct AboutView: View {
  var body: some View {
    List {
      Section {
        HStack(spacing: 16) {
          if let icon = UIImage(named: "AppIcon") {
            Image(uiImage: icon)
              .resizable()
              .frame(width: 60, height: 60)
              .clipShape(RoundedRectangle(cornerRadius: 14))
          }
          VStack(alignment: .leading, spacing: 4) {
            Text("Ruckus")
              .font(.title2.bold())
            Text("Version \(appVersion)")
              .font(.subheadline)
              .foregroundStyle(.secondary)
            Link("defn.io", destination: URL(string: "https://defn.io")!)
              .font(.subheadline)
          }
        }
        .padding(.vertical, 4)
      }
      Section("Open Source Licenses") {
        ForEach(licenses, id: \.name) { license in
          NavigationLink(license.name) {
            ScrollView {
              Text(license.text)
                .font(.caption.monospaced())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(license.name)
            .navigationBarTitleDisplayMode(.inline)
          }
        }
      }
    }
    .navigationTitle("About")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    return "\(version) (\(build))"
  }

  private var licenses: [LicenseEntry] {
    guard let url = Bundle.main.url(forResource: "licenses", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let entries = try? JSONDecoder().decode([LicenseEntry].self, from: data)
    else { return [] }
    return entries
  }
}

private struct LicenseEntry: Decodable {
  let name: String
  let text: String
}
