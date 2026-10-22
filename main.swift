// Google日本語入力のシークレットモードをメニューバーに表示し、クリックで切り替える。
// 実際の切り替えは ~/.local/bin/gime-incognito に任せる。
import AppKit

let script = NSString(string: "~/.local/bin/gime-incognito").expandingTildeInPath
let config = NSString(string: "~/Library/Application Support/Google/JapaneseInput/config1.db").expandingTildeInPath

final class App: NSObject, NSApplicationDelegate {
    var item: NSStatusItem!
    var lastMtime: Date?
    var on = false
    var busy = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        refresh(force: true)
        // 変換候補「しーくれっと」や環境設定から切り替えた場合も拾えるよう、設定ファイルを見張る
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refresh(force: false)
        }
    }

    func run(_ arg: String) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: script)
        p.arguments = [arg]
        let out = Pipe()
        p.standardOutput = out
        do { try p.run() } catch { return "" }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func refresh(force: Bool) {
        if busy { return }
        let mtime = (try? FileManager.default.attributesOfItem(atPath: config))?[.modificationDate] as? Date
        if !force && mtime == lastMtime { return }
        lastMtime = mtime
        on = run("status") == "on"
        draw()
    }

    func draw() {
        guard let b = item.button else { return }
        let img = NSImage(systemSymbolName: on ? "eye.slash.fill" : "eye",
                          accessibilityDescription: on ? "シークレットモード オン" : "シークレットモード オフ")
        img?.isTemplate = true
        b.image = img
        b.imagePosition = .imageLeading
        b.appearsDisabled = busy
        b.title = ""
        if on {
            // メニューバーは文字色やティントを無視するので、色付きのバッジを画像として描く
            b.image = badge()
            b.toolTip = "シークレットモード: オン（学習しない）\nクリックでオフ"
        } else {
            b.toolTip = "シークレットモード: オフ（通常）\nクリックでオン"
        }
    }

    func badge() -> NSImage {
        let font = NSFont.boldSystemFont(ofSize: 12)
        let text = NSAttributedString(string: "シークレット", attributes: [.font: font, .foregroundColor: NSColor.white])
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            .applying(.init(paletteColors: [.white]))
        let eye = NSImage(systemSymbolName: "eye.slash.fill", accessibilityDescription: nil)!
            .withSymbolConfiguration(config)!
        let pad: CGFloat = 6, gap: CGFloat = 4, height: CGFloat = 18
        let size = NSSize(width: pad + eye.size.width + gap + text.size().width + pad, height: height)
        let img = NSImage(size: size, flipped: false) { rect in
            NSColor.systemRed.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5).fill()
            eye.draw(in: NSRect(x: pad, y: (height - eye.size.height) / 2,
                                width: eye.size.width, height: eye.size.height))
            text.draw(at: NSPoint(x: pad + eye.size.width + gap, y: (height - text.size().height) / 2))
            return true
        }
        img.isTemplate = false
        img.accessibilityDescription = "シークレットモード オン"
        return img
    }

    @objc func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp
            || NSApp.currentEvent?.modifierFlags.contains(.control) == true {
            let menu = NSMenu()
            menu.addItem(withTitle: on ? "シークレットモード: オン" : "シークレットモード: オフ", action: nil, keyEquivalent: "")
            menu.addItem(.separator())
            menu.addItem(withTitle: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            item.menu = menu
            item.button?.performClick(nil)
            item.menu = nil
            return
        }
        if busy { return }
        busy = true
        draw()
        DispatchQueue.global().async {
            _ = self.run("toggle")
            DispatchQueue.main.async {
                self.busy = false
                self.refresh(force: true)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
