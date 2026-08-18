# Installation

SwiftUI Semantic Audit currently ships from source. A complete installation places one CLI binary on `PATH` and exposes four sibling skill directories to the local coding-agent host.

## Requirements

- macOS 13 or later;
- a Swift 6.3-compatible toolchain;
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

## Agent-assisted installation

The recommended installer is the copy-paste prompt in the [root README](../../README.md#install-with-your-coding-agent). It tells the current agent to:

- clone the public repository into a stable user-owned location;
- record the exact commit because there is no release tag;
- build with the committed `Package.resolved` file;
- install the CLI without `sudo`;
- detect Codex or Claude Code and use its documented personal skill directory;
- symlink all four skills without overwriting anything;
- verify the binary, router links, and `doctor` output.

The prompt stops on conflicts. This protects an existing install from being silently replaced.

## Manual CLI installation

Choose an empty stable source directory and a user-owned bin directory. This block runs in a subshell and exits before cloning or installing when either destination already exists:

```bash
(
  set -euo pipefail
  install_root="$HOME/.local/share/swiftui-semantic-audit"
  bin_dir="$HOME/.local/bin"

  test ! -e "$install_root" && test ! -L "$install_root"
  test ! -e "$bin_dir/swiftui-audit" && test ! -L "$bin_dir/swiftui-audit"

  git clone https://github.com/potapenko/swiftui-semantic-audit.git "$install_root"
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
  install_root="$HOME/.local/share/swiftui-semantic-audit"
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

## Updating an unreleased install

Treat the recorded Git commit as the installed version. Before updating, inspect local changes and existing destinations. Do not pull over a modified clone or overwrite a binary blindly. A safe update should select a new commit explicitly, rebuild with locked dependencies, verify it, and replace the old installation only as an intentional operator action.

Until tagged artifacts exist, installation receipts are the reliable way to reproduce or roll back an environment.

## Uninstalling

Removal is intentionally not automated by this project. The source clone, binary, and four host links are separate paths; inspect each one before deleting it. This avoids removing a shared clone or a path that another tool now owns.

Next: [Run a first audit](first-audit.md).
