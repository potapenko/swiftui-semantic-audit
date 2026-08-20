# Installation

SwiftUI Semantic Audit 0.5.0 installs the CLI through the upstream Homebrew tap. Agent skills are optional, remain a separate operator-owned step, and are pinned to the same immutable release tag.

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

## Agent-assisted skill installation

The recommended skill installer is the [copy-paste recipe in the agent prompt library](agent-prompts.md#install-the-agent-skills). It tells the current agent to:

- clone the immutable `0.5.0` tag into a stable user-owned location;
- verify the exact tag and commit;
- verify the Homebrew-installed CLI version;
- detect Codex or Claude Code and use its documented personal skill directory;
- symlink all four skills without overwriting anything;
- verify the binary, router links, and `doctor` output.

The prompt stops on conflicts. This protects an existing install from being silently replaced.

## Locked source fallback

Choose an empty stable source directory and a user-owned bin directory. This block runs in a subshell and exits before cloning or installing when either destination already exists:

```bash
(
  set -euo pipefail
  install_root="$HOME/.local/share/swiftui-semantic-audit/0.5.0"
  bin_dir="$HOME/.local/bin"

  test ! -e "$install_root" && test ! -L "$install_root"
  test ! -e "$bin_dir/swiftui-audit" && test ! -L "$bin_dir/swiftui-audit"

  git clone --branch 0.5.0 --depth 1 \
    https://github.com/potapenko/swiftui-semantic-audit.git "$install_root"
  cd "$install_root"
  git rev-parse HEAD
  git remote get-url origin
  swift build -c release --disable-automatic-resolution

  mkdir -p "$bin_dir"
  install -m 0755 .build/release/swiftui-audit "$bin_dir/swiftui-audit"
)
```

If that directory is not already on `PATH`, add it for the current shell before verification:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Decide separately whether to persist that line in the appropriate shell configuration file.

## Manual skill installation

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
