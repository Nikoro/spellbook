import Foundation

enum SpellbookAppHelp {
    struct Context {
        let resolver: ActivationResolver
        let cwd: String
        let renderError: (Error) -> String
        let fail: (String) -> Never
    }

    static func show(arguments: [String], context: Context) {
        guard let spellName = arguments.first else { print(RootHelp.render()); return }
        do {
            let result = try context.resolver.resolve(cwd: context.cwd)
            let lookup = SpellLookup()
            guard let spell = lookup.find(name: spellName, in: result.manifest) else {
                context.fail(context.renderError(SpellbookError.spellNotFound(name: spellName)))
            }
            let isAlias = spell.name != spellName
            if isAlias {
                print(HelpGenerator.aliasHelp(name: spellName, canonical: spell))
            } else {
                print(HelpGenerator.spellHelp(spell))
            }
        } catch {
            context.fail(context.renderError(error))
        }
    }
}
