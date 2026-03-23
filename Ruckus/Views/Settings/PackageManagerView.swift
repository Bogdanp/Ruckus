import SwiftUI

struct PackageManagerView: View {
  @State private var manager = PackageManager()
  @State private var searchText = ""

  var body: some View {
    List {
      installedSection
      if !searchText.isEmpty {
        searchSection
      }
    }
    .searchable(text: $searchText, prompt: "Search packages")
    .task(id: searchText) {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      await manager.search(query: searchText)
    }
    .navigationTitle("Packages")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await manager.loadInstalled()
    }
    .alert("Error", isPresented: showAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(manager.alertMessage ?? "")
    }
  }

  private var showAlert: Binding<Bool> {
    Binding(
      get: { manager.alertMessage != nil },
      set: { if !$0 { manager.alertMessage = nil } }
    )
  }

  private var installedSection: some View {
    Section {
      if manager.isLoadingInstalled {
        ProgressView()
          .frame(maxWidth: .infinity)
      } else if manager.installedPackages.isEmpty {
        Text("No packages installed")
          .foregroundStyle(.secondary)
      } else {
        ForEach(manager.installedPackages, id: \.name) { pkg in
          VStack(alignment: .leading, spacing: 2) {
            Text(pkg.name)
          }
          .swipeActions(edge: .trailing) {
            AsyncButton(role: .destructive) {
              await manager.remove(name: pkg.name)
            } label: {
              Label("Remove", systemImage: "trash")
            }
          }
        }
      }
    } header: {
      Text("Installed")
    }
  }

  private var searchSection: some View {
    Section {
      if manager.isSearching {
        ProgressView()
          .frame(maxWidth: .infinity)
      } else if manager.searchResults.isEmpty {
        Text("No results")
          .foregroundStyle(.secondary)
      } else {
        ForEach(manager.searchResults, id: \.name) { pkg in
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(pkg.name)
              if !pkg.description.isEmpty {
                Text(pkg.description)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(2)
              }
            }
            Spacer()
            if !manager.installedNames.contains(pkg.name) {
              AsyncButton(options: [.showsProgressView, .disabledWhileRunning, .showsSuccessIcon]) {
                await manager.install(source: pkg.name)
              } label: {
                Text("Install")
                  .font(.caption)
              }
              .buttonStyle(.bordered)
            } else {
              Label("Installed", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.iconOnly)
            }
          }
        }
      }
    } header: {
      Text("Search Results")
    }
  }
}
