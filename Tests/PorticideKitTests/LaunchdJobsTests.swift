import Testing
@testable import PorticideKit

struct LaunchdJobsTests {
    @Test func parsesRunningJobsByPID() {
        let output = """
        PID\tStatus\tLabel
        30469\t0\tai.openclaw.gateway
        -\t0\tcom.apple.SafariHistoryServiceAgent
        812\t0\thomebrew.mxcl.postgresql@17
        """

        #expect(LaunchdJobs.parse(output) == [30469: "ai.openclaw.gateway", 812: "homebrew.mxcl.postgresql@17"])
    }

    @Test func ignoresMalformedRows() {
        #expect(LaunchdJobs.parse("garbage\n\n12 0").isEmpty)
    }
}
