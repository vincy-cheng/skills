import { describe, expect, test } from 'claude-code/testing'

import { stepOf, type GoalStatus } from './state'

/**
 * The hooks module's behaviors: status-line text shaping, the toast's
 * status-diff + main-loop filter, the pane's shared open-args, and the
 * command surface (none — the band button is the sole opener). The exported
 * pieces under test come from register.tsx alongside the hooks wiring (same
 * module, testable seams).
 */
import { humanizeSince, nextOf, statusLine, toastsFor, FLOW_PANE, register } from './register'

const NOW = new Date('2026-10-23T22:14:00+08:00')

describe('humanizeSince — Status since → short duration', () => {
  test('humanizes 45 minutes', () => {
    expect(humanizeSince('2026-10-23 21:29+08:00', NOW)).toBe('45m')
  })

  test('humanizes 2h 15m', () => {
    expect(humanizeSince('2026-10-23 19:59+08:00', NOW)).toBe('2h 15m')
  })

  test('omits the duration when since is absent (old state files)', () => {
    expect(humanizeSince(undefined, NOW)).toBeUndefined()
  })

  test('returns undefined for an unparseable timestamp', () => {
    expect(humanizeSince('not a date', NOW)).toBeUndefined()
  })
})

describe('statusLine — the ambient text', () => {
  test('composes feat, step, status, duration', () => {
    const run = {
      feat: 'demo',
      status: 'test' as GoalStatus,
      since: '2026-10-23 21:29+08:00',
      updated: '',
      tasksDone: 0,
      tasksTotal: 0,
      issue: '',
      pr: '',
      branch: '',
    }
    expect(statusLine(run, NOW)).toBe('dev-flow: demo · step 6/11 · test · 45m')
  })

  test('omits duration when since is absent', () => {
    const run = {
      feat: 'demo',
      status: 'test' as GoalStatus,
      since: undefined,
      updated: '',
      tasksDone: 0,
      tasksTotal: 0,
      issue: '',
      pr: '',
      branch: '',
    }
    expect(statusLine(run, NOW)).toBe('dev-flow: demo · step 6/11 · test')
  })
})

describe('toastsFor — status diff, main-loop only', () => {
  const run = (feat: string, status: GoalStatus) => ({
    feat,
    status,
    since: undefined,
    updated: '',
    tasksDone: 0,
    tasksTotal: 0,
    issue: '',
    pr: '',
    branch: '',
  })

  test('fires one toast per real flip', () => {
    const prev = { demo: 'execute' as GoalStatus }
    const now = [run('demo', 'test')]
    const toasts = toastsFor(now, prev)
    expect(toasts).toEqual(['dev-flow: demo execute → test (step 6/11)'])
  })

  test('no toast when the status is unchanged', () => {
    const prev = { demo: 'test' as GoalStatus }
    const now = [run('demo', 'test')]
    expect(toastsFor(now, prev)).toEqual([])
  })

  test('no toast on first sight (session start, not a flip)', () => {
    const prev: Record<string, GoalStatus> = {}
    const now = [run('demo', 'test')]
    expect(toastsFor(now, prev)).toEqual([])
  })
})

describe('farewell transition — Y1/Y2 regression: transition-only close', () => {
  const run = (feat: string, status: GoalStatus) => ({
    feat,
    status,
    since: undefined,
    updated: '',
    tasksDone: 0,
    tasksTotal: 0,
    issue: '',
    pr: '',
    branch: '',
  })

  test('a merged run seen in an earlier status farewell-closes (prev ≠ current)', () => {
    const prev: Record<string, GoalStatus> = { demo: 'pr-review' }
    const finished = [run('demo', 'merged')]
    const just = finished.find(r => prev[r.feat] !== undefined && prev[r.feat] !== r.status)
    expect(just).toBeDefined()
  })

  test('a session that starts on a finished run does not close (no earlier status)', () => {
    const prev: Record<string, GoalStatus> = {}
    const finished = [run('demo', 'merged')]
    const just = finished.find(r => prev[r.feat] !== undefined && prev[r.feat] !== r.status)
    expect(just).toBeUndefined()
  })

  test('a steady-state finished run does not close (status unchanged)', () => {
    const prev: Record<string, GoalStatus> = { demo: 'merged' }
    const finished = [run('demo', 'merged')]
    const just = finished.find(r => prev[r.feat] !== undefined && prev[r.feat] !== r.status)
    expect(just).toBeUndefined()
  })
})

describe('nextOf — the pane next-step line', () => {
  test('names the next status and its skill', () => {
    expect(nextOf('execute')).toBe('test (dev-flow:test)')
  })

  test('terminal statuses render their wording', () => {
    expect(nextOf('done')).toBe('closed out')
    expect(nextOf('merged')).toBe('done (dev-flow:new-feature)')
  })
})
describe('FLOW_PANE — the open-args both the band and the pane share', () => {
  test('opens the dev-flow pane with the 14-row request', () => {
    expect(FLOW_PANE).toMatchObject({ id: 'flow', title: 'dev-flow', rows: 14, columns: 44, closeOnEscape: true })
  })
})

describe('register — the command surface', () => {
  test('registers no commands — the band button is the sole pane opener', () => {
    const registrations: string[] = []
    const specs: unknown[] = []
    // Fake On/$ stubs: record registrations, never run handlers.
    const recordingOn = ((pattern: string) => {
      registrations.push(pattern)
      return () => undefined
    }) as unknown as Parameters<typeof register>[0]
    const $ = {
      command: { register: (spec: unknown) => { specs.push(spec) } },
      ui: { status: () => undefined },
      fs: { list: () => Promise.resolve({ value: [] }) },
    } as never
    register(recordingOn as never, $ as never)
    expect(registrations.filter(r => r.startsWith('command.'))).toEqual([])
    expect(specs).toEqual([])
  })
})
