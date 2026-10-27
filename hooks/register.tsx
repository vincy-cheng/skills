import type { Register, RenderNode } from 'claude-code'

import { readStates, stepOf, STEPS, type FsList, type FsRead, type GoalStatus, type Run } from './state'

type Fs = { list: FsList; read: FsRead }

/** Reads dev-flow state files through the session's fs (the `$` wrapper stays in this file). */
function readRunStates($: { fs: Fs }) {
  return readStates(
    path => $.fs.list(path),
    path => $.fs.read(path),
  )
}

/**
 * dev-flow session help: four person-facing behaviors, all reading
 * `docs/features/.feature-states/` live:
 * - status line (ambient): `dev-flow: <feat> · step 6/11 · test · 45m`
 * - band (always drawn): the [ Flow ] button that opens the pane
 * - `/flow` pane (on-demand): a compact 14-row card of the current run
 * - step toast: fires when a run's Goal status flips between turns
 *
 * Placement and close are the surface's: `rows` is a request, not a grant;
 * a person-opened pane seats at any width; the mod never auto-opens.
 */

const PANE = 'flow'

/** The open-args both openers share — /flow and the band's [ Flow ] button.
 *  rows: 14 — header, 11 strip rows, refs, button. Requests, not grants:
 *  a person-opened pane still seats at any size the surface picks. */
const FLOW_PANE = { id: PANE, title: 'dev-flow', rows: 14, columns: 44, closeOnEscape: true } as const

/** Status → the skill whose run *advances the run into* that status (the gate table's "Sets" column). */
const ENTERED_BY: Record<GoalStatus, string> = {
  fresh: '',
  brainstorm: 'brainstorm',
  spec: 'brainstorm',
  planning: 'plan',
  issue: 'create-github-issue',
  execute: 'execute-tasks',
  test: 'test',
  review: 'review',
  'doc-fix': 'doc-fix',
  'pr-review': 'open-pr',
  merged: 'new-feature',
  done: 'new-feature',
}

/** The step after `status` and the skill that runs it, for the pane's next-step line. */
export function nextOf(status: GoalStatus): string {
  const next = STEPS[stepOf(status) + 1]
  if (next === undefined) return 'closed out'
  const skill = ENTERED_BY[next]
  if (skill === '' || skill === undefined) return next
  return `${next} (dev-flow:${skill})`
}

/** `Status since` vs. now, humanized — `undefined` when unknown (old files, bad timestamp). */
export function humanizeSince(since: string | undefined, now: Date): string | undefined {
  if (since === undefined) return undefined
  const then = new Date(since)
  if (Number.isNaN(then.getTime())) return undefined
  const minutes = Math.max(0, Math.round((now.getTime() - then.getTime()) / 60000))
  const hours = Math.floor(minutes / 60)
  const rest = minutes % 60
  if (hours === 0) return `${minutes}m`
  if (rest === 0) return `${hours}h`
  return `${hours}h ${rest}m`
}

/** The ambient status-line text for a run; `undefined` (clear) when there is none. */
export function statusLine(run: Run | null, now: Date): string | undefined {
  if (run === null) return undefined
  const parts = [
    `dev-flow: ${run.feat}`,
    `step ${stepOf(run.status)}/11`,
    run.status,
  ]
  const duration = humanizeSince(run.since, now)
  if (duration !== undefined) parts.push(duration)
  return parts.join(' · ')
}

/** The toast texts for status flips between the last-known and current reads. */
export function toastsFor(runs: Run[], prev: Record<string, GoalStatus>): string[] {
  const toasts: string[] = []
  for (const run of runs) {
    const was = prev[run.feat]
    if (was !== undefined && was !== run.status) {
      toasts.push(`dev-flow: ${run.feat} ${was} → ${run.status} (step ${stepOf(run.status)}/11)`)
    }
  }
  return toasts
}

/** /flow command spec, extracted for tests. */
export const FLOW_COMMAND = {
  name: 'flow',
  description: 'Open the dev-flow pane: current run, lifecycle, refs, next step',
  immediate: true,
} as const

export const register: Register = on => {
  /** Last-known statuses — the flip cache (session-scoped, ambient; not a cross-session ledger). */
  let lastKnown: Record<string, GoalStatus> = {}
  /** Whether the current run has already been farewell-closed (A1: transition-only). */
  let farewelled = false

  on('session.start', async ($, e, next) => {
    await $.command.register(FLOW_COMMAND)

    const states = await readRunStates($)
    lastKnown = Object.fromEntries(states.active.map(run => [run.feat, run.status]))
    await $.ui.status(statusLine(states.current, new Date()))

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    // Subagent turns also fire turn.complete; the pane's story stays ambient —
    // only the main loop (agentId absent) re-evaluates.
    if (e.agentId === undefined || e.agentId === null) {
      const states = await readRunStates($)

      // The previous statuses, captured before the cache overwrites — the
      // farewell close needs the transition (prev ≠ current), not a
      // steady-state read.
      const prev = lastKnown
      for (const toast of toastsFor(states.active, prev)) {
        $.ui.toast(toast)
      }
      // A run that just reached done/merged also toasts — it left the active
      // list, so toastsFor can't see it (the merged → done close-out flip).
      for (const run of states.finished) {
        const was = prev[run.feat]
        if (was !== undefined && was !== run.status) {
          $.ui.toast(`dev-flow: ${run.feat} ${was} → ${run.status} (step ${stepOf(run.status)}/11)`)
        }
      }
      lastKnown = Object.fromEntries(states.active.map(run => [run.feat, run.status]))

      await $.ui.status(statusLine(states.current, new Date()))

      // Farewell close: only on the flip into done/merged (the run was seen
      // in an earlier status last turn), never on a steady-state read — a
      // session that starts on a finished run, or a pane the person
      // re-opened, persists untouched.
      const justFinished = states.finished.find(
        run => prev[run.feat] !== undefined && prev[run.feat] !== run.status,
      )
      if (justFinished !== undefined && !farewelled) {
        await $.ui.close({ id: PANE })
        $.ui.toast(`dev-flow: ${justFinished.feat} finished — pane closed.`)
        farewelled = true
      } else {
        farewelled = false
      }

      // The pane follows the state files: redraw with the fresh picture.
      $.ui.invalidate('ui.render')
    }

    return next(e)
  })

  // The band: an always-drawn row above the prompt whose [ Flow ] button opens
  // the pane. A press is person input — the pane it opens places at any width,
  // where an unasked open waits below 144 columns. The band draws nothing else
  // (the status line owns the ambient text) and yields to surveys; stacking
  // under whatever other mods drew follows next(e).
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)
    const below = await next(e).catch(() => undefined)

    const { Box, Button } = $.ui.resolve(e)
    const mine = (
      <Box>
        <Button key="flow-open" plain label="[ Flow ]" onPress={() => void $.ui.open(FLOW_PANE)} />
      </Box>
    )
    return below ? <Box flexDirection="column">{mine}{below as RenderNode}</Box> : mine
  })

  // /flow: opens the pane. The render hook below draws it fresh each time.
  on('command.run', { command: 'flow' }, async $ => {
    // `immediate: true` (on FLOW_COMMAND) lets /flow run while a turn streams:
    // the host runs an immediate command at once instead of queueing it until
    // the turn ends. This hook must not assume the turn's state — it opens a
    // pane and nothing else.
    // `columns` asks for a docked pane beside the transcript; `rows` covers
    // the inline fallback above the prompt when the terminal is narrow.
    await $.ui.open(FLOW_PANE)
    return { text: 'dev-flow pane opened. Esc closes it when it holds focus.' }
  })

  // The pane: a compact 14-row card — header+step, 11 strip rows, refs+next, buttons.
  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const states = await readRunStates($)
    const { Box, Text, Button } = $.ui.resolve(e)
    const run = states.current

    if (run === null) {
      return (
        <Box flexDirection="column">
          <Text dimColor>No active dev-flow run. Start one: /new-feature &lt;idea&gt;</Text>
          {CloseButton($, Button)}
        </Box>
      )
    }

    const now = new Date()
    const duration = humanizeSince(run.since, now)

    return (
      <Box flexDirection="column">
        <Text>
          <Text bold color="claude">{run.feat}</Text>
          {'  '}step {stepOf(run.status)}/11 · {run.status}{duration !== undefined ? ` · ${duration}` : ''}
        </Text>
        {LifecycleStrip(Box, Text, stepOf(run.status))}
        <Text dimColor>
          Tasks {run.tasksDone}/{run.tasksTotal} · {run.issue || '—'} → {run.branch || '—'} · next: {nextOf(run.status)}
        </Text>
        <Box>
          {CloseButton($, Button)}
        </Box>
      </Box>
    )
  })
}

/**
 * The pane's own close path: a UI event, never a prompt — so closing works
 * mid-response, where the host's Esc owns interrupt priority. Every state
 * the pane draws carries it (run card and empty state alike).
 */
function CloseButton($: { ui: { close: (args: { id: string }) => Promise<void> } }, Button: (props: { key?: string; label: string; onPress: () => void }) => RenderNode | null | undefined) {
  return (
    <Button
      key="close"
      label="Close"
      onPress={() => void $.ui.close({ id: PANE })}
    />
  )
}

/** The 11 lifecycle names after `fresh`, keyed by step number. */
const STEP_NAME = STEPS.slice(1)

/** A drawing element from $.ui.resolve(e), whatever the surface's table holds. */
type El = (props: Record<string, unknown>) => RenderNode | null | undefined

/**
 * The elements come from $.ui.resolve(e); pass them in, they are no globals.
 * Done steps: success. Current: bold accent. Future: subtle — never red; a
 * run's ahead steps are normal, not failures. One row per step so the full
 * names always fit any granted width — the horizontal strip truncated
 * mid-name against the pane's 44-column request.
 */
function LifecycleStrip(Box: El, Text: El, step: number) {
  return (
    <Box flexDirection="column">
      {STEP_NAME.map((name: string, i: number) => {
        const stepNo = i + 1
        const isDone = stepNo < step
        const isCurrent = stepNo === step
        return (
          <Text
            key={name}
            color={isCurrent ? 'claude' : isDone ? 'success' : 'subtle'}
            bold={isCurrent}
          >
            {isDone ? '✓ ' : isCurrent ? '▸ ' : '· '}
            {name}
          </Text>
        )
      })}
    </Box>
  )
}
