// Only the type is imported: "@opencode/plugin" is not installed next to this
// file, and `Plugin.define` is an identity helper anyway.
import type { Plugin } from "@opencode/plugin"

const NTFY_URL = "https://ntfy.sh/myunghalee-ntfy-topic"

const ASK_MESSAGE = "Opencode: please answer the question"
const DONE_MESSAGE = "Opencode: please check the result"

async function notify(message: string) {
  try {
    await fetch(NTFY_URL, {
      method: "POST",
      body: message,
      signal: AbortSignal.timeout(5_000),
    })
  } catch {
    // ignore; a missed notification must never break the session
  }
}

type Event = { type: string; data: any; location?: { directory?: string } }

const plugin: Plugin = {
  id: "ntfy-notify",
  async setup(ctx) {
    const controller = new AbortController()

    // The plugin is loaded once per project location that the server has open.
    // Every instance receives the server's whole event stream, so without this
    // filter each open project would send its own copy of the same alert. Only
    // handle sessions that live in this instance's location.
    const myDirectory: string | undefined = (ctx as any).location?.directory

    // A top-level session reports `session.execution.succeeded` at the end of
    // every "busy period", not once per user request. When it launches a
    // background subagent (or background shell) and then ends its turn, it goes
    // idle and succeeds while that work is still running, then gets woken again
    // when it finishes. Notifying on that first success is premature.
    const running = new Set<string>() // sessions with a turn in flight
    const parents = new Map<string, string | undefined>() // sessionID -> parentID
    const shells = new Map<string, Set<string>>() // sessionID -> running shellIDs
    const directories = new Map<string, string>() // sessionID -> location directory

    const directoryOf = async (sessionID: string): Promise<string | undefined> => {
      const known = directories.get(sessionID)
      if (known !== undefined) return known
      try {
        const session = await ctx.session.get({ sessionID })
        const directory = session.location?.directory
        if (directory !== undefined) directories.set(sessionID, directory)
        return directory
      } catch {
        return undefined
      }
    }

    // Whether a session belongs to this plugin instance's location.
    const owns = async (sessionID: string) => {
      if (myDirectory === undefined) return true
      return (await directoryOf(sessionID)) === myDirectory
    }

    const parentOf = async (sessionID: string): Promise<string | undefined> => {
      if (parents.has(sessionID)) return parents.get(sessionID)
      try {
        const session = await ctx.session.get({ sessionID })
        parents.set(sessionID, session.parentID)
        return session.parentID
      } catch {
        return undefined
      }
    }

    const isDescendant = async (sessionID: string, rootID: string) => {
      let current = await parentOf(sessionID)
      // Subagent nesting is shallow (`experimental.subagent_depth` defaults to 1).
      for (let depth = 0; depth < 16 && current !== undefined; depth++) {
        if (current === rootID) return true
        current = await parentOf(current)
      }
      return false
    }

    // True while anything launched under `rootID` is still running, so the root
    // will be resumed and its current success is not the end of the request.
    const hasPendingWork = async (rootID: string) => {
      for (const sessionID of running) {
        if (sessionID !== rootID && (await isDescendant(sessionID, rootID))) return true
      }
      for (const [sessionID, ids] of shells) {
        if (ids.size === 0) continue
        if (sessionID === rootID || (await isDescendant(sessionID, rootID))) return true
      }
      return false
    }

    const handle = async (event: Event) => {
      // Track the session tree, execution state, and shells so a completion can
      // be attributed to the request that is actually finished.
      switch (event.type) {
        case "session.created":
          parents.set(event.data.sessionID, event.data.parentID)
          if (event.data.location?.directory !== undefined)
            directories.set(event.data.sessionID, event.data.location.directory)
          return
        case "session.deleted":
          running.delete(event.data.sessionID)
          parents.delete(event.data.sessionID)
          shells.delete(event.data.sessionID)
          directories.delete(event.data.sessionID)
          return
        case "session.execution.started":
          running.add(event.data.sessionID)
          return
        case "session.execution.succeeded":
        case "session.execution.failed":
        case "session.execution.interrupted":
          running.delete(event.data.sessionID)
          break
        case "session.shell.started": {
          const ids = shells.get(event.data.sessionID) ?? new Set<string>()
          ids.add(event.data.shell.id)
          shells.set(event.data.sessionID, ids)
          return
        }
        case "session.shell.ended":
          shells.get(event.data.sessionID)?.delete(event.data.shell.id)
          return
      }

      // Waiting for the user: permission prompt or a question form. Subagents
      // can ask too, and the user still has to answer those.
      if (event.type === "permission.asked" || event.type === "form.created") {
        if (await owns(event.data.sessionID)) await notify(ASK_MESSAGE)
        return
      }

      // Turn finished (successfully or not). Ignore subagent sessions.
      if (
        event.type === "session.execution.succeeded" ||
        event.type === "session.execution.failed" ||
        event.type === "session.execution.interrupted"
      ) {
        const sessionID = event.data.sessionID
        const session = await ctx.session.get({ sessionID })
        if (session.parentID) return
        if (!(await owns(sessionID))) return
        // A background subagent/shell will wake this session again; its next
        // success (or a failure) is the real end of the request.
        if (event.type === "session.execution.succeeded" && (await hasPendingWork(sessionID))) return
        await notify(DONE_MESSAGE)
      }
    }

    // The server's event stream can end quietly after a while, so keep
    // resubscribing for as long as the plugin is loaded.
    void (async () => {
      while (!controller.signal.aborted) {
        try {
          for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
            await handle(event)
          }
        } catch {
          if (controller.signal.aborted) return
        }
        // A dropped stream means missing history; discard tracking rather than
        // risk suppressing a notification forever.
        running.clear()
        parents.clear()
        shells.clear()
        directories.clear()
        await new Promise((resolve) => setTimeout(resolve, 1_000))
      }
    })()

    return () => controller.abort()
  },
}

export default plugin
