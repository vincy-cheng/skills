/**
 * Pure parser for dev-flow state files (`docs/features/.feature-states/`).
 *
 * Isolation rule: the engine interface `$` never crosses an import boundary
 * (engine validation rejects it) — every fs call is passed in as a parameter
 * (`readStates(list, read)`); the hooks module wraps it in the same file it
 * uses `$` (`register.tsx`'s `readRunStates`).
 *
 * Malformed or old-format files degrade gracefully: skipped or parsed without
 * garbage, never a crash on a render path.
 */

/** The Goal-status lifecycle — the gate table's statuses in order (step N = index N). */
export const STEPS = [
  'fresh',
  'brainstorm',
  'spec',
  'planning',
  'issue',
  'execute',
  'test',
  'review',
  'doc-fix',
  'pr-review',
  'merged',
  'done',
] as const

export type GoalStatus = (typeof STEPS)[number]

/** A parsed run — every field optional-safe for pre-Status-since files. */
export type Run = {
  feat: string
  status: GoalStatus
  /** When the Goal status last changed; `undefined` on files written before the field existed. */
  since: string | undefined
  updated: string
  tasksDone: number
  tasksTotal: number
  issue: string
  pr: string
  branch: string
}

/** The fs seams the parser needs, as parameters — `$` stays in the hooks module. */
export type FsList = (path?: string) => Promise<{ name: string; kind: 'file' | 'dir' | 'other' }[]>
export type FsRead = (path: string) => Promise<string>
// Note (spec A5 deviation): no mtime memoization — the engine's list seam
// carries no mtime, and the measured cost (a few KB of local reads per turn)
// didn't justify a caller-side cache. Revisit if state dirs grow large.

export type RunStates = {
  /** All non-done runs, newest-updated first. */
  active: Run[]
  /** Runs that just finished (done or merged) — the farewell transition needs them. */
  finished: Run[]
  /** The newest-updated non-done run — the run the session surfaces. */
  current: Run | null
}

const STATE_DIR = 'docs/features/.feature-states'

const STATUS_RE = /^- \*\*Goal status:\*\* (\S+)$/
const SINCE_RE = /^- \*\*Status since:\*\* (.+)$/
const UPDATED_RE = /^- \*\*Updated:\*\* (.+)$/
const BASE_BRANCH_RE = /^- \*\*Base branch:\*\* (.+)$/
const TARGET_BRANCH_RE = /^- \*\*Target branch:\*\* (.+)$/
const ISSUE_RE = /^- Issue: (.+)$/
const PR_RE = /^- PR: (.+)$/
const TASK_RE = /^- \[( |x)\] /

/**
 * Parse one state file's text. Returns `null` when the file is unreadable as a
 * state file (no Goal status, or a status outside the lifecycle) — the caller
 * skips it.
 */
export function parseState(feat: string, text: string): Run | null {
  const lines = text.split('\n')
  let status: GoalStatus | undefined
  let since: string | undefined
  let updated = ''
  let baseBranch = ''
  let targetBranch = ''
  let issue = ''
  let pr = ''
  let tasksDone = 0
  let tasksTotal = 0
  let inTasks = false

  for (const line of lines) {
    if (line.startsWith('## ')) {
      inTasks = line === '## Tasks'
      continue
    }

    const task = TASK_RE.exec(line)
    if (inTasks && task) {
      tasksTotal++
      if (task[1] === 'x') tasksDone++
      continue
    }
    if (inTasks) continue

    const statusMatch = STATUS_RE.exec(line)
    if (statusMatch?.[1] !== undefined) {
      const candidate = statusMatch[1]
      if ((STEPS as readonly string[]).includes(candidate)) {
        status = candidate as GoalStatus
      }
      continue
    }

    const sinceMatch = SINCE_RE.exec(line)
    if (sinceMatch?.[1] !== undefined) {
      since = sinceMatch[1]
      continue
    }

    const updatedMatch = UPDATED_RE.exec(line)
    if (updatedMatch?.[1] !== undefined) {
      updated = updatedMatch[1]
      continue
    }

    const baseMatch = BASE_BRANCH_RE.exec(line)
    if (baseMatch?.[1] !== undefined) {
      baseBranch = baseMatch[1]
      continue
    }

    const targetMatch = TARGET_BRANCH_RE.exec(line)
    if (targetMatch?.[1] !== undefined) {
      targetBranch = targetMatch[1]
      continue
    }

    const issueMatch = ISSUE_RE.exec(line)
    if (issueMatch?.[1] !== undefined) {
      issue = issueMatch[1]
      continue
    }

    const prMatch = PR_RE.exec(line)
    if (prMatch?.[1] !== undefined) {
      pr = prMatch[1]
      continue
    }
  }

  if (status === undefined) return null

  return {
    feat: feat.replace(/\.state\.md$/, ''),
    status,
    since,
    updated,
    tasksDone,
    tasksTotal,
    issue,
    pr,
    branch: targetBranch || baseBranch,
  }
}

/** Step number for a status — the gate table, explicit (statuses are not 1:1 with steps). */
export function stepOf(status: GoalStatus): number {
  return STEPS.indexOf(status)
}

/**
 * Read every state file through injected fs calls. Unreadable or malformed
 * files are skipped; a missing state dir means no runs (most sessions run
 * outside a dev-flow feature). Active = every non-done run; finished = the
 * done/merged ones (the farewell transition lives on them); the current run
 * is the newest-updated non-done one (the index is derived data — never a
 * dependency).
 */
export async function readStates(list: FsList, read: FsRead): Promise<RunStates> {
  let entries: { name: string; kind: 'file' | 'dir' | 'other' }[]
  try {
    entries = await list(STATE_DIR)
  } catch {
    return { active: [], finished: [], current: null }
  }

  const runs: Run[] = []
  const finished: Run[] = []
  for (const entry of entries) {
    if (entry.kind !== 'file' || !entry.name.endsWith('.state.md') || entry.name === '.state.md') continue
    let text: string
    try {
      text = await read(`${STATE_DIR}/${entry.name}`)
    } catch {
      continue
    }
    const run = parseState(entry.name, text)
    if (run === null) continue
    if (run.status === 'done' || run.status === 'merged') finished.push(run)
    else runs.push(run)
  }

  // newest-updated first: Updated is the file's own clock (A6 — never the index)
  const active = runs.sort((a, b) => (a.updated < b.updated ? 1 : -1))

  return { active, finished, current: active[0] ?? null }
}
