import { describe, expect, test } from 'claude-code/testing'

import { parseState, readStates, stepOf, STEPS, type FsList, type FsRead } from './state'

/** A minimal state file with every field the parser knows. */
const FULL = [
  '# demo — dev-flow state',
  '',
  '- **Created:** 2026-10-23 19:10+08:00',
  '- **Updated:** 2026-10-23 22:11+08:00',
  '- **Status since:** 2026-10-23 21:38+08:00',
  '- **Base branch:** feat/76-demo',
  '- **Target branch:** dev',
  '- **Goal status:** execute',
  '- **Kind:** feature',
  '',
  '## Tasks',
  '- [x] first task',
  '- [ ] second task',
  '',
  '## References',
  '- Issue: #76',
  '- PR: #80',
  '',
].join('\n')

/** A pre-Roles-era state file: no Status since, no Roles block, bare tasks. */
const OLD_FORMAT = [
  '# legacy — dev-flow state',
  '',
  '- **Created:** 2026-09-01 10:00+08:00',
  '- **Updated:** 2026-09-01 11:00+08:00',
  '- **Goal status:** test',
  '',
  '## Tasks',
  '- [x] only task',
  '',
].join('\n')

/** A malformed file: a Goal status that isn't a lifecycle status. */
const MALFORMED = [
  '# broken — dev-flow state',
  '- **Goal status:** flying',
  '',
].join('\n')

const fullReader: FsRead = async (path: string) => {
  if (path.includes('full')) return FULL
  if (path.includes('old')) return OLD_FORMAT
  if (path.includes('bad')) return MALFORMED
  if (path.includes('empty')) return ''
  throw new Error(`no fixture for ${path}`)
}

describe('parseState', () => {
  test('reads every field from a current state file', async () => {
    const run = parseState('full.state.md', FULL)
    expect(run).not.toBeNull()
    expect(run?.feat).toBe('full')
    expect(run?.status).toBe('execute')
    expect(run?.since).toBe('2026-10-23 21:38+08:00')
    expect(run?.updated).toBe('2026-10-23 22:11+08:00')
    expect(run?.tasksDone).toBe(1)
    expect(run?.tasksTotal).toBe(2)
    expect(run?.issue).toBe('#76')
    expect(run?.pr).toBe('#80')
    expect(run?.branch).toBe('dev')
  })

  test('renders a pre-Roles-era file without garbage', async () => {
    const run = parseState('old.state.md', OLD_FORMAT)
    expect(run).not.toBeNull()
    expect(run?.status).toBe('test')
    expect(run?.since).toBeUndefined()
    expect(run?.tasksTotal).toBe(1)
    expect(run?.tasksDone).toBe(1)
    expect(run?.issue).toBe('')
    expect(run?.pr).toBe('')
    expect(run?.branch).toBe('')
  })

  test('rejects an unknown Goal status', () => {
    expect(parseState('bad.state.md', MALFORMED)).toBeNull()
  })

  test('rejects a file with no Goal status line', () => {
    expect(parseState('empty.state.md', '')).toBeNull()
  })
})

describe('readStates', () => {
  const lister: FsList = async () => [
    { name: 'full.state.md', kind: 'file' },
    { name: 'old.state.md', kind: 'file' },
    { name: 'bad.state.md', kind: 'file' },
    { name: 'nested', kind: 'dir' },
  ]

  test('skips malformed files and dirs, parses the rest', async () => {
    const states = await readStates(lister, fullReader)
    expect(states.active).toHaveLength(2)
    const names = states.active.map(run => run.feat)
    expect(names).toContain('full')
    expect(names).toContain('old')
  })

  test('returns empty when the state dir is missing', async () => {
    const missing: FsList = async () => {
      throw new Error('ENOENT')
    }
    const states = await readStates(missing, fullReader)
    expect(states.active).toHaveLength(0)
    expect(states.current).toBeNull()
  })
})

describe('stepOf — explicit status→step table (A3: statuses are not 1:1 with steps)', () => {
  const expected: Record<string, number> = {
    fresh: 0,
    brainstorm: 1,
    spec: 2,
    planning: 3,
    issue: 4,
    execute: 5,
    test: 6,
    review: 7,
    'doc-fix': 8,
    'pr-review': 9,
    merged: 10,
    done: 11,
  }
  test('maps all 12 statuses via the explicit table', () => {
    expect(STEPS).toHaveLength(12)
    for (const status of STEPS) {
      expect(stepOf(status)).toBe(expected[status])
    }
  })
})