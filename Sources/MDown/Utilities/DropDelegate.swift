import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDropDelegate: DropDelegate {
    let appState: AppState

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.fileURL])
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.fileURL]).first else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }

            let ext = url.pathExtension.lowercased()
            guard ext == "md" || ext == "markdown" else { return }

            DispatchQueue.main.async {
                appState.loadFile(url: url)
            }
        }

        return true
    }
}
