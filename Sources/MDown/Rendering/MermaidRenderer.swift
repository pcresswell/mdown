import AppKit
import CryptoKit
import WebKit

/// Renders Mermaid diagram source to a PNG on disk using an offscreen WKWebView.
/// Callers supply the Mermaid source and light/dark preference; the renderer
/// returns a file URL suitable for embedding in an `<img>` tag.
struct RenderedMermaid {
    let url: URL
    let logicalSize: CGSize
}

@MainActor
final class MermaidRenderer {
    static let shared = MermaidRenderer()

    private let tempDir: URL
    private var diskCache: [String: RenderedMermaid] = [:]
    private var renderChain: Task<Void, Never>?
    private let mermaidJS: String?

    init() {
        let fm = FileManager.default
        tempDir = fm.temporaryDirectory.appendingPathComponent("mdown-mermaid", isDirectory: true)
        try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        if let url = Bundle.module.url(forResource: "mermaid.min", withExtension: "js"),
            let js = try? String(contentsOf: url, encoding: .utf8) {
            mermaidJS = js
        } else {
            mermaidJS = nil
        }
    }

    /// Render the given Mermaid source and return a file URL to the resulting PNG.
    /// Renders are serialized: concurrent calls wait on each other so the shared
    /// snapshot window is never driven by two requests at once.
    func render(source: String, isDark: Bool, scale: CGFloat = 2.0) async -> RenderedMermaid? {
        let key = cacheKey(source: source, isDark: isDark, scale: scale)
        if let cached = diskCache[key], FileManager.default.fileExists(atPath: cached.url.path) {
            return cached
        }
        guard let mermaidJS else { return nil }

        let previous = renderChain
        let task = Task { [self] () -> RenderedMermaid? in
            _ = await previous?.value
            return await Self.perform(
                source: source, isDark: isDark, scale: scale,
                key: key, tempDir: tempDir, mermaidJS: mermaidJS
            )
        }
        renderChain = Task { _ = await task.value }

        let result = await task.value
        if let result { diskCache[key] = result }
        return result
    }

    private func cacheKey(source: String, isDark: Bool, scale: CGFloat) -> String {
        let digest = SHA256.hash(data: Data(source.utf8))
        let hex = digest.compactMap { String(format: "%02x", $0) }.joined().prefix(16)
        return "\(hex)-\(isDark ? "dark" : "light")-\(Int(scale * 100))-w900"
    }

    private static func perform(
        source: String, isDark: Bool, scale: CGFloat,
        key: String, tempDir: URL, mermaidJS: String
    ) async -> RenderedMermaid? {
        await withCheckedContinuation { (continuation: CheckedContinuation<RenderedMermaid?, Never>) in
            let session = MermaidRenderSession(
                source: source,
                isDark: isDark,
                scale: scale,
                key: key,
                tempDir: tempDir,
                mermaidJS: mermaidJS,
                completion: { rendered in
                    continuation.resume(returning: rendered)
                }
            )
            session.start()
        }
    }
}

// MARK: - Per-render session

@MainActor
private final class MermaidRenderSession: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    private let source: String
    private let isDark: Bool
    private let scale: CGFloat
    private let key: String
    private let tempDir: URL
    private let mermaidJS: String
    private var completion: ((RenderedMermaid?) -> Void)?
    private var logicalSize: CGSize = .zero

    private var window: NSWindow?
    private var webView: WKWebView?
    private var didFinish = false
    private var timeoutTask: DispatchWorkItem?

    init(
        source: String, isDark: Bool, scale: CGFloat, key: String,
        tempDir: URL, mermaidJS: String, completion: @escaping (RenderedMermaid?) -> Void
    ) {
        self.source = source
        self.isDark = isDark
        self.scale = scale
        self.key = key
        self.tempDir = tempDir
        self.mermaidJS = mermaidJS
        self.completion = completion
    }

    func start() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "done")
        contentController.add(self, name: "log")
        config.userContentController = contentController
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        let initialFrame = NSRect(x: 0, y: 0, width: 1200, height: 800)
        let webView = WKWebView(frame: initialFrame, configuration: config)
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        self.webView = webView

        // Off-screen window so the WKWebView has a valid window/layer.
        let window = NSWindow(
            contentRect: NSRect(x: -20000, y: -20000, width: initialFrame.width, height: initialFrame.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isOpaque = false
        window.contentView = webView
        window.orderBack(nil)
        self.window = window

        let html = buildHTML()
        webView.loadHTMLString(html, baseURL: nil)

        // Safety net: abort if mermaid never reports done (bad source, load failure, etc.)
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, !self.didFinish else { return }
            self.finish(nil)
        }
        timeoutTask = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeout)
    }

    private func buildHTML() -> String {
        let sourceJSON = jsonEncode(source)
        let theme = isDark ? "dark" : "default"
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          html, body { margin: 0; padding: 0; background: transparent; }
          body { display: inline-block; padding: 8px; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
          #out svg { display: block; }
        </style>
        <script>
        window.addEventListener('error', (e) => {
          try { window.webkit.messageHandlers.log.postMessage('window error: ' + (e.message || e.error)); } catch (x) {}
        });
        window.addEventListener('unhandledrejection', (e) => {
          try { window.webkit.messageHandlers.log.postMessage('unhandled rejection: ' + e.reason); } catch (x) {}
        });
        </script>
        <script>\(mermaidJS)</script>
        </head>
        <body>
        <div id="out"></div>
        <script>
        (async () => {
          try {
            mermaid.initialize({ startOnLoad: false, theme: \(jsonEncode(theme)), securityLevel: 'loose' });
            const source = \(sourceJSON);
            const renderResult = await mermaid.render('mmd', source);
            const svg = renderResult.svg;
            const out = document.getElementById('out');
            out.innerHTML = svg;
            const el = out.querySelector('svg');
            let w = 0, h = 0;
            const vb = el.getAttribute('viewBox');
            if (vb) {
              const parts = vb.split(/\\s+/).map(Number);
              w = Math.ceil(parts[2]);
              h = Math.ceil(parts[3]);
            }
            if (!w || !h) {
              const r = el.getBoundingClientRect();
              w = Math.ceil(r.width);
              h = Math.ceil(r.height);
            }
            const MAX_W = 900;
            if (w > MAX_W) {
              h = Math.ceil(h * (MAX_W / w));
              w = MAX_W;
            }
            el.setAttribute('width', w);
            el.setAttribute('height', h);
            el.style.width = w + 'px';
            el.style.height = h + 'px';
            el.style.maxWidth = 'none';
            document.body.style.width = (w + 16) + 'px';
            document.body.style.height = (h + 16) + 'px';
            setTimeout(() => {
              window.webkit.messageHandlers.done.postMessage({ ok: true, width: w + 16, height: h + 16 });
            }, 50);
          } catch (e) {
            window.webkit.messageHandlers.done.postMessage({ ok: false, error: String(e) });
          }
        })();
        </script>
        </body>
        </html>
        """
    }

    private func jsonEncode(_ string: String) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: [string], options: [])) ?? Data("[\"\"]".utf8)
        let wrapped = String(data: data, encoding: .utf8) ?? "[\"\"]"
        // wrapped is a JSON array with a single string; strip the brackets
        let trimmed = wrapped.dropFirst().dropLast()
        return String(trimmed)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "log" {
            FileHandle.standardError.write(Data("[mermaid/js] \(message.body)\n".utf8))
            return
        }
        handleDoneMessage(message.body)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        FileHandle.standardError.write(Data("[mermaid] nav didFail: \(error.localizedDescription)\n".utf8))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        FileHandle.standardError.write(Data("[mermaid] nav didFailProvisional: \(error.localizedDescription)\n".utf8))
    }

    private func handleDoneMessage(_ body: Any) {
        guard !didFinish else { return }
        guard let dict = body as? [String: Any], let ok = dict["ok"] as? Bool, ok,
            let width = dict["width"] as? Double, let height = dict["height"] as? Double,
            let webView = webView, let window = window
        else {
            FileHandle.standardError.write(Data("[mermaid] render failed: \(body)\n".utf8))
            finish(nil)
            return
        }

        let pixelWidth = max(16.0, width)
        let pixelHeight = max(16.0, height)
        logicalSize = CGSize(width: pixelWidth, height: pixelHeight)

        // Resize the view and its window so the snapshot captures the whole diagram.
        let frame = NSRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)
        webView.frame = frame
        window.setContentSize(NSSize(width: pixelWidth, height: pixelHeight))

        // Wait one runloop tick so layout/paint catches up, then snapshot.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.snapshot(rect: frame)
        }
    }

    private func snapshot(rect: NSRect) {
        guard let webView else { finish(nil); return }
        let config = WKSnapshotConfiguration()
        config.rect = rect
        // Render at 2x for retina crispness.
        config.snapshotWidth = NSNumber(value: Double(rect.width * scale))
        webView.takeSnapshot(with: config) { [weak self] image, _ in
            Task { @MainActor [weak self] in
                self?.handleSnapshot(image)
            }
        }
    }

    private func handleSnapshot(_ image: NSImage?) {
        guard let image, let png = pngData(from: image) else {
            finish(nil)
            return
        }
        let fileURL = tempDir.appendingPathComponent("\(key).png")
        do {
            try png.write(to: fileURL, options: .atomic)
            finish(RenderedMermaid(url: fileURL, logicalSize: logicalSize))
        } catch {
            finish(nil)
        }
    }

    private func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff)
        else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    private func finish(_ result: RenderedMermaid?) {
        guard !didFinish else { return }
        didFinish = true
        timeoutTask?.cancel()
        timeoutTask = nil
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "done")
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "log")
        webView?.navigationDelegate = nil
        webView?.stopLoading()
        window?.orderOut(nil)
        window?.contentView = nil
        webView = nil
        window = nil
        let callback = completion
        completion = nil
        callback?(result)
    }
}
