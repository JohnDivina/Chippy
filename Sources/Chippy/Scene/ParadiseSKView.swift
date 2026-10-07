import SwiftUI
import SpriteKit

/// Custom `SKView` subclass that ensures Metal render passes only occur when a valid window and drawable layer exist.
public final class GovernorSKView: SKView {
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            isPaused = false
        } else {
            isPaused = true
        }
    }
}

/// `NSViewRepresentable` wrapping `GovernorSKView` with fine-grained control over occlusion,
/// pauses, Metal draw call batching, and energy-efficient frame rates.
public struct ParadiseSKView: NSViewRepresentable {
    public let scene: SKScene
    public let governor: RenderGovernor

    public init(scene: SKScene, governor: RenderGovernor) {
        self.scene = scene
        self.governor = governor
    }

    public func makeNSView(context: Context) -> GovernorSKView {
        let skView = GovernorSKView()
        skView.isPaused = true // Avoid frame 0 draw call before window attaches
        skView.ignoresSiblingOrder = true
        skView.shouldCullNonVisibleNodes = true
        skView.preferredFramesPerSecond = 60
        skView.presentScene(scene)

        governor.attach(skView: skView, scene: scene)
        return skView
    }

    public func updateNSView(_ nsView: GovernorSKView, context: Context) {
        if nsView.scene !== scene {
            nsView.presentScene(scene)
            governor.attach(skView: nsView, scene: scene)
        }
        if nsView.bounds.size != scene.size && nsView.bounds.width > 0 && nsView.bounds.height > 0 {
            scene.size = nsView.bounds.size
        }
    }
}
