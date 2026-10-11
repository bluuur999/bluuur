// Exercise failed startup and retry using injected enumeration, without recording.
import AppKit
import Metal
import ScreenCaptureKit

@main
struct StreamRecoveryCheck {
    @MainActor static func main() async throws {
        var attempts = 0
        let streamer = ScreenStreamer(shareableContent: {
            attempts += 1
            throw NSError(domain: "bluuur.test.enumeration", code: 1)
        })
        streamer.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        precondition(attempts == 1 && !streamer.isStarted, "failed enumeration must release startup state")
        streamer.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        precondition(attempts == 1, "retries must back off instead of flooding the capture service")
        try await Task.sleep(nanoseconds: 500_000_000)
        streamer.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        precondition(attempts == 2 && !streamer.isStarted, "a second attempt must be possible")
        streamer.stop()
        try await Task.sleep(nanoseconds: 550_000_000)
        streamer.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        precondition(attempts == 3 && !streamer.isStarted)
        print("OK: failed capture startup recovers; retry backoff and repeat attempts work")
    }
}
