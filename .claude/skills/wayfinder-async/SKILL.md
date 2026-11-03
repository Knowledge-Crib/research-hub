---
name: wayfinder-async
description: Unattended variant of Matt Pocock's wayfinder for background research sessions. Chart a decision map for a large, foggy requirement, resolve every AFK research ticket through parallel researcher subagents, and park human-in-the-loop tickets as decisions for the owner instead of answering them. Use when a session brief says to run wayfinder-async, or when resuming a map with owner decisions.
---

# Wayfinder (async)

Adapted from `wayfinder` by Matt Pocock (mattpocock/skills). The method is the same:
a **shared map** of **decision tickets** that clears the fog between here and a named
**destination**. What changes is the operating context. You run as a background agent
with no human in the session, so:

- You never answer a human-in-the-loop (HITL) ticket yourself. Grilling and prototype
  tickets are **parked** for the owner, with everything they need to decide quickly.
- You resolve **every** AFK research ticket on the frontier in one session, in parallel.
  (Upstream wayfinder already exempts research tickets from the one-ticket-per-session rule.)
- The tracker is a **file contract** (`map.json`), not a live issue tracker. The owner's
  tooling mirrors it into GitHub issues after you finish. Never call the GitHub API yourself.

Plan, don't do: tickets resolve decisions. The pull to build the thing means you have
reached the edge of the map.

## Inputs

The first user message of the session contains:

- **Slug**: short kebab-case id for this effort. It prefixes nothing in filenames (outputs are flat) but goes in `map.json`.
- **Brief**: the requirement, constraints, and what the owner already believes.
- **Context files**: mounted read-only under `/mnt/session/uploads/context/`. Read them all before charting.
- **Mode**: `chart` (new map) or `advance` (owner decisions attached; the current `map.json` is in the message or under `/mnt/session/uploads/context/`).

## Ticket types

Same four types as upstream. Each is `AFK` or `HITL`:

| Type | Mode | How it resolves here |
|---|---|---|
| research | AFK | Delegate to a researcher subagent (see below). Resolve now. |
| task | AFK if you can do it in the sandbox, else HITL | AFK: do it. HITL: park with a precise checklist. |
| grilling | HITL | Park. Write the question, the options you see, the evidence for each, and what changes downstream depending on the answer. Do not pick for the owner. |
| prototype | HITL | Park, but you may attach a cheap draft artifact (outline, stub, diagram as text) for the owner to react to. |

## Chart mode

1. **Name the destination** from the brief in one or two lines: the spec, decision, or change this effort is finding its way to. If the brief is ambiguous about the destination, choose the narrowest reasonable reading, state it, and add a grilling ticket asking the owner to confirm it.
2. **Map the frontier breadth-first.** Fan out across the whole space before going deep: every open decision, every fact a decision waits on, and the first steps takeable now.
3. **Write tickets you can state precisely now.** Fog-or-ticket test: can you phrase the question sharply *now*? Not whether you can answer it. Everything vaguer goes into `not_yet_specified`. Work beyond the destination goes into `out_of_scope` with a reason.
4. **Wire blocking** in a second pass (`blocked_by` lists ticket keys).
5. **Resolve the research frontier**: every open, unblocked research ticket, fanned out in parallel (see Delegation). When answers unblock further research tickets or graduate fog into new research tickets, run another round. Stop when the frontier contains only HITL tickets, or after 4 rounds.
6. **Write the outputs** (see Output contract) and stop.

## Advance mode

1. Load `map.json` (low resolution first; zoom into research notes only as needed).
2. Apply each owner decision: record it as the ticket's `resolution` with `resolved_by: "owner"`, set `status: "closed"`.
3. If a decision invalidates other tickets or puts them past the destination, update them or move them to `out_of_scope`.
4. Graduate fog the decisions have made specifiable into new tickets. Clear each graduated item from `not_yet_specified`.
5. Run research rounds on the new frontier, exactly as in chart mode.
6. Rewrite all outputs. Update the ADR and report; never fork a second ADR for the same decision.

## Delegation (research tickets)

Delegate each research ticket to the **researcher** subagent, many in parallel. Give each one:

- The ticket key and the exact question.
- The destination line, so it knows what the answer is for.
- Any closed-ticket gists it depends on.
- The output filename it must write: `research-<KEY>-<short-slug>.md` in `/mnt/session/outputs/`.

When a researcher returns, read its note, then write the ticket's `resolution`: a 2–5 sentence
answer with the decision-relevant facts, plus `assets: ["research-<KEY>-....md"]`.
If a note is thin, contradicts another, or rests on secondary sources, send the researcher a
follow-up before accepting it. You can message the same subagent thread again.

## Output contract

Write everything **flat** into `/mnt/session/outputs/` (no subdirectories):

1. `map.json`: the machine-readable map. This schema is the contract with the owner's tooling. Keep keys stable across runs.

```json
{
  "schema_version": 1,
  "slug": "llm-security-guardrails",
  "destination": "one or two lines",
  "notes": "domain, standing preferences, skills every session should consult",
  "tickets": [
    {
      "key": "T1",
      "title": "Short decision-shaped name",
      "type": "research | grilling | prototype | task",
      "mode": "AFK | HITL",
      "question": "The decision or investigation this ticket resolves",
      "blocked_by": ["T0"],
      "status": "open | closed | out_of_scope",
      "resolution": "Markdown answer, empty while open",
      "resolved_by": "agent | owner | null",
      "assets": ["research-T1-threat-taxonomy.md"],
      "owner_brief": "HITL only: options, evidence for each, what changes downstream"
    }
  ],
  "not_yet_specified": ["loose description of fog toward the destination"],
  "out_of_scope": [{ "gist": "...", "why": "...", "ticket": "T9 or null" }]
}
```

   Ticket keys are `T1`, `T2`, and so on. Never renumber. New tickets take the next free number.

2. `map.md`: the human map body (Destination, Notes, Decisions so far, Not yet specified, Out of scope). Refer to tickets **by title**, never by bare key.
3. `decisions-for-owner.md`: one section per open HITL ticket, frontier first. Each section has the question, options, evidence per option with citations, your read of the trade-off, and what it unblocks. Be concrete enough that each decision takes the owner minutes.
4. `research-<KEY>-<slug>.md`: one per resolved research ticket (written by researchers).
5. `ADR-<NNN>-<slug>.md`: the recommendation so far in **Context / Decision / Consequences** form. Where the decision depends on parked tickets, write the recommended default, and mark it `PENDING OWNER: <ticket title>`.
6. `report.md`: the executive summary, covering what was found, what is decided, what is waiting on the owner, and the top risks. One page.

If the hub repository is mounted and `git push` works, also commit these files to the branch
`research/<slug>` under `research/<slug>/`. If push fails, note it in `report.md` and continue.
The `/mnt/session/outputs/` copy is the one that counts.

## Quality bar

- Every factual claim traces to a **primary source** (vendor docs, standards bodies, papers, source code, first-party announcements) with a URL. Secondary write-ups only to find primary sources.
- Date-sensitive facts (pricing, product capabilities, standards versions) carry the date seen.
- Distinguish "documented" from "claimed by vendor marketing" from "inferred".
- Name what you could not verify. An honest gap beats a confident guess.
