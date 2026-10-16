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

const plugin: Plugin = {
  id: "ntfy-notify",
  async setup(ctx) {
    const controller = new AbortController()

    const handle = async (event: { type: string; data: any }) => {
      // Waiting for the user: permission prompt or a question form.
      if (event.type === "permission.asked" || event.type === "form.created") {
        await notify(ASK_MESSAGE)
        return
      }

      // Turn finished (successfully or not). Ignore subagent sessions.
      if (
        event.type === "session.execution.succeeded" ||
        event.type === "session.execution.failed" ||
        event.type === "session.execution.interrupted"
      ) {
        const session = await ctx.session.get({ sessionID: event.data.sessionID })
        if (!session.parentID) await notify(DONE_MESSAGE)
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
        await new Promise((resolve) => setTimeout(resolve, 1_000))
      }
    })()

    return () => controller.abort()
  },
}

export default plugin
