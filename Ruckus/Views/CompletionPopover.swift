import UIKit

final class CompletionPopover: UIView, UITableViewDataSource, UITableViewDelegate {
  private let tableView = UITableView()
  private let insertAction: (String) -> Void
  private var items: [String] = []
  private var prefix: String = ""

  private static let rowHeight: CGFloat = 32
  private static let maxVisible = 5
  private static let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

  init(insertAction: @escaping (String) -> Void) {
    self.insertAction = insertAction
    super.init(frame: .zero)
    backgroundColor = .secondarySystemBackground
    layer.cornerRadius = 8
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.2
    layer.shadowOffset = CGSize(width: 0, height: 2)
    layer.shadowRadius = 4
    clipsToBounds = false

    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = Self.rowHeight
    tableView.separatorStyle = .none
    tableView.backgroundColor = .clear
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.clipsToBounds = true
    tableView.layer.cornerRadius = 8
    addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: topAnchor),
      tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])

    isHidden = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError()
  }

  func update(items: [String], prefix: String) {
    self.items = items
    self.prefix = prefix
    tableView.reloadData()
    let visible = min(items.count, Self.maxVisible)
    let height = Self.rowHeight * CGFloat(visible)
    let widthNeeded = items.prefix(Self.maxVisible).reduce(CGFloat(200)) { maxW, item in
      let size = (item as NSString).size(withAttributes: [.font: Self.font])
      return max(maxW, size.width + 40)
    }
    frame.size = CGSize(width: min(widthNeeded, 300), height: height)
    isHidden = items.isEmpty
  }

  func dismiss() {
    isHidden = true
    items = []
    tableView.reloadData()
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = items[indexPath.row]
    let attributed = NSMutableAttributedString(
      string: item,
      attributes: [.font: Self.font, .foregroundColor: UIColor.label]
    )
    let matchRange = NSRange(location: 0, length: (prefix as NSString).length)
    attributed.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: matchRange)
    cell.textLabel?.attributedText = attributed
    cell.backgroundColor = .clear
    return cell
  }

  // MARK: - UITableViewDelegate

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let item = items[indexPath.row]
    let suffix = String(item.dropFirst(prefix.count))
    insertAction(suffix)
    dismiss()
  }
}
