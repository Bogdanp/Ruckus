extension PackageSource: CustomStringConvertible {
  public var description: String {
    switch self {
    case .catalog(let name):
      name
    case .catalogWithSource(_, let source):
      source
    case .url(let url):
      url
    case .git(let url):
      url
    case .file(let path):
      path
    case .dir(let path):
      path
    case .link(let path):
      path
    case .staticLink(let path):
      path
    case .clone(_, let source):
      source
    }
  }
}
