# Acceptance and QA contract

- Node type: branch
- Status: Active
- Contract revision: `spec-14`
- Read when: selecting fixture, build, determinism, safety, dogfood, skill, CI, or completion obligations.
- Do not read when: the task does not implement or verify accepted behavior.
- Maximum size: 100 physical lines.

Revision: `spec-14`
Status: active  
Release state: 0.5.0 is the current public release and 0.4.0/0.5.0 artifacts are immutable; 0.6.0 is publication-authorized with its terminal receipt pending

## Choose the governing child

- [Fixture, Build, and Safety Acceptance](acceptance/fixtures-build-and-safety.md) — mandatory fixtures, test milestones, cache determinism, snapshot safety, and revision loading.
- [Reusable Component Surface Acceptance](acceptance/component-surface.md) — exact role/config compatibility, positive/negative boundaries, dominance, slice, and realistic/indexed parity.
- [CLI Dogfood, Skills, and CI Acceptance](acceptance/dogfood-skills-and-ci.md) — release-path commands, four skill workflows, and hosted CI obligations.
- [Definition of Done](acceptance/definition-of-done.md) — accepted product, schema, rule, fixture, workflow, and cache completion states.
- [Project Watcher Acceptance](acceptance/project-watcher.md) — setup safety, freshness, lifecycle, indexed snapshots, agent integration, and compatibility.
