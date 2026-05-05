enum ParamAttributesReader {
    static func read(_ node: YAMLNode) -> ParamAttributes {
        guard case .map(let entries) = node else { return ParamAttributes() }
        var attributes = ParamAttributes()
        for entry in entries {
            absorb(entry, into: &attributes)
        }
        return attributes
    }

    private static func absorb(_ entry: MapEntry, into attributes: inout ParamAttributes) {
        switch entry.key {
        case "description":
            attributes.description = entry.value.scalar
        case "flags":
            attributes.flags = ScalarListReader.read(entry.value)
        case "default":
            attributes.defaultValue = entry.value.scalar
        case "type":
            attributes.type = ParamTypeReader.read(entry.value)
        case "values":
            attributes.values = ScalarListReader.read(entry.value)
        default:
            break
        }
    }
}
