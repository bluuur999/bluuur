import Foundation
import CoreGraphics

// Keep real click targets aligned while the pointer is in use.
struct MouseInteraction {
    private var previous: CGPoint?
    private var lastUse = -Double.greatestFiniteMagnitude
    private var lastUpdate: Double?
    private(set) var factor = 1.0

    mutating func update(position: CGPoint, buttonsDown: Bool, now: Double,
                         enabled: Bool, inSettings: Bool) -> Double {
        let moved = previous.map { hypot(position.x - $0.x, position.y - $0.y) > 1 } ?? false
        previous = position
        if enabled && !inSettings && (moved || buttonsDown) { lastUse = now }
        let active = enabled && now - lastUse < 1
        let dt = min(0.1, max(0, now - (lastUpdate ?? now)))
        lastUpdate = now
        // Flatten promptly for clicks; bring depth back gently after mouse use.
        let duration = active ? 0.06 : 0.32
        factor += ((active ? 0 : 1) - factor) * (1 - exp(-dt / duration))
        if factor < 0.005 { factor = 0 }
        return factor
    }
}
