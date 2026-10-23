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
 * dev-flow session help: three person-facing behaviors, all reading
 * `docs/features/.feature-states/` live:
 * - status line (ambient): `dev-flow: <feat> · step 6/11 · test · 45m`
 * - `/flow` pane (on-demand): a compact 4-row card of the current run
 * - step toast: fires when a run's Goal status flips between turns
 *
 * Placement and close are the surface's: `rows` is a request, not a grant;
 * a person-opened pane seats at any width; the mod never auto-opens.
 */

const PANE = 'flow'

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

export const register: Register = on => {
  /** Last-known statuses — the flip cache (session-scoped, ambient; not a cross-session ledger). */
  let lastKnown: Record<string, GoalStatus> = {}
  /** Whether the current run has already been farewell-closed (A1: transition-only). */
  let farewelled = false

  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'flow',
      description: 'Open the dev-flow pane: current run, lifecycle, refs, next step',
    })

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

      for (const toast of toastsFor(states.active, lastKnown)) {
        $.ui.toast(toast)
      }
      lastKnown = Object.fromEntries(states.active.map(run => [run.feat, run.status]))

      await $.ui.status(statusLine(states.current, new Date()))

      // Farewell close: only on the flip into done/merged, never steady-state
      // reads — a pane the person re-opened persists showing the final state.
      if (states.current !== null && (states.current.status === 'done' || states.current.status === 'merged')) {
        if (!farewelled && lastKnown[states.current.feat] !== undefined) {
          await $.ui.close({ id: PANE })
          $.ui.toast(`dev-flow: ${states.current.feat} finished — pane closed.`)
          farewelled = true
        }
      } else {
        farewelled = false
      }

      // The pane follows the state files: redraw with the fresh picture.
      $.ui.invalidate('ui.render')
    }

    return next(e)
  })

  // /flow: opens the pane. The render hook below draws it fresh each time.
  on('command.run', { command: 'flow' }, async $ => {
    await $.ui.open({ id: PANE, title: 'dev-flow', rows: 4, closeOnEscape: true })
    return { text: 'dev-flow pane opened. Esc closes it when it holds focus.' }
  })

  // The pane: a compact 4-row card — header+step, strip, refs+next, buttons.
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
          Tasks {run.tasksDone}/{run.tasksTotal} · {run.issue || '—'} → {run.branch || 'dev'} · next: {nextOf(run.status)}
        </Text>
        <Box>
          <Button
            key="resume"
            label="Resume run"
            onPress={() => void $.prompt.submit({ text: '/dev-flow:new-feature resume' })}
          />
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
 * run's ahead steps are normal, not failures. The strip carries no unique
 * data (row 1 has the step number and status); wrap or truncation is fine.
 */
function LifecycleStrip(Box: El, Text: El, step: number) {
  return (
    <Box>
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
            {stepNo === 1 ? '' : ' → '}
            {isDone ? '✓' : ''}
            {name}
          </Text>
        )
      })}
    </Box>
  )
}