import Testing
@testable import SpellbookKit

struct DoctorResolverTests {

    private let resolver = DoctorResolver()
    private let binDir = "/Users/me/.spellbook/bin"

    // MARK: - Manifest checks

    @Test func validManifest_producesInfoItem() {
        let result = makeResult(spellCount: 2, path: "/project/spells.yaml")
        let report = diagnose(result: result, pathEnv: binDir + ":/usr/bin")
        let items = report.items.filter { $0.category == .manifest }
        #expect(items.count == 1)
        #expect(items[0].severity == .info)
        #expect(items[0].message.contains("2 spells"))
    }

    @Test func noManifest_producesError() {
        let report = diagnose(error: .noManifestFound, pathEnv: binDir + ":/usr/bin")
        let items = report.items.filter { $0.category == .manifest }
        #expect(items.count == 1)
        #expect(items[0].severity == .error)
        #expect(report.hasErrors)
    }

    @Test func shadowsHidden_producesWarning() {
        let location = ManifestLocation(
            path: "/project/spells.yaml", source: .project, shadowsHidden: true
        )
        let result = ActivationResult(
            manifest: SpellbookManifest(spells: []),
            location: location,
            chain: ["/project/spells.yaml"]
        )
        let report = diagnose(result: result, pathEnv: binDir + ":/usr/bin")
        let warnings = report.items.filter { $0.severity == .warning && $0.category == .manifest }
        #expect(warnings.count == 1)
        #expect(warnings[0].message.contains(".spells.yaml"))
    }

    // MARK: - Extends checks

    @Test func extendsChain_reportsChain() {
        let result = makeResult(
            spellCount: 1, path: "/project/spells.yaml",
            chain: ["/shared/spells.yaml", "/project/spells.yaml"]
        )
        let report = diagnose(result: result, pathEnv: binDir + ":/usr/bin")
        let items = report.items.filter { $0.category == .extends }
        #expect(items.count == 1)
        #expect(items[0].severity == .info)
        #expect(items[0].message.contains("/shared/spells.yaml"))
    }

    @Test func singleManifest_noExtendsItem() {
        let result = makeResult(spellCount: 1, path: "/project/spells.yaml")
        let report = diagnose(result: result, pathEnv: binDir + ":/usr/bin")
        let items = report.items.filter { $0.category == .extends }
        #expect(items.isEmpty)
    }

    // MARK: - PATH checks

    @Test func pathContainsBinDir_producesInfo() {
        let result = makeResult(spellCount: 0, path: "/p/spells.yaml")
        let report = diagnose(result: result, pathEnv: "/usr/bin:" + binDir)
        let items = report.items.filter { $0.category == .path }
        #expect(items.count == 1)
        #expect(items[0].severity == .info)
    }

    @Test func pathMissingBinDir_producesError() {
        let result = makeResult(spellCount: 0, path: "/p/spells.yaml")
        let report = diagnose(result: result, pathEnv: "/usr/bin:/usr/local/bin")
        let items = report.items.filter { $0.category == .path }
        #expect(items.count == 1)
        #expect(items[0].severity == .error)
        #expect(items[0].message.contains("not in PATH"))
    }

    @Test func pathEnvNil_producesError() {
        let result = makeResult(spellCount: 0, path: "/p/spells.yaml")
        let report = diagnose(result: result, pathEnv: nil)
        let items = report.items.filter { $0.category == .path }
        #expect(items[0].severity == .error)
    }

    // MARK: - Helpers

    private func diagnose(
        result: ActivationResult? = nil,
        error: SpellbookError? = nil,
        pathEnv: String?
    ) -> DoctorReport {
        resolver.diagnose(DoctorInput(
            activationResult: result,
            activationError: error,
            pathEnv: pathEnv,
            spellbookBinDir: binDir,
            stateSnapshot: nil
        ))
    }

    private func makeResult(
        spellCount: Int,
        path: String,
        chain: [String]? = nil
    ) -> ActivationResult {
        let spells = (0..<spellCount).map { index in
            SpellDefinition(
                name: "hello\(index > 0 ? "\(index)" : "")",
                script: "echo"
            )
        }
        return ActivationResult(
            manifest: SpellbookManifest(spells: spells),
            location: ManifestLocation(path: path, source: .project),
            chain: chain ?? [path]
        )
    }
}
