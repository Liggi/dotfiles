---
name: create-skill
description: Create new Claude Code skills. Only applies when user explicitly asks to create a skill or convert a workflow into a skill.
---

# Create Skill

Guide the creation of new Claude Code skills following the Agent Skills Spec.

## When to Use

**ONLY when user explicitly requests:**
- "Create a skill for..."
- "Make this into a skill"
- "Can you turn this workflow into a skill?"

**NOT automatically** - Don't proactively suggest making skills unless asked.

## Should This Be a Skill?

Before creating a skill, consider:

**Good candidates:**
- Repeated workflows with specific patterns (commits, PRs, deployments)
- Multi-step processes with clear structure (iterative refinement, research)
- Domain expertise (generative art, data analysis)
- Workflows you'll use across many projects

**Better as CLAUDE.md instructions:**
- Project-specific workflows
- One-off processes
- Context that doesn't generalize
- Preferences that aren't about process

**Rule of thumb:** If it's reusable across conversations and projects, it's a skill. If it's context about this codebase, it's CLAUDE.md.

## Skill Anatomy

**Minimal structure:**
```
skill-name/
  └── SKILL.md  (required)
```

**SKILL.md format:**
```markdown
---
name: skill-name
description: What it does and when Claude should use it
---

# Skill Name

Instructions go here.
```

## Creation Workflow

### 1. Name and Description

**Name:**
- Lowercase alphanumeric + hyphens
- Matches directory name
- Descriptive and specific

**Description (critical):**
This determines when Claude invokes the skill. Be specific about:
- What the skill does
- When it applies
- What triggers it

**Good examples:**
```yaml
description: Create commits following Jason's workflow patterns. Handles branch creation, logical grouping of changes, tag inference, and commit message generation. Applies when agent needs to commit or user requests commit.

description: Performs iterative criticism loops to progressively improve anything. Applies when user explicitly requests refinement iterations.

description: Creating algorithmic art using p5.js with seeded randomness and interactive parameter exploration. Use this when users request creating art using code, generative art, algorithmic art, flow fields, or particle systems.
```

**Bad examples:**
```yaml
description: Helps with git  # Too vague, when does it apply?
description: A skill for making things better  # Not specific enough
description: Does commits  # Unclear when to invoke
```

### 2. Write Instructions

**Structure suggestions:**

**When to Use** - Clarify triggers/context
```markdown
## When to Use

- User asks to commit changes
- Agent needs to create a commit
- Task completion requires committing
```

**Workflow/Steps** - Main instructions
```markdown
## Workflow

### 1. First Step
Clear guidance on what to do.

### 2. Next Step
Continue with clear steps.
```

**Rules/Guidelines** - Constraints and quality standards
```markdown
## Safety Rules

- ❌ Never commit to main
- ✅ Keep commits atomic
```

**Examples** - Show don't tell
```markdown
## Examples

Good: [conversation-analysis] add issue tree component
Bad: [conversation-analysis] adds new component
```

**Principles:**
- **Be specific but not prescriptive** - Structure, not scripts
- **Use examples liberally** - They clarify better than explanations
- **Trust Claude's judgment** - Give principles, not implementation
- **Keep it focused** - One skill = one workflow

### 3. Create the Skill

```bash
mkdir -p ~/.claude/skills/skill-name
```

Write SKILL.md to that directory with the frontmatter and instructions.

### 4. Verify

**Check:**
- ✅ Directory name matches `name` in frontmatter
- ✅ Description is specific about when to invoke
- ✅ YAML frontmatter is valid
- ✅ Instructions are clear and actionable
- ✅ Examples are concrete

## YAML Frontmatter

**Required:**
```yaml
---
name: skill-name
description: What it does and when to use it (be specific!)
---
```

## Tips

**The description is everything:**
Claude uses it to decide when to invoke. Spend time getting it right. Be specific about triggers.

**Start simple:**
Create a basic version first. You can always refine it after testing in real use.

**Study existing skills:**
Look at `~/.claude/skills/` or [anthropics/skills](https://github.com/anthropics/skills) for patterns.

**Multiple focused skills > one mega-skill:**
Keep each skill focused on a single workflow. They compose better.
