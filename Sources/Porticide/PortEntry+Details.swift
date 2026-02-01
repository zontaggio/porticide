import Foundation

extension PortEntry {
    var displayName: String {
        ServiceClassifier.classify(commandLine: commandLine).displayName
    }

    var detail: String? {
        ServiceClassifier.classify(commandLine: commandLine).detail
    }

    var iconName: String {
        ServiceClassifier.classify(commandLine: commandLine).iconName
    }
}
