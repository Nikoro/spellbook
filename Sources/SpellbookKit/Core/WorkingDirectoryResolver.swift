public struct WorkingDirectoryResolver {
    public init() {}

    public func resolve(
        workingDir: String?,
        originManifestDir: String,
        invocationCwd: String,
        home: String?
    ) -> String {
        guard let raw = workingDir else {
            return invocationCwd
        }
        if raw.hasPrefix("/") {
            return raw
        }
        if raw == "~" {
            return home ?? raw
        }
        if raw.hasPrefix("~/") {
            guard let home = home else { return raw }
            return home + String(raw.dropFirst())
        }
        return originManifestDir + "/" + raw
    }
}
