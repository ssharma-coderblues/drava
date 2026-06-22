---
description: Set up this project as Pravartak-managed (run once, interactively)
argument-hint: ""
skill: scaffold
---

Read pravartak/skills/scaffold/SKILL.md and execute the documented procedure with
arguments: $ARGUMENTS.

<!--
Bootstrap note: the Claude adapter's /scaffold must be available BEFORE .claude/commands/
exists, so unlike the other commands this file is not generated as a pointer by the scaffold
itself. It is made available at install time (install.sh copies it to
.claude/commands/scaffold.md) or the architect copies it manually:

    mkdir -p .claude/commands && cp pravartak/commands/scaffold.md .claude/commands/

Alternatively, the architect can simply tell the active runtime: "Read
pravartak/skills/scaffold/SKILL.md and execute it."
-->
