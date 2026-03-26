import SwiftUI

struct TabBarCollectionView: UIViewRepresentable {
  var documents: [EditorDocument]
  var activeDocumentID: UUID?
  var onSelect: (EditorDocument) -> Void
  var onClose: (EditorDocument) -> Void
  var onReorder: ([UUID]) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  func makeUIView(context: Context) -> UICollectionView {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.estimatedItemSize = CGSize(width: 80, height: 32)
    layout.minimumInteritemSpacing = 6
    layout.minimumLineSpacing = 6
    layout.sectionInset = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)

    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.alwaysBounceHorizontal = true
    collectionView.dragInteractionEnabled = true
    collectionView.delegate = context.coordinator
    collectionView.dragDelegate = context.coordinator
    collectionView.dropDelegate = context.coordinator

    context.coordinator.setupDataSource(collectionView)
    return collectionView
  }

  func updateUIView(_ collectionView: UICollectionView, context: Context) {
    context.coordinator.parent = self
    guard !collectionView.hasActiveDrag else { return }

    var scrollTarget: IndexPath?
    if let activeID = activeDocumentID,
       activeID != context.coordinator.previousActiveID,
       let index = documents.firstIndex(where: { $0.id == activeID }) {
      context.coordinator.previousActiveID = activeID
      scrollTarget = IndexPath(item: index, section: 0)
    }

    context.coordinator.applySnapshot(scrollingTo: scrollTarget)
  }

  // MARK: - Coordinator

  final class Coordinator: NSObject,
    UICollectionViewDelegate,
    UICollectionViewDragDelegate,
    UICollectionViewDropDelegate {

    var parent: TabBarCollectionView
    var previousActiveID: UUID?
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    private weak var collectionView: UICollectionView?

    init(parent: TabBarCollectionView) {
      self.parent = parent
    }

    func setupDataSource(_ collectionView: UICollectionView) {
      self.collectionView = collectionView
      let registration = UICollectionView.CellRegistration<UICollectionViewCell, UUID> { [weak self] cell, _, docID in
        guard let self, let doc = self.parent.documents.first(where: { $0.id == docID })
        else { return }
        cell.contentConfiguration = UIHostingConfiguration {
          TabBarItemContent(
            title: doc.title,
            isDirty: doc.isDirty,
            isActive: doc.id == self.parent.activeDocumentID,
            onClose: { self.parent.onClose(doc) }
          )
        }
        .margins(.all, 0)
        .background(.clear)
      }

      dataSource = UICollectionViewDiffableDataSource<Int, UUID>(
        collectionView: collectionView
      ) { collectionView, indexPath, docID in
        collectionView.dequeueConfiguredReusableCell(
          using: registration, for: indexPath, item: docID
        )
      }

      dataSource.reorderingHandlers.canReorderItem = { _ in true }
      dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
        guard let self else { return }
        self.parent.onReorder(transaction.finalSnapshot.itemIdentifiers)
      }

      applySnapshot()
    }

    func applySnapshot(scrollingTo indexPath: IndexPath? = nil) {
      var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
      snapshot.appendSections([0])
      let ids = parent.documents.map(\.id)
      snapshot.appendItems(ids)
      snapshot.reconfigureItems(ids)
      dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
        guard let self, let collectionView = self.collectionView else { return }
        collectionView.collectionViewLayout.invalidateLayout()
        if let indexPath {
          collectionView.layoutIfNeeded()
          collectionView.scrollToItem(
            at: indexPath,
            at: .centeredHorizontally,
            animated: true
          )
        }
      }
    }

    // MARK: - Selection

    func collectionView(
      _ collectionView: UICollectionView,
      didSelectItemAt indexPath: IndexPath
    ) {
      collectionView.deselectItem(at: indexPath, animated: false)
      guard indexPath.item < parent.documents.count else { return }
      parent.onSelect(parent.documents[indexPath.item])
    }

    // MARK: - Drag

    func collectionView(
      _ collectionView: UICollectionView,
      itemsForBeginning session: any UIDragSession,
      at indexPath: IndexPath
    ) -> [UIDragItem] {
      guard indexPath.item < parent.documents.count else { return [] }
      let doc = parent.documents[indexPath.item]
      let provider = NSItemProvider(object: doc.id.uuidString as NSString)
      let item = UIDragItem(itemProvider: provider)
      item.localObject = doc.id
      return [item]
    }

    // MARK: - Drop

    func collectionView(
      _ collectionView: UICollectionView,
      dropSessionDidUpdate session: any UIDropSession,
      withDestinationIndexPath dest: IndexPath?
    ) -> UICollectionViewDropProposal {
      guard collectionView.hasActiveDrag else {
        return UICollectionViewDropProposal(operation: .forbidden)
      }
      return UICollectionViewDropProposal(
        operation: .move, intent: .insertAtDestinationIndexPath
      )
    }

    func collectionView(
      _ collectionView: UICollectionView,
      performDropWith coordinator: any UICollectionViewDropCoordinator
    ) {
      // Reorder is committed via reorderingHandlers.didReorder
    }

    // MARK: - Drag/Drop Preview

    func collectionView(
      _ collectionView: UICollectionView,
      dragPreviewParametersForItemAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
      previewParameters(for: collectionView, at: indexPath)
    }

    func collectionView(
      _ collectionView: UICollectionView,
      dropPreviewParametersForItemAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
      previewParameters(for: collectionView, at: indexPath)
    }

    private func previewParameters(
      for collectionView: UICollectionView,
      at indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
      guard let cell = collectionView.cellForItem(at: indexPath) else {
        return nil
      }
      let params = UIDragPreviewParameters()
      params.visiblePath = UIBezierPath(
        roundedRect: cell.bounds, cornerRadius: 16
      )
      params.shadowPath = UIBezierPath()
      params.backgroundColor = .secondarySystemBackground
      return params
    }
  }
}
