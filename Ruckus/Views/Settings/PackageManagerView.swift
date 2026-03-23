import SwiftUI

struct PackageManagerView: View {
  @State private var manager = PackageManager()
  @State private var searchText = ""
  @State private var searchTask: Task<Void, Never>?

  var body: some View {
    List {
      installedSection
      if !searchText.isEmpty {
        searchSection
      }
    }
    .searchable(text: $searchText, prompt: "Search packages")
    .onChange(of: searchText) {
      searchTask?.cancel()
      searchTask = Task {
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        await manager.search(query: searchText)
      }
    }
    .navigationTitle("Packages")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await manager.loadInstalled()
    }
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
            Text(pkg.source)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          .swipeActions(edge: .trailing) {
            AsyncButton(role: .destructive) {
              try? await manager.remove(name: pkg.name)
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
            if !isInstalled(pkg.name) {
              AsyncButton(options: [.showsProgressView, .disabledWhileRunning, .showsSuccessIcon]) {
                try? await manager.install(source: pkg.name)
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

  private func isInstalled(_ name: String) -> Bool {
    manager.installedPackages.contains { $0.name == name }
  }
}
