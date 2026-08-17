import AuditCore

public struct CheckPolicy: Sendable {
    public init() {}

    public func evaluate(diff: SemanticDiffReport, failOnNew threshold: Severity) -> CheckReport {
        CheckReport(diff: diff, threshold: threshold)
    }

    public func humanDescription(_ report: CheckReport) -> String {
        var lines = [
            report.passed ? "Check passed" : "Check failed",
            "New findings: \(report.totalNewFindings)",
            "At or above \(report.threshold.rawValue): \(report.failingFindings.count)",
        ]
        for finding in report.failingFindings {
            lines.append("\(finding.severity.rawValue) \(finding.rule.rawValue) \(finding.id)")
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
