public enum WrapperContent {
    public static func render(spellName: String) -> String {
        """
        #!/bin/sh
        exec spells run "\(spellName)" --cwd "$PWD" -- "$@"
        """
    }
}
