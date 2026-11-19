import type { Plugin } from "@opencode-ai/plugin"

const SERVERS: Record<string, { unit: string; port: number }> = {
  "llama.cpp-saluki": { unit: "llama-saluki.service", port: 8081 },
  "llama.cpp": { unit: "llama-server.service", port: 8080 },
}

export default (async ({ $ }) => {
  let last = "unknown"
  let queue: Promise<void> = Promise.resolve()

  async function waitReady(port: number) {
    for (let i = 0; i < 90; i++) {
      try {
        const res = await fetch(`http://127.0.0.1:${port}/v1/models`, {
          signal: AbortSignal.timeout(1500),
        })
        if (res.ok) return
      } catch {}
      await new Promise((resolve) => setTimeout(resolve, 1000))
    }
  }

  async function sync(providerID?: string) {
    const target = providerID && SERVERS[providerID] ? providerID : null
    const key = target ?? "off"
    if (key === last) return

    if (target) {
      const { unit, port } = SERVERS[target]
      await $`systemctl --user start ${unit}`.quiet().nothrow()
      await waitReady(port)
    } else {
      await $`systemctl --user stop llama-saluki.service llama-server.service`
        .quiet()
        .nothrow()
    }
    last = key
  }

  function enqueue(providerID?: string) {
    queue = queue.then(() => sync(providerID)).catch(() => {})
    return queue
  }

  return {
    "chat.message": async (input) => {
      if (!input.model?.providerID) return
      await enqueue(input.model.providerID)
    },
    event: async ({ event }) => {
      const e = event as any
      if (e.type !== "session.next.model.switched") return
      const providerID =
        e.data?.model?.providerID ?? e.properties?.model?.providerID
      if (providerID) await enqueue(providerID)
    },
  }
}) satisfies Plugin
