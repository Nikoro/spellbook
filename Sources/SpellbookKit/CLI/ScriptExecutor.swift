public struct ScriptExecutor {
    private let processRunner: ProcessRunner

    public init(processRunner: ProcessRunner) {
        self.processRunner = processRunner
    }

    @discardableResult
    public func execute(
        script: String,
        shell: String? = nil,
        environment: [String: String]? = nil,
        workingDirectory: String? = nil
    ) throws -> Int32 {
        let shellName = shell ?? ShellDefaults.shell
        return try processRunner.run(
            executablePath: "/usr/bin/env",
            arguments: [shellName, "-c", script],
            environment: environment,
            workingDirectory: workingDirectory
        )
    }
}
