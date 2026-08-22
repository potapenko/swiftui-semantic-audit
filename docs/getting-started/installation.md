# Installation

SwiftUI Semantic Audit 0.5.0 installs the CLI through the upstream Homebrew tap. A local Codex or Claude Code agent can follow this page end to end. Homebrew and the four agent skills remain separately owned and are pinned to the same immutable release.

## Requirements

- macOS 13 or later;
- Homebrew for the packaged CLI path;
- a Swift 6.3-compatible toolchain for source builds and indexed analysis;
- Xcode command-line tools for indexed analysis;
- Git;
- a local Codex or Claude Code session for the bundled agent workflow.

Check the machine first:

```bash
sw_vers
swift --version
xcode-select -p
git --version
```

If `brew --version` fails, install Homebrew by following the current official
instructions at [brew.sh](https://brew.sh/), then verify `brew --version`
before continuing.

## Homebrew CLI installation

Install directly from the upstream tap without a separate `brew tap` command:

```bash
brew install potapenko/tap/swiftui-semantic-audit
swiftui-audit --version
swiftui-audit doctor . --format json
```

The formula owns only the CLI under Homebrew's prefix. It does not install the four agent skills or edit user configuration.

Update or remove the CLI through the same fully qualified formula:

```bash
brew upgrade potapenko/tap/swiftui-semantic-audit
brew uninstall potapenko/tap/swiftui-semantic-audit
```

## Agent skill installation

Homebrew does not contain the skills. After the CLI passes, clone the immutable
release into a stable user-owned directory. This step does not build or install
another CLI. It stops if the destination exists and verifies the release commit:

```bash
(
  set -euo pipefail
  install_root="$HOME/.local/share/swiftui-semantic-audit/0.5.0"
  repository="https://github.com/potapenko/swiftui-semantic-audit.git"
  expected_commit="e460237d1175a0007c6cf91af34898637fdeedb2"

  test ! -e "$install_root" && test ! -L "$install_root"
  git clone --branch 0.5.0 --depth 1 "$repository" "$install_root"
  cd "$install_root"
  test "$(git remote get-url origin)" = "$repository"
  test "$(git rev-parse HEAD)" = "$expected_commit"
)
```

The repository contains one router and three specialists:

```text
swiftui-semantic
swiftui-semantic-audit
swiftui-dataflow-refactor
swiftui-change-review
```

They must remain siblings because the router uses relative links to the specialists.

For Codex, use the personal skill root documented by OpenAI:

```bash
skill_root="$HOME/.agents/skills"
```

For Claude Code, use its personal skill root:

```bash
skill_root="$HOME/.claude/skills"
```

Preflight every target before creating any link, then create all four as one operation. Replace the `skill_root` assignment with the Claude Code path when appropriate:

```bash
(
  set -euo pipefail
  install_root="$HOME/.local/share/swiftui-semantic-audit/0.5.0"
  skill_root="$HOME/.agents/skills"

  for skill in swiftui-semantic swiftui-semantic-audit swiftui-dataflow-refactor swiftui-change-review; do
    test ! -e "$skill_root/$skill" && test ! -L "$skill_root/$skill"
  done

  mkdir -p "$skill_root"
  for skill in swiftui-semantic swiftui-semantic-audit swiftui-dataflow-refactor swiftui-change-review; do
    ln -s "$install_root/skills/$skill" "$skill_root/$skill"
  done
)
```

Both [Codex](https://learn.chatgpt.com/docs/build-skills) and [Claude Code](https://code.claude.com/docs/en/skills) document symlinked personal skill directories. Restart the host only if the new top-level skill directory is not detected in the current session.

## Locked source fallback

Use this only when the Homebrew CLI path is unavailable. It builds the CLI from
the same verified release clone without changing the four skill links. Choose a
user-owned bin directory and stop if the executable destination already exists:

```bash
(
  set -euo pipefail
  install_root="$HOME/.local/share/swiftui-semantic-audit/0.5.0"
  bin_dir="$HOME/.local/bin"

  test -d "$install_root/.git"
  test "$(git -C "$install_root" rev-parse HEAD)" = \
    "e460237d1175a0007c6cf91af34898637fdeedb2"
  test ! -e "$bin_dir/swiftui-audit" && test ! -L "$bin_dir/swiftui-audit"

  swift build --package-path "$install_root" -c release \
    --disable-automatic-resolution
  mkdir -p "$bin_dir"
  install -m 0755 "$install_root/.build/release/swiftui-audit" \
    "$bin_dir/swiftui-audit"
)
```

If that directory is not already on `PATH`, add it for the current shell before verification:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Decide separately whether to persist that line in the appropriate shell configuration file.

## Verify

```bash
swiftui-audit --help
swiftui-audit doctor . --format json
```

Confirm each link resolves:

```bash
for skill in swiftui-semantic swiftui-semantic-audit swiftui-dataflow-refactor swiftui-change-review; do
  test -f "$skill_root/$skill/SKILL.md"
done
```

Use the router for normal work:

- Codex: `$swiftui-semantic`
- Claude Code: `/swiftui-semantic`

The specialists remain directly invocable for advanced use, but installing only the router is incomplete.

For project instructions, audits, focused refactors, change reviews, and staged migrations, continue with the [agent prompt library](agent-prompts.md).

## Updating skills

Do not pull a skill clone across release tags or replace existing symlinks blindly. Inspect the current clone and destinations, clone the new immutable tag into a new stable path, validate it, then intentionally repoint all four sibling links as one operator action.

## Uninstalling

Homebrew owns CLI removal. The optional source clone and four host links remain separate operator-owned paths; inspect each before deleting it so a shared clone or repurposed path is not removed accidentally.

Next: [Run a first audit](first-audit.md).
