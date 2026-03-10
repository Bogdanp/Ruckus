enum ActiveSheet: Identifiable {
  case output
  case settings
  case fileBrowser

  var id: Self { self }
}
