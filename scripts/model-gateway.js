// model-gateway.js — LLM 网关：Anthropic Messages API → 多后端路由
// 启动: node model-gateway.js (监听 127.0.0.1:8787)

const http = require("http");

const DEEPSEEK_KEY = process.env.GW_DEEPSEEK_KEY || "";
const DEEPSEEK_BASE = "https://api.deepseek.com/anthropic";
const GEMINI_KEY = process.env.GW_GEMINI_KEY || "";
const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/openai";

const PORT = 8787;

// ---- helpers ----
function getBackend(model) {
  if (model.startsWith("gemini")) return "gemini";
  return "deepseek";
}

async function fetchSSE(url, opts) {
  const res = await fetch(url, opts);
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${res.status}: ${text.slice(0, 500)}`);
  }
  return res;
}

function openaiToAnthropic(data, model) {
  const choice = (data.choices || [])[0] || {};
  return {
    id: data.id || "msg_" + Date.now(),
    type: "message",
    role: "assistant",
    model: model,
    content: [{ type: "text", text: choice.message?.content || "" }],
    stop_reason: choice.finish_reason === "stop" ? "end_turn" : choice.finish_reason || "end_turn",
    stop_sequence: null,
    usage: {
      input_tokens: data.usage?.prompt_tokens || 0,
      output_tokens: data.usage?.completion_tokens || 0,
    },
  };
}

function anthropicToOpenAI(body) {
  const messages = (body.messages || []).map((m) => ({
    role: m.role,
    content: typeof m.content === "string" ? m.content : m.content?.map((c) => c.text || "").join("") || "",
  }));
  // Handle system prompt
  if (body.system) {
    messages.unshift({ role: "system", content: typeof body.system === "string" ? body.system : body.system?.map((c) => c.text || "").join("") || "" });
  }
  return {
    model: body.model,
    max_tokens: body.max_tokens || 4096,
    messages,
    stream: body.stream || false,
    temperature: body.temperature,
    top_p: body.top_p,
  };
}

function sseOpenAItoAnthropic(chunk) {
  if (!chunk.choices?.[0]) return null;
  const c = chunk.choices[0];
  if (c.delta?.content) {
    return {
      type: "content_block_delta",
      index: 0,
      delta: { type: "text_delta", text: c.delta.content },
    };
  }
  if (c.finish_reason) {
    return {
      type: "message_delta",
      delta: { stop_reason: c.finish_reason === "stop" ? "end_turn" : c.finish_reason },
      usage: { output_tokens: chunk.usage?.completion_tokens || 0 },
    };
  }
  return null;
}

// ---- HTTP server ----
const server = http.createServer(async (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "*");
  res.setHeader("Access-Control-Allow-Methods", "*");

  if (req.method === "OPTIONS") return res.end();

  // Collect body
  let body = "";
  for await (const chunk of req) body += chunk;

  if (req.url === "/v1/models" || req.url === "/models") {
    // Return both providers' models
    return res.end(JSON.stringify({
      object: "list",
      data: [
        { id: "deepseek-v4-pro", object: "model" },
        { id: "deepseek-v4-flash", object: "model" },
        { id: "gemini-2.5-flash", object: "model" },
        { id: "gemini-2.5-pro", object: "model" },
        { id: "gemini-3.5-flash", object: "model" },
      ],
    }));
  }

  if (!req.url.includes("/messages")) {
    res.writeHead(404);
    return res.end("not found");
  }

  let parsed;
  try { parsed = JSON.parse(body); } catch (e) { res.writeHead(400); return res.end("bad json"); }

  const model = parsed.model || "deepseek-v4-pro";
  const backend = getBackend(model);
  const isStream = parsed.stream;

  try {
    if (backend === "gemini") {
      const oaiBody = anthropicToOpenAI(parsed);
      oaiBody.model = model; // Keep original model name
      const apiRes = await fetchSSE(`${GEMINI_BASE}/chat/completions`, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${GEMINI_KEY}` },
        body: JSON.stringify(oaiBody),
      });

      if (isStream) {
        res.writeHead(200, { "Content-Type": "text/event-stream", "x-request-id": "gemini-" + Date.now() });
        let first = true;
        for await (const line of apiRes.body) {
          const text = new TextDecoder().decode(line);
          const lines = text.split("\n").filter((l) => l.startsWith("data:"));
          for (const l of lines) {
            const data = l.slice(5).trim();
            if (data === "[DONE]") {
              res.end("data: [DONE]\n\n");
              return;
            }
            try {
              const chunk = JSON.parse(data);
              const ae = sseOpenAItoAnthropic(chunk);
              if (ae) {
                if (first) {
                  res.write(`data: ${JSON.stringify({ type: "message_start", message: { id: "msg_gemini", type: "message", role: "assistant", model, content: [], usage: { input_tokens: chunk.usage?.prompt_tokens || 0 } } })}\n\n`);
                  res.write(`data: ${JSON.stringify({ type: "content_block_start", index: 0, content_block: { type: "text", text: "" } })}\n\n`);
                  first = false;
                }
                res.write(`data: ${JSON.stringify(ae)}\n\n`);
              }
            } catch {}
          }
        }
        res.end("data: [DONE]\n\n");
        return;
      }

      const json = await apiRes.json();
      return res.end(JSON.stringify(openaiToAnthropic(json, model)));
    }

    // DeepSeek: passthrough
    const apiRes = await fetchSSE(`${DEEPSEEK_BASE}/v1/messages`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-api-key": DEEPSEEK_KEY },
      body: JSON.stringify(parsed),
    });

    if (isStream) {
      res.writeHead(200, { "Content-Type": "text/event-stream" });
      for await (const chunk of apiRes.body) res.write(new TextDecoder().decode(chunk));
      return res.end();
    }

    const json = await apiRes.json();
    return res.end(JSON.stringify(json));

  } catch (e) {
    console.error("Gateway error:", e.message);
    res.writeHead(502);
    return res.end(JSON.stringify({ error: { message: e.message, type: "gateway_error" } }));
  }
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`Model Gateway on http://127.0.0.1:${PORT}`);
  console.log("  gemini-* → Gemini API");
  console.log("  deepseek-* / other → DeepSeek API");
});
