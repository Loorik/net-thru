// Renders the README animation: the app's real StatusView, fed a scripted traffic sequence,
// inside a mock menu bar. Writes demo-light.gif and demo-dark.gif into the given directory.
// Usage (see `make demo`): swift run MakeDemo <output directory>
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
for theme in [Theme.light, Theme.dark] {
    try DemoAnimation(script: ReadmeTraffic.script, theme: theme).write(to: outputDirectory)
}
