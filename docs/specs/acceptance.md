# Acceptance and QA contract

- Node type: branch
- Status: Active
- Contract revision: `spec-10`
- Read when: selecting fixture, build, determinism, safety, dogfood, skill, CI, or completion obligations.
- Do not read when: the task does not implement or verify accepted behavior.
- Maximum size: 100 physical lines.

Revision: `spec-10`
Status: active  
Release state: 0.4.0 released

## Choose the governing child

- [Fixture, Build, and Safety Acceptance](acceptance/fixtures-build-and-safety.md) — mandatory fixtures, test milestones, cache determinism, snapshot safety, and revision loading.
- [Reusable Component Surface Acceptance](acceptance/component-surface.md) — exact role/config compatibility, positive/negative boundaries, dominance, slice, and realistic/indexed parity.
- [CLI Dogfood, Skills, and CI Acceptance](acceptance/dogfood-skills-and-ci.md) — release-path commands, four skill workflows, and hosted CI obligations.
- [Definition of Done](acceptance/definition-of-done.md) — accepted product, schema, rule, fixture, workflow, and cache completion states.
