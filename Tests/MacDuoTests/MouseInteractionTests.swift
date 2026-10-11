import Foundation
import CoreGraphics
import Testing
@testable import MacDuo

struct MouseInteractionTests {
    @Test func pointerFlattensThenRestores() {
        var mouse = MouseInteraction()
        #expect(mouse.update(position: CGPoint(x: 0, y: 0), buttonsDown: false, now: 0, enabled: true, inSettings: false) == 1)
        for step in 1...10 {
            _ = mouse.update(position: CGPoint(x: Double(step * 2), y: 0), buttonsDown: false,
                now: Double(step) / 10, enabled: true, inSettings: false)
        }
        #expect(mouse.factor == 0)
        for step in 11...35 {
            _ = mouse.update(position: CGPoint(x: 20, y: 0), buttonsDown: false,
                now: Double(step) / 10, enabled: true, inSettings: false)
        }
        #expect(mouse.factor > 0.99)
    }

    @Test func settingsAndDisabledModePreservePerspective() {
        for (enabled, inSettings) in [(true, true), (false, false)] {
            var mouse = MouseInteraction()
            for step in 0...10 {
                let factor = mouse.update(position: CGPoint(x: Double(step * 4), y: 0), buttonsDown: true,
                    now: Double(step) / 10, enabled: enabled, inSettings: inSettings)
                #expect(factor == 1)
            }
        }
    }

    @Test func testDepthReturnsGraduallyAfterMouseStops() {
        var mouse = MouseInteraction()
        for step in 0...60 {
            _ = mouse.update(position: CGPoint(x: Double(step * 2), y: 0), buttonsDown: false,
                now: Double(step) / 60, enabled: true, inSettings: false)
        }
        #expect(mouse.factor == 0)
        for step in 61...119 {
            _ = mouse.update(position: CGPoint(x: 120, y: 0), buttonsDown: false,
                now: Double(step) / 60, enabled: true, inSettings: false)
        }
        let first = mouse.update(position: CGPoint(x: 120, y: 0), buttonsDown: false,
            now: 2, enabled: true, inSettings: false)
        #expect(first > 0 && first < 0.06)
        for step in 121...131 {
            _ = mouse.update(position: CGPoint(x: 120, y: 0), buttonsDown: false,
                now: Double(step) / 60, enabled: true, inSettings: false)
        }
        #expect(mouse.factor > 0.4 && mouse.factor < 0.5)
    }
}
