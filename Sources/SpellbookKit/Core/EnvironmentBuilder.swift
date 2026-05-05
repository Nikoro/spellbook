public struct EnvironmentBuilder {
    public struct Context: Equatable {
        public let spellName: String
        public let projectRoot: String
        public let manifestPath: String
        public let originPath: String
        public let workingDir: String

        public init(
            spellName: String,
            projectRoot: String,
            manifestPath: String,
            originPath: String,
            workingDir: String
        ) {
            self.spellName = spellName
            self.projectRoot = projectRoot
            self.manifestPath = manifestPath
            self.originPath = originPath
            self.workingDir = workingDir
        }
    }

    public init() {}

    public func build(_ context: Context) -> [String: String] {
        [
            "SPELLBOOK_SPELL_NAME": context.spellName,
            "SPELLBOOK_PROJECT_ROOT": context.projectRoot,
            "SPELLBOOK_MANIFEST_PATH": context.manifestPath,
            "SPELLBOOK_ORIGIN_PATH": context.originPath,
            "SPELLBOOK_WORKING_DIR": context.workingDir
        ]
    }
}
