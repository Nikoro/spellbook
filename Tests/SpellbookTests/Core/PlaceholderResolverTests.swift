import Testing
@testable import SpellbookKit

struct PlaceholderResolverTests {
    private let resolver = PlaceholderResolver()

    @Test func knownParamPlaceholders_areShellEscapedAsSingleTokens() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(
                script: nil,
                params: [
                    ParamDefinition(name: "env"),
                    ParamDefinition(name: "message")
                ]
            )
        )
        let arguments = ParsedArguments(
            values: [
                "env": "prod us-east-1",
                "message": "it's $HOME; rm -rf /"
            ]
        )

        let result = resolver.resolve(
            script: "deploy {{env}} --message {{message}}",
            spell: spell,
            arguments: arguments
        )

        #expect(result == "deploy 'prod us-east-1' --message 'it'\\''s $HOME; rm -rf /'")
    }

    @Test func substitution_isSinglePass() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(script: nil, params: [ParamDefinition(name: "template")])
        )
        let arguments = ParsedArguments(values: ["template": "{{env}}"])

        let result = resolver.resolve(
            script: "echo {{template}}",
            spell: spell,
            arguments: arguments
        )

        #expect(result == "echo '{{env}}'")
    }

    @Test func multipleAndRepeatedKnownPlaceholders_areAllResolved() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(
                script: nil,
                params: [
                    ParamDefinition(name: "env"),
                    ParamDefinition(name: "tag")
                ]
            )
        )
        let arguments = ParsedArguments(values: ["env": "prod", "tag": "v1.2.3"])

        let result = resolver.resolve(
            script: "echo {{env}} {{tag}} {{env}}",
            spell: spell,
            arguments: arguments
        )

        #expect(result == "echo 'prod' 'v1.2.3' 'prod'")
    }

    @Test func unknownPlaceholder_remainsUnchanged() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(script: nil, params: [ParamDefinition(name: "env")])
        )

        let result = resolver.resolve(
            script: "echo {{missing}} {{env}}",
            spell: spell,
            arguments: ParsedArguments(values: ["env": "prod"])
        )

        #expect(result == "echo {{missing}} 'prod'")
    }

    @Test func externalTemplateSyntax_withSpacesDotsAndExpressions_isPreserved() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(script: nil, params: [ParamDefinition(name: "env")])
        )

        let result = resolver.resolve(
            script: "echo {{ github.ref }} {{ .Values.image }} {{ user.name }} {{env}}",
            spell: spell,
            arguments: ParsedArguments(values: ["env": "prod"])
        )

        #expect(result == "echo {{ github.ref }} {{ .Values.image }} {{ user.name }} 'prod'")
    }

    @Test func passthroughArgs_areExpandedAsIndividuallyEscapedTokens() {
        let spell = SpellDefinition(name: "wrap")

        let result = resolver.resolve(
            script: "./wrap ...args --done",
            spell: spell,
            arguments: ParsedArguments(
                passthrough: ["--flag", "two words", "it's"]
            )
        )

        #expect(result == "./wrap '--flag' 'two words' 'it'\\''s' --done")
    }

    @Test func emptyPassthrough_removesArgsToken() {
        let spell = SpellDefinition(name: "wrap")

        let result = resolver.resolve(
            script: "./wrap ...args",
            spell: spell,
            arguments: ParsedArguments()
        )

        #expect(result == "./wrap ")
    }

    @Test func missingKnownParamValue_fallsBackToDefaultOrZeroValue() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy"),
            body: SpellBody(
                script: nil,
                params: [
                    ParamDefinition(
                        name: "env",
                        shape: ParamShape(isRequired: false, isPositional: false, flags: ["--env"]),
                        schema: ParamSchema(type: .string, defaultValue: "dev")
                    ),
                    ParamDefinition(
                        name: "count",
                        shape: ParamShape(isRequired: false, isPositional: false, flags: ["--count"]),
                        schema: ParamSchema(type: .int)
                    )
                ]
            )
        )

        let result = resolver.resolve(
            script: "echo {{env}} {{count}}",
            spell: spell,
            arguments: ParsedArguments()
        )

        #expect(result == "echo 'dev' '0'")
    }
}
