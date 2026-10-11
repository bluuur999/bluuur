// Modified for bluuur 2.0.3: exact integration stays stable after dropped frames.
import Foundation

/// Turns the sensor's 10 Hz steps into a value that changes smoothly at the
/// display refresh rate.
///
/// The exact critically damped solution is stable even after a missed frame.
struct CriticallyDampedSpring {
    var value: Double
    var velocity: Double = 0

    /// Radians per second. Higher follows the target faster and smooths less.
    var frequency: Double = 20
    private var waitingForFirstPicture = false

    init(value: Double = 0) {
        self.value = value
    }

    mutating func advance(to target: Double, dt: Double, pictureReady: Bool = true) {
        if waitingForFirstPicture {
            guard pictureReady else { return }
            waitingForFirstPicture = false
            return
        }
        let elapsed = max(dt, 0)
        let offset = value - target
        let rate = velocity + frequency * offset
        let decay = exp(-frequency * elapsed)
        value = target + (offset + rate * elapsed) * decay
        velocity = (velocity - frequency * rate * elapsed) * decay
    }

    mutating func reset(to newValue: Double) {
        value = newValue
        velocity = 0
        waitingForFirstPicture = false
    }

    mutating func beginEntry(at threshold: Double) {
        reset(to: threshold)
        waitingForFirstPicture = true
    }
}
