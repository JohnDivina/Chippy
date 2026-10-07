import SwiftUI
import SpriteKit

/// `NSViewRepresentable` wrapping `SKView` with fine-grained control over occlusion,
/// pauses, Metal draw call batching, and energy-efficient frame rates.
public struct ParadiseSKView: NSViewRepresentable {
    public let scene: SKScene
    public let governor: RenderGovernor

    public init(scene: SKScene, governor: RenderGovernor) {
        self.scene = scene
        self.governor = governor
    }

    public func makeNSView(context: Context) -> SKView {
        let skView = SKView()
        skView.ignoresSiblingOrder = true
        skView.shouldCullNonVisibleNodes = true
        skView.preferredFramesPerSecond = 60
        skView.presentScene(scene)

        governor.attach(skView: skView, scene: scene)
        return skView
    }

    public func updateNSView(_ nsView: SKView, context: Context) {
        if nsView.scene !== scene {
            nsView.presentScene(scene)
            governor.attach(skView: nsView, scene: scene)
        }
        if nsView.bounds.size != scene.size && nsView.bounds.width > 0 && nsView.bounds.height > 0 {
            scene.size = nsView.bounds.size
        }
    }
}
