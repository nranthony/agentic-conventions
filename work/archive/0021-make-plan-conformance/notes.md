# 0021 — make-plan conformance and the feedback-pointer fallback (myconv 0.8.0)

Opened at release time rather than before the work, because the batch came from
two inbound sources rather than from a proposal here:

- a **collated review of `make-plan` by three outside models**, triaged 2026-09-09;
- the **`ikigai` repo's feedback report** of 2026-09-08 (`make-plan`,
  `assumed-repo-shape`), archived at
  `feedback/archive/ikigai-make-plan-2026-09-08-adr-location-without-docs-adr.md`
  with its disposition in `feedback/README.md`.

**The durable record is already elsewhere**, which is why this item is thin and
should stay so: what a consumer receives is in `CHANGELOG.md` 0.8.0, and the
triage decision (classed mechanical — it follows from ADR-0015, so no new ADR)
is in the feedback register. Nothing here is load-bearing except the handoff.

Exit rule: archive once the deployment tier confirms the re-vendor
(handoff §6).

**Archived 2026-09-15.** The deployment tier confirmed the re-vendor in its reply of
2026-09-09, answered here in `reply-to-sandbox-myconv-0.8.0.md`. The one lesson that
outlives this item — skills converge, wheels bake — now lives where consumers read it:
the channel's `AGENTS.md`, "Consuming a release".
