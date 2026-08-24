# Installation

SwiftUI Semantic Audit 0.6.0 installs the CLI through the upstream Homebrew tap. A local Codex or Claude Code agent can follow this page end to end. Homebrew and the four agent skills remain separately owned and are pinned to the same immutable release.

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

The version command must report `0.6.0`. `doctor` checks environment readiness;
it accepts neither `--index-store` nor `--config`, and it does not prove that a
watcher snapshot is fresh. `project status --wait indexed` provides that receipt.

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
  install_root="$HOME/.local/share/swiftui-semantic-audit/0.6.0"
  repository="https://github.com/potapenko/swiftui-semantic-audit.git"

  test ! -e "$install_root" && test ! -L "$install_root"
  git clone --branch 0.6.0 --depth 1 "$repository" "$install_root"
  cd "$install_root"
  test "$(git remote get-url origin)" = "$repository"
  test "$(git describe --tags --exact-match HEAD)" = "0.6.0"
  test "$(git rev-parse HEAD)" = "$(git rev-list -n 1 0.6.0)"
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
  install_root="$HOME/.local/share/swiftui-semantic-audit/0.6.0"
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
  install_root="$HOME/.local/share/swiftui-semantic-audit/0.6.0"
  bin_dir="$HOME/.local/bin"

  test -d "$install_root/.git"
  test "$(git -C "$install_root" describe --tags --exact-match HEAD)" = "0.6.0"
  test "$(git -C "$install_root" rev-parse HEAD)" = \
    "$(git -C "$install_root" rev-list -n 1 0.6.0)"
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
skill_root="$HOME/.agents/skills" # Use "$HOME/.claude/skills" for Claude Code.
test "$(swiftui-audit --version)" = "0.6.0"
swiftui-audit --help
swiftui-audit doctor . --format json
```

Confirm each link resolves:

```bash
skill_root="$HOME/.agents/skills" # Use "$HOME/.claude/skills" for Claude Code.
for skill in swiftui-semantic swiftui-semantic-audit swiftui-dataflow-refactor swiftui-change-review; do
  test -f "$skill_root/$skill/SKILL.md"
done
```

Use the router for normal work:

- Codex: `$swiftui-semantic`
- Claude Code: `/swiftui-semantic`

The specialists remain directly invocable for advanced use, but installing only the router is incomplete.

For project instructions, audits, focused refactors, change reviews, and staged migrations, continue with the [agent prompt library](agent-prompts.md).

## Updating an existing installation

This immutable guide updates an existing installation to `0.6.0`. Do not pull
an existing skill clone across release tags or replace destinations blindly.
The CLI and skills remain separate ownership phases even though the completed
installation must resolve to one release.

First select the agent host and inspect all current destinations. Use the
Claude Code skill root instead when appropriate:

```bash
skill_root="$HOME/.agents/skills"
printf 'CLI: '
swiftui-audit --version
for skill in swiftui-semantic swiftui-semantic-audit swiftui-dataflow-refactor swiftui-change-review; do
  destination="$skill_root/$skill"
  test -L "$destination"
  printf '%s -> %s\n' "$skill" "$(readlink "$destination")"
  test -f "$destination/SKILL.md"
done
```

Stop if any destination is missing, is not a symlink, or does not contain the
expected `SKILL.md`. Resolve that ownership conflict instead of overwriting it.

Update and verify the Homebrew-owned CLI:

```bash
brew update
brew upgrade potapenko/tap/swiftui-semantic-audit
test "$(swiftui-audit --version)" = "0.6.0"
```

Prepare the new immutable skill source in its own versioned directory. An
existing directory is accepted only when it is already the exact release:

```bash
(
  set -euo pipefail
  install_root="$HOME/.local/share/swiftui-semantic-audit/0.6.0"
  repository="https://github.com/potapenko/swiftui-semantic-audit.git"

  test ! -L "$install_root"
  if test -e "$install_root"; then
    test -d "$install_root/.git"
  else
    git clone --branch 0.6.0 --depth 1 "$repository" "$install_root"
  fi

  test "$(git -C "$install_root" remote get-url origin)" = "$repository"
  test "$(git -C "$install_root" describe --tags --exact-match HEAD)" = "0.6.0"
  test "$(git -C "$install_root" rev-parse HEAD)" = \
    "$(git -C "$install_root" rev-list -n 1 0.6.0)"
  for skill in swiftui-semantic swiftui-semantic-audit swiftui-dataflow-refactor swiftui-change-review; do
    test -f "$install_root/skills/$skill/SKILL.md"
  done
)
```

Repoint all four sibling links in one guarded operation. The preflight accepts
only links created by this versioned installation layout:

```bash
(
  set -euo pipefail
  install_root="$HOME/.local/share/swiftui-semantic-audit/0.6.0"
  skill_root="$HOME/.agents/skills" # Use "$HOME/.claude/skills" for Claude Code.

  for skill in swiftui-semantic swiftui-semantic-audit swiftui-dataflow-refactor swiftui-change-review; do
    destination="$skill_root/$skill"
    test -L "$destination"
    case "$(readlink "$destination")" in
      "$HOME/.local/share/swiftui-semantic-audit/"*/skills/"$skill") ;;
      *) printf 'Unexpected skill owner: %s\n' "$destination" >&2; exit 1 ;;
    esac
    test -f "$install_root/skills/$skill/SKILL.md"
  done

  for skill in swiftui-semantic swiftui-semantic-audit swiftui-dataflow-refactor swiftui-change-review; do
    ln -sfn "$install_root/skills/$skill" "$skill_root/$skill"
  done
)
```

Verify the shared release before reporting success:

```bash
install_root="$HOME/.local/share/swiftui-semantic-audit/0.6.0"
skill_root="$HOME/.agents/skills" # Use "$HOME/.claude/skills" for Claude Code.
test "$(swiftui-audit --version)" = "0.6.0"
for skill in swiftui-semantic swiftui-semantic-audit swiftui-dataflow-refactor swiftui-change-review; do
  test "$(readlink "$skill_root/$skill")" = "$install_root/skills/$skill"
  test -f "$skill_root/$skill/SKILL.md"
done
```

Keep the previous immutable clone until the updated CLI and all four links
have passed verification. Remove it later only after confirming that no other
host or link still uses it.

## Uninstalling

Homebrew owns CLI removal. The optional source clone and four host links remain separate operator-owned paths; inspect each before deleting it so a shared clone or repurposed path is not removed accidentally.

Next: [Run a first audit](first-audit.md).
