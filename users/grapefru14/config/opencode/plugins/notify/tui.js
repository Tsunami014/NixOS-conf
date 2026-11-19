import { Plugin } from "@opencode/plugin/tui"
import { spawn } from "node:child_process"

const send = (message) =>
  spawn("notify-send",
    ["--app-name=OpenCode", "OpenCode", message],
    { stdio: "ignore" })

const DEBUG = false

export default Plugin.define({
  id: "local.notify",
  setup(context) {
    context.ui.toast.show({ message: "notify plugin loaded" })

    // Session IDs known to be subagents (child sessions)
    const children = new Set()

    const track = (event) => {
      if (DEBUG) {
        context.ui.toast.show({ message: JSON.stringify(event).slice(0, 300) })
      }
      const d = event?.data ?? {}
      const id = d.sessionID ?? d.id ?? d.info?.id
      const parent = d.parentID ?? d.parentId ?? d.info?.parentID ?? d.info?.parentId
      if (id && parent) children.add(id)
    }

    // Candidate events that may carry a session's parentID
    const stops = [
      context.data.on("session.created", track),
      context.data.on("session.updated", track),
    ]

    stops.push(
      context.data.on("session.execution.succeeded", (event) => {
        const id = event?.data?.sessionID
        send(children.has(id) ? "Subagent finished" : "Finished")
      }),
      context.data.on("permission.asked", () => send("Permission needed")),
    )

    return () => stops.forEach((stop) => stop())
  },
})
