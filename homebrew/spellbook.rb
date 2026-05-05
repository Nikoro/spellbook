# Draft Homebrew formula for Spellbook.
#
# Intended location after 1.0: a dedicated tap at `Nikoro/homebrew-spellbook`
# (file path `Formula/spellbook.rb`). While the tap is not published yet this
# draft lives inside the main repo so release tooling can bump `version`,
# `url`, and `sha256` in one place.
#
# Release workflow fills in the SHA256 value from the
# `spells-macos-arm64.sha256` artifact produced by `.github/workflows/release.yml`.
class Spellbook < Formula
  desc "Project-scoped YAML spells turned into shell commands, macOS-first"
  homepage "https://github.com/Nikoro/spellbook"
  version "0.0.0" # bumped by release tooling

  depends_on arch: :arm64
  depends_on :macos

  on_macos do
    on_arm do
      url "https://github.com/Nikoro/spellbook/releases/download/v#{version}/spells-macos-arm64"
      sha256 "REPLACE_WITH_ARM64_SHA256"
    end
  end

  def install
    bin.install "spells-macos-arm64" => "spells"
  end

  def caveats
    <<~CAVEATS
      Spellbook ships a single `spells` binary. To finish setup, add the generated
      wrapper directory to PATH — the binary prints the correct snippet for your
      shell:

        eval "$(spells init zsh)"   # or bash / fish

      Activating in a project directory generates per-spell wrappers under
      $SPELLBOOK_HOME/bin (defaults to ~/.spellbook/bin).
    CAVEATS
  end

  test do
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/spells --version"))
  end
end
