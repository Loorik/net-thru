import AppKit

/// Contents of the menu bar item: a mirrored bar graph of the last few seconds, followed by the
/// current upload and download rates.
package final class StatusView: NSView {
    package var samples: [TrafficSample] = [] {
        didSet { redrawIfChanged(from: oldValue) }
    }

    /// Clicks go to the status item's button underneath, which opens the menu.
    override package func hitTest(_ point: NSPoint) -> NSView? { nil }

    override package func viewDidChangeEffectiveAppearance() {
        needsDisplay = true
    }

    override package func viewDidChangeBackingProperties() {
        needsDisplay = true
    }

    override package func draw(_ dirtyRect: NSRect) {
        let midline = Midline(centeredIn: bounds, backingScale: backingScale)
        TrafficGraph(samples: samples, midline: midline).draw()
        let latest = samples.last ?? .idle
        for direction in TrafficDirection.allCases {
            RateLabel(direction: direction, rate: latest.rate(direction), midline: midline).draw(rightEdge: bounds.maxX)
        }
    }

    private var backingScale: CGFloat {
        window?.backingScaleFactor ?? StatusLayout.defaultBackingScale
    }

    private func redrawIfChanged(from oldSamples: [TrafficSample]) {
        if samples != oldSamples { needsDisplay = true }
    }
}
