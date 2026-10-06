---
description: Create a structured idea folder under ideas/<slug>/ (or ideas/<project>/<slug>/ in an ideas repo) with five self-contained docs — README, research, design, plan, tl-dr — plus cost.md when the user opts in. Asks two questions up front: nesting level, and whether to include cost research. Discusses and grills the idea with the user before writing any files. Pass the idea as arguments. The plan.md is a draft that can be handed straight to /new-feature when you're ready to build. Not part of the step pipeline.
---

# new-idea

Scaffold a structured idea folder for a brainstormed product or concept.

Arguments: $ARGUMENTS

Follow `skills/new-idea/SKILL.md` (dev-flow plugin) exactly: ask the two up-front questions (nesting level — ideas repo → `ideas/<project>/<slug>/`, project repo → `ideas/<slug>/`; and cost.md inclusion), then **discuss the idea with the user first** — grill it, synthesize, get an explicit go-ahead (see the skill's "Grill the idea" section) before writing anything. Then derive a kebab-case English slug, create the required files, and fill them from what the user gave you — never invent facts.