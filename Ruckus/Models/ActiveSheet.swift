enum ActiveSheet: Identifiable {
  case output
  case settings
  case fileBrowser
  case saveBrowser

  var id: Self { self }
}
