import SwiftUI

struct PackageManagerView: View {
  @State private var manager = PackageManager.shared
  @State private var searchText = ""

  var body: some View {
    ScrollViewReader { proxy in
      List {
        installedSection
        if !manager.autoPackages.isEmpty {
          autoSection
        }
        if !searchText.isEmpty {
          searchSection
        }
      }
      .onChange(of: manager.searchResults.count) {
        if !manager.searchResults.isEmpty {
          withAnimation {
            proxy.scrollTo("searchResults", anchor: .top)
          }
        }
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
    .sheet(item: installingBinding) { source in
      InstallProgressView(source: source.id, manager: manager)
        .interactiveDismissDisabled()
    }
  }

  private var showAlert: Binding<Bool> {
    Binding(
      get: { manager.alertMessage != nil },
      set: { if !$0 { manager.alertMessage = nil } }
    )
  }

  private var installingBinding: Binding<InstallSource?> {
    Binding(
      get: { manager.installingSource.map(InstallSource.init) },
      set: { _ in }
    )
  }

  private var installedSection: some View {
    Section {
      if manager.isLoadingInstalled {
        ProgressView()
          .frame(maxWidth: .infinity)
      } else if manager.manualPackages.isEmpty && manager.activeOperations.isEmpty {
        Text("No packages installed")
          .foregroundStyle(.secondary)
      } else {
        ForEach(manager.manualPackages, id: \.name) { pkg in
          HStack {
            packageRow(pkg)
            if manager.isOperationActive(for: pkg.name) {
              Spacer()
              ProgressView()
            }
          }
          .swipeActions(edge: .trailing) {
            if manager.activeOperations.isEmpty {
              AsyncButton(role: .destructive, options: AsyncButtonOption.allButCancel) {
                await manager.remove(name: pkg.name)
              } label: {
                Label("Remove", systemImage: "trash")
                  .labelStyle(.iconOnly)
              }
            }
          }
        }
      }
    } header: {
      Text("Installed")
    }
  }

  private var autoSection: some View {
    Section {
      ForEach(manager.autoPackages, id: \.name) { pkg in
        packageRow(pkg)
          .foregroundStyle(.secondary)
          .swipeActions(edge: .trailing) {
            if manager.activeOperations.isEmpty {
              AsyncButton(role: .destructive, options: AsyncButtonOption.allButCancel) {
                await manager.remove(name: pkg.name)
              } label: {
                Label("Remove", systemImage: "trash")
                  .labelStyle(.iconOnly)
              }
            }
          }
      }
    } header: {
      HStack {
        Text("Auto-installed Dependencies")
        Spacer()
        AsyncButton(options: AsyncButtonOption.allButCancel) {
          await manager.removeOrphans()
        } label: {
          Text("Clean")
            .font(.caption)
        }
        .disabled(!manager.activeOperations.isEmpty)
      }
    }
  }

  private func packageRow(_ pkg: InstalledPackage) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(pkg.name)
      Text(pkg.source.description)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }

  private var searchSection: some View {
    Section {
      if manager.isSearching {
        ContentUnavailableView {
          ProgressView()
        } description: {
          Text("Searching packages...")
        }
      } else if manager.searchResults.isEmpty {
        ContentUnavailableView(
          "No Results",
          systemImage: "magnifyingglass",
          description: Text("No packages matching \"\(searchText)\"")
        )
      } else {
        ForEach(manager.searchResults, id: \.name) { pkg in
          HStack {
            Text(pkg.name)
            Spacer()
            if manager.isOperationActive(for: pkg.name) {
              ProgressView()
            } else if !manager.installedNames.contains(pkg.name) {
              AsyncButton(options: [.showsProgressView, .disabledWhileRunning, .showsSuccessIcon]) {
                await manager.install(source: pkg.name)
              } label: {
                Text("Install")
                  .font(.caption)
              }
              .buttonStyle(.borderedProminent)
              .buttonBorderShape(.capsule)
              .disabled(!manager.activeOperations.isEmpty)
            } else {
              Label("Installed", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .labelStyle(.iconOnly)
            }
          }
        }
      }
    } header: {
      Text("Search Results")
        .id("searchResults")
    }
  }
}

private struct InstallSource: Identifiable {
  let id: String
  init(_ source: String) { self.id = source }
}

private struct InstallProgressView: View {
  let source: String
  @Bindable var manager: PackageManager

  var body: some View {
    NavigationStack {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            Text(manager.installLog.isEmpty ? "Starting install…" : manager.installLog)
              .font(.system(.caption, design: .monospaced))
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding()
              .id("logTail")
              .textSelection(.enabled)
          }
        }
        .onChange(of: manager.installLog) {
          withAnimation {
            proxy.scrollTo("logTail", anchor: .bottom)
          }
        }
      }
      .navigationTitle("Installing \(source)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          AsyncButton(options: AsyncButtonOption.allButCancel) {
            await manager.cancelInstall()
          } label: {
            Text("Cancel")
          }
          .disabled(manager.installingSource == nil)
        }
      }
    }
  }
}
