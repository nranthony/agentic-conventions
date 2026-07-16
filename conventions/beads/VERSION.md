# Beads pinned version + upgrade log

**Pinned:** bd 1.1.0 (build 8e4e59d39)

Install/upgrade from **gastownhall/beads** only (steveyegge/beads is
superseded). Cadence: weekly `bd upgrade` then `bd doctor --fix`
(doctor is a no-op in embedded mode as of 1.1.0). `bd backup` before
any upgrade or storage-mode migration.

| Date | Version | Notes |
|---|---|---|
| 2026-07-16 | 1.1.0 (8e4e59d39) | Initial install; pilot init in project_zenbu (embedded Dolt, prefix `zb`). Metrics opted out (`bd metrics off`). `bd doctor` not supported in embedded mode. |
