# Research Hub

The GitHub repository backing the Deep Research Managed Agent. It plays two roles:

1. **Skill source.** Every Managed Agents session mounts this repo. Skills under
   `.claude/skills/<name>/SKILL.md` are discovered at session start, so there is no Skills API upload.
2. **Wayfinder tracker.** The local toolkit (`research.py sync`) mirrors each run's
   `map.json` into issues here. A map issue is labelled `wayfinder:map`, and each child ticket
   is labelled `wayfinder:<type>`.

Research branches (`research/<slug>`) hold each run's notes, ADR and report when the
agent's `git push` succeeds.

## Setup

```bash
scripts/vendor_skills.sh          # pulls research, grilling, domain-modeling, wayfinder
git add .claude && git commit -m "Vendor research skills" && git push
```

`wayfinder-async` is committed directly. It is the unattended adaptation the agent runs.

## Answering parked decisions

Open the issues labelled `wayfinder:grilling`, `wayfinder:prototype` or `wayfinder:task` that
are marked **Owner decision needed**. Comment your decision, starting the comment with `Decision:`.
Then run `research.py resume <slug>` from the toolkit.
# hub-repo
