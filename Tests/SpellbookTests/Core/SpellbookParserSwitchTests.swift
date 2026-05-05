import Testing
@testable import SpellbookKit

struct SpellbookParserSwitchTests {
    private let parser = SpellbookParser()

    @Test func switch_singleOption_withScript() throws {
        let spell = try #require(try parseSwitchSpell([
            MapEntry(key: "staging", value: .map([
                MapEntry(key: "script", value: .scalar("./deploy staging"))
            ]))
        ]))

        let branches = try #require(spell.switchBranches)
        #expect(branches.options.map(\.name) == ["staging"])
        #expect(branches.options.first?.command.script == "./deploy staging")
        #expect(branches.defaultBranch == .none)
    }

    @Test func switch_optionWithAliases_areParsed() throws {
        let spell = try #require(try parseSwitchSpell([
            MapEntry(key: "production", value: .map([
                MapEntry(key: "aliases", value: .sequence([
                    .scalar("-p"), .scalar("--prod"), .scalar("prod")
                ])),
                MapEntry(key: "script", value: .scalar("./deploy production"))
            ]))
        ]))

        let option = try #require(spell.switchBranches?.options.first)
        #expect(option.name == "production")
        #expect(option.aliases == ["-p", "--prod", "prod"])
        #expect(option.command.script == "./deploy production")
    }

    @Test func switch_defaultAsString_pointsToOptionKey() throws {
        let spell = try #require(try parseDeploySpell([
            MapEntry(key: "switch", value: .map([
                MapEntry(key: "staging", value: .map([
                    MapEntry(key: "script", value: .scalar("./deploy staging"))
                ])),
                MapEntry(key: "production", value: .map([
                    MapEntry(key: "script", value: .scalar("./deploy production"))
                ]))
            ])),
            MapEntry(key: "default", value: .scalar("production"))
        ]))

        let branches = try #require(spell.switchBranches)
        #expect(branches.defaultBranch == .key("production"))
    }

    @Test func switch_defaultAsInlineMap_becomesInlineCommand() throws {
        let spell = try #require(try parseDeploySpell([
            MapEntry(key: "switch", value: .map([
                MapEntry(key: "staging", value: .map([
                    MapEntry(key: "script", value: .scalar("./deploy staging"))
                ]))
            ])),
            MapEntry(key: "default", value: .map([
                MapEntry(key: "script", value: .scalar("./deploy --dry-run"))
            ]))
        ]))

        let branches = try #require(spell.switchBranches)
        guard case .inline(let command) = branches.defaultBranch else {
            Issue.record("expected inline default, got \(branches.defaultBranch)")
            return
        }
        #expect(command.script == "./deploy --dry-run")
    }

    @Test func switch_nestedInsideOption_recurses() throws {
        let spell = try #require(try parseSwitchSpell([
            MapEntry(key: "env", value: .map([
                MapEntry(key: "switch", value: .map([
                    MapEntry(key: "staging", value: .map([
                        MapEntry(key: "script", value: .scalar("./deploy staging"))
                    ])),
                    MapEntry(key: "production", value: .map([
                        MapEntry(key: "script", value: .scalar("./deploy production"))
                    ]))
                ]))
            ]))
        ]))

        let outer = try #require(spell.switchBranches?.options.first)
        #expect(outer.name == "env")
        let inner = try #require(outer.command.switchBranches)
        #expect(inner.options.map(\.name) == ["staging", "production"])
    }

    @Test func switch_scalarOptionShorthand_isTreatedAsScript() throws {
        let spell = try #require(try parseSwitchSpell([
            MapEntry(key: "staging", value: .scalar("./deploy staging"))
        ]))

        let option = try #require(spell.switchBranches?.options.first)
        #expect(option.name == "staging")
        #expect(option.command.script == "./deploy staging")
    }

    @Test func switch_coexistsWithParams_isError() {
        let error = #expect(throws: SpellbookError.self) {
            try parseDeploySpell([
                MapEntry(key: "params", value: .map([
                    MapEntry(key: "target", value: .map([
                        MapEntry(key: "default", value: .scalar("./out"))
                    ]))
                ])),
                MapEntry(key: "switch", value: .map([
                    MapEntry(key: "staging", value: .map([
                        MapEntry(key: "script", value: .scalar("./deploy staging"))
                    ]))
                ]))
            ])
        }
        guard case .paramsAndSwitchCoexist(let spell) = error else {
            Issue.record("expected paramsAndSwitchCoexist, got \(String(describing: error))")
            return
        }
        #expect(spell == "deploy")
    }

    @Test func switch_coexistsWithScript_isError() {
        let error = #expect(throws: SpellbookError.self) {
            try parseDeploySpell([
                MapEntry(key: "script", value: .scalar("./deploy")),
                MapEntry(key: "switch", value: .map([
                    MapEntry(key: "staging", value: .map([
                        MapEntry(key: "script", value: .scalar("./deploy staging"))
                    ]))
                ]))
            ])
        }
        guard case .scriptAndSwitchCoexist(let spell) = error else {
            Issue.record("expected scriptAndSwitchCoexist, got \(String(describing: error))")
            return
        }
        #expect(spell == "deploy")
    }

    private func parseSwitchSpell(_ options: [MapEntry]) throws -> SpellDefinition? {
        try parseDeploySpell([
            MapEntry(key: "switch", value: .map(options))
        ])
    }

    private func parseDeploySpell(_ fields: [MapEntry]) throws -> SpellDefinition? {
        let node: YAMLNode = .map([
            MapEntry(key: "spells", value: .map([
                MapEntry(key: "deploy", value: .map(fields))
            ]))
        ])
        return try parser.parse(node).spells.first
    }
}
