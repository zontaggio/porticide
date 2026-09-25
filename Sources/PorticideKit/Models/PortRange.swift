public enum PortRange {
    public static let valid: ClosedRange<Int> = 1...65535

    /// Builds a scan range from two user-entered bounds, clamped to valid
    /// ports and accepted in either order.
    public static func normalized(_ first: Int, _ second: Int) -> ClosedRange<Int> {
        let a = first.clamped(to: valid)
        let b = second.clamped(to: valid)
        return min(a, b)...max(a, b)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
