// Modified for bluuur 2.0.0: branding, Russian settings, or mouse interaction.
import Foundation
import os

/// Read with:
///
///     log show --last 5m --predicate 'subsystem == "local.lidblur.mac"'
///
/// Notice level, not info: info level lives only in memory, and `log show`
/// reads the on-disk store.
enum Diagnostics {
    static let geometry = Logger(subsystem: "local.lidblur.mac", category: "geometry")
    static let lid = Logger(subsystem: "local.lidblur.mac", category: "lid")
}
