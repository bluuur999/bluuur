import Testing
@testable import MacDuo

struct EffectEntryTests {
    @Test func testDelayedCaptureStillStartsFlat() {
        var spring = CriticallyDampedSpring()
        spring.beginEntry(at: 90)
        for _ in 0..<120 {
            spring.advance(to: 50, dt: 1.0 / 60, pictureReady: false)
        }
        #expect(spring.value == 90 && spring.velocity == 0)
        spring.advance(to: 50, dt: 1.0 / 60, pictureReady: true)
        #expect(spring.value == 90)
        var previous = spring.value
        for _ in 0..<120 {
            spring.advance(to: 50, dt: 1.0 / 60)
            #expect(spring.value <= previous && spring.value >= 50)
            #expect(previous - spring.value < 5.5)
            previous = spring.value
        }
        #expect(abs(spring.value - 50) < 0.01)
    }

    @Test func testNewEntryAndCancelledEntryClearOldMotion() {
        var spring = CriticallyDampedSpring(value: 40)
        spring.velocity = -200
        spring.beginEntry(at: 90)
        #expect(spring.value == 90 && spring.velocity == 0)
        spring.reset(to: 90)
        spring.advance(to: 80, dt: 1.0 / 60)
        #expect(spring.value < 90)
    }
    @Test func testDroppedFramesDoNotReverseOrOvershoot() {
        for interval in [1.0/120, 1.0/60, 1.0/20, 0.1, 0.25] {
            var spring = CriticallyDampedSpring(value: 130)
            var previous = spring.value
            for _ in 0..<120 {
                spring.advance(to: 70, dt: interval)
                #expect(spring.value <= previous && spring.value >= 70)
                #expect(spring.value.isFinite && spring.velocity.isFinite)
                previous = spring.value
            }
            #expect(abs(spring.value - 70) < 0.01)
        }
    }

    @Test func testAnimationRespondsWithinTwoHundredMilliseconds() {
        var spring = CriticallyDampedSpring(value: 90)
        for _ in 0..<12 { spring.advance(to: 50, dt: 1.0/60) }
        #expect(spring.value < 54)
    }

}
