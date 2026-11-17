import { Plugin } from "@opencode/plugin/tui"
import { spawn } from "node:child_process"

const send = (message) =>
  spawn("notify-send",
    ["--app-name=OpenCode", "OpenCode", message],
    { stdio: "ignore" })

export default Plugin.define({
  id: "local.notify",
  setup(context) {
    context.ui.toast.show({ message: "notify plugin loaded" })
    const stopDone = context.data.on("session.execution.succeeded", () => send("Finished"))
    const stopPerm = context.data.on("permission.asked", () => send("Permission needed"))
    return () => { stopDone(); stopPerm() }
  },
})
