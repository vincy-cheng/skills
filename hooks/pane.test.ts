import { expect, test } from 'claude-code/testing'

/**
 * Task 8: the pane carries its own `[ Close ]` button — closing never waits
 * on Esc's interrupt priority (the host owns Esc while Claude responds).
 * Mounted on both input surfaces; the button is found by key.
 *
 * The mount environment has no dev-flow state dir, so the pane draws its
 * empty state — which is exactly what this test asserts the button on:
 * every state the pane can draw carries the close path.
 */

const PANE_PROPS = {
  title: 'dev-flow',
  isFocused: true,
  bodyColumns: 80,
  placement: 'inline' as const,
  scroll: { offset: 0, bodyRows: 4 },
  view: {},
}

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