import Runestone
import UIKit

struct EditorAccessoryBar {
  // Sorted by frequency across .rkt files (see bin/count-rkt-symbols).
  private static let frequentSymbols: [String] = [
    "-", "(", ")", "\"", "\\", ";", "#", ".", "[", "]",
    "?", "/", ":"
  ]
  private static let extendedSymbols: [String] = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "'", "=", ">", "_", "*", ",", "!",
    "+", "%", "~", "`", "<", "@", "|", "$", "{", "}",
    "^", "&"
  ]

  private static let barHeight: CGFloat = 76
  private static let barPadding: CGFloat = 4

  static func makeInputAccessoryView(
    for textView: TextView,
    palette: ColorPalette?
  ) -> UIInputView {
    let bar = UIInputView(
      frame: CGRect(x: 0, y: 0, width: 0, height: barHeight),
      inputViewStyle: .keyboard
    )
    bar.allowsSelfSizing = true
    if let palette {
      bar.backgroundColor = palette.backgroundColor

      // Extend a filler view below the accessory bar to cover the
      // keyboard's rounded top corners (visible when theme != system).
      let filler = UIView()
      filler.backgroundColor = palette.backgroundColor
      filler.translatesAutoresizingMaskIntoConstraints = false
      bar.addSubview(filler)
      NSLayoutConstraint.activate([
        filler.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
        filler.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
        filler.topAnchor.constraint(equalTo: bar.bottomAnchor),
        // Arbitrary large value; clipped by the screen edge.
        filler.heightAnchor.constraint(equalToConstant: 500)
      ])
    }

    let topRow = makeSnippetRow(
      snippets: frequentSymbols, for: textView, palette: palette
    )
    let bottomRow = makeSnippetRow(
      snippets: extendedSymbols, for: textView, palette: palette
    )

    let stack = UIStackView(arrangedSubviews: [topRow, bottomRow])
    stack.axis = .vertical
    stack.spacing = 4
    stack.translatesAutoresizingMaskIntoConstraints = false
    bar.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: barPadding),
      stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -barPadding),
      stack.topAnchor.constraint(equalTo: bar.topAnchor, constant: barPadding),
      stack.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -barPadding)
    ])

    return bar
  }

  private static func makeSnippetRow(
    snippets: [String],
    for textView: TextView,
    palette: ColorPalette?
  ) -> UIScrollView {
    let scrollView = UIScrollView()
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.clipsToBounds = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 6
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)

    for symbol in snippets {
      var config = UIButton.Configuration.plain()
      config.title = symbol
      config.baseForegroundColor = palette?.textColor ?? .label
      config.titleTextAttributesTransformer = .init { attrs in
        var attrs = attrs
        attrs.font = .monospacedSystemFont(ofSize: 17, weight: .medium)
        return attrs
      }
      config.contentInsets = NSDirectionalEdgeInsets(
        top: 6, leading: 12,
        bottom: 6, trailing: 12
      )
      config.background.cornerRadius = 6
      config.background.backgroundColor = palette?.gutterBackground ?? .systemBackground
      let button = UIButton(configuration: config)
      button.layer.applySoftShadow()
      button.addAction(UIAction { _ in textView.insertText(symbol) }, for: .touchUpInside)
      stack.addArrangedSubview(button)
    }

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
    ])

    return scrollView
  }
}
