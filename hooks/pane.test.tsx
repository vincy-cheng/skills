import { expect, test } from 'claude-code/testing'

/**
 * The `/flow` pane's two drawing paths:
 * - empty state (no state dir / no active run): names the start path, closes
 * - run card (an active run): header+step, lifecycle strip, refs, next step
 *
 * Both carry the pane's own `[ Close ]` button — closing never waits on
 * Esc's interrupt priority (the host owns Esc while Claude responds).
 * The button is found by key, on both input surfaces.
 *
 * The mount environment has no dev-flow state dir, so tests that mount it
 * plainly draw the empty state. The run-card tests stub fs.list/fs.read to
 * feed one active run through the real parser — the run-card path.
 */

const PANE_PROPS = {
  title: 'dev-flow',
  isFocused: true,
  bodyColumns: 80,
  placement: 'inline' as const,
  scroll: { offset: 0, bodyRows: 4 },
  view: {},
}

/** A minimal state file with an active run (brainstorm, one open task). */
const ACTIVE_STATE = [
  '# demo — dev-flow state',
  '',
  '- **Updated:** 2026-10-26 22:18+08:00',
  '- **Goal status:** brainstorm',
  '- **Target branch:** dev',
  '',
  '## Tasks',
  '- [ ] <task description>',
  '',
  '## References',
  '- Issue: #80 (seed — issue is the brief; step 4 = branch only)',
  '- PR: _(pending)_',
  '',
].join('\n')

test('pane draws a Close button on every input surface', async $ => {
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({
      plugin: 'dev-flow',
      surface,
      component: 'Pane',
      props: { ...PANE_PROPS },
      requestId: 'flow',
    })

    const close = await ui.find({ key: 'close' })
    expect(close).toBeDefined()

    await ui.unmount()
  }
})

test('the empty state names the start path and closes too', async $ => {
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({
      plugin: 'dev-flow',
      surface,
      component: 'Pane',
      props: { ...PANE_PROPS },
      requestId: 'flow',
    })

    expect(await ui.find({ type: 'Text', text: /No active dev-flow run/ })).toBeDefined()
    const close = await ui.find({ key: 'close' })
    expect(close).toBeDefined()

    await ui.unmount()
  }
})

test('the pane draws exactly one button — Close; no Resume', async $ => {
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({
      plugin: 'dev-flow',
      surface,
      component: 'Pane',
      props: { ...PANE_PROPS },
      requestId: 'flow',
    })

    expect(await ui.find({ key: 'close' })).toBeDefined()
    expect(await ui.find({ key: 'resume' })).toBeUndefined()

    await ui.unmount()
  }
})

test('the run card draws the run, its step, and closes', async ($, on) => {
  on('fs.list', () => ({
    value: [{ name: 'demo.state.md', kind: 'file' }],
  }))
  on('fs.read', ($, e) => ({
    value: e.path.endsWith('demo.state.md') ? ACTIVE_STATE : '',
  }))

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({
      plugin: 'dev-flow',
      surface,
      component: 'Pane',
      props: { ...PANE_PROPS },
      requestId: 'flow',
    })

    expect(await ui.find({ type: 'Text', text: /demo/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /step 1\/11 · brainstorm/ })).toBeDefined()
    expect(await ui.find({ key: 'close' })).toBeDefined()

    await ui.unmount()
  }
})

test('the lifecycle strip renders every step name in full, un-truncated', async ($, on) => {
  on('fs.list', () => ({
    value: [{ name: 'demo.state.md', kind: 'file' }],
  }))
  on('fs.read', ($, e) => ({
    value: e.path.endsWith('demo.state.md') ? ACTIVE_STATE : '',
  }))

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({
      plugin: 'dev-flow',
      surface,
      component: 'Pane',
      props: { ...PANE_PROPS },
      requestId: 'flow',
    })

    // Every full step name renders as its own glyph-prefixed row — no truncation.
    for (const name of STEPS_IN_ORDER) {
      expect(await ui.find({ type: 'Text', text: new RegExp(`[✓▸·] ${escapeRegExp(name)}$`) })).toBeDefined()
    }

    // Each step row is its own Text — the old strip joined them with ' → '
    // onto one wide line the surface truncated mid-name. The find above
    // already matched the glyph-anchored row; assert on its actual text.
    for (const name of STEPS_IN_ORDER) {
      const row = await ui.find({ type: 'Text', text: new RegExp(`[✓▸·] ${escapeRegExp(name)}$`) })
      const rowText: unknown = row?.props?.text !== undefined ? row.props.text : row?.text
      expect(rowText).toBeDefined()
      expect(String(rowText)).not.toContain(' → ')
    }

    await ui.unmount()
  }
})

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

const STEPS_IN_ORDER = ['brainstorm', 'spec', 'planning', 'issue', 'execute', 'test', 'review', 'doc-fix', 'pr-review', 'merged', 'done']
test('the band draws a Flow button that opens the pane as person input', async ($, on) => {
  let openCalls: Array<Record<string, unknown>> = []
  on('ui.open', ($, e) => {
    openCalls.push(e)
    return { value: { isPlaced: true } }
  })

  for (const surface of ['terminal', 'desktop'] as const) {
    openCalls = []
    const ui = await $.ui.mount({
      plugin: 'dev-flow',
      surface,
      component: 'AbovePrompt',
      props: {
        title: '',
        hasSurvey: false,
        isWorking: false,
        maxRows: 4,
        bodyColumns: 80,
        scroll: { offset: 0, bodyRows: 4 },
        view: {},
      },
      requestId: 'band',
    })

    const flow = await ui.find({ key: 'flow-open' })
    expect(flow).toBeDefined()
    expect(openCalls).toHaveLength(0)

    await $.ui.press({ plugin: 'dev-flow', key: 'flow-open', requestId: 'band', surface })
    expect(openCalls).toHaveLength(1)
    expect(openCalls[0]).toMatchObject({ id: 'flow' })

    await ui.unmount()
  }
})

test('the band yields to a survey and shows nothing without one', async ($, on) => {
  on('ui.open', () => ({ value: { isPlaced: true } }))
  // A survey holds the band; our hook passes through to next(e) — the test
  // answers the beneath render so the pass-through is what gets mounted.
  // An empty Box stands for another mod's row beneath ours.
  on('ui.render', ($, e) => {
    const { Box } = $.ui.resolve(e)
    return <Box />
  })

  const ui = await $.ui.mount({
    plugin: 'dev-flow',
    surface: 'terminal',
    component: 'AbovePrompt',
    props: {
      title: '',
      hasSurvey: true,
      isWorking: false,
      maxRows: 4,
      bodyColumns: 80,
      scroll: { offset: 0, bodyRows: 4 },
      view: {},
    },
    requestId: 'band',
  })

  expect(await ui.find({ key: 'flow-open' })).toBeUndefined()
  await ui.unmount()
})
