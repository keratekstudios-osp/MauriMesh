const http = require("http");

const html = `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <meta http-equiv="Cache-Control" content="no-store" />
  <title>MauriMesh Direct Preview</title>
  <style>
    body{margin:0;background:#020403;color:white;font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
    header{height:72px;background:#050b16;display:flex;align-items:center;gap:14px;padding:0 22px;border-bottom:1px solid rgba(255,255,255,.08)}
    main{padding:22px;max-width:900px;margin:0 auto}
    .dot{width:14px;height:14px;border-radius:50%;background:#00D084;box-shadow:0 0 20px #00D084}
    .hero,.card,.mesh{border:1px solid rgba(34,197,94,.32);background:rgba(2,12,8,.88);border-radius:24px;padding:22px;margin-top:18px}
    .pill{display:inline-block;color:#00D084;border:1px solid rgba(34,197,94,.45);border-radius:999px;padding:8px 12px;font-size:12px;font-weight:900}
    h1{font-size:42px;margin:20px 0 10px}
    p{color:rgba(255,255,255,.72);line-height:1.55}
    .grid{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-top:18px}
    .mesh{height:310px;position:relative;background:#020806}
    .node{position:absolute;width:72px;height:72px;border-radius:50%;border:1px solid #00D084;background:rgba(0,208,132,.16);display:grid;place-items:center;font-weight:900;text-align:center}
    .a{left:16%;top:25%}.b{left:46%;top:52%}.c{left:76%;top:25%}.d{left:62%;top:74%;opacity:.45}
    .truth{border-left:3px solid #F59E0B;padding-left:12px}
    @media(max-width:700px){.grid{grid-template-columns:1fr}h1{font-size:36px}}
  </style>
</head>
<body>
  <header>
    <div style="font-size:30px;color:rgba(255,255,255,.72)">☰</div>
    <div class="dot"></div>
    <strong style="font-size:24px">MauriMesh</strong>
  </header>

  <main>
    <section class="hero">
      <span class="pill">DIRECT REPLIT SERVER · NO API WAIT</span>
      <h1>MauriMesh Messenger</h1>
      <p>This direct server bypasses the old cached React bundle and proves the Replit static UI layer is reachable.</p>
    </section>

    <section class="grid">
      <div class="card"><span class="pill">READY</span><h2>Web UI Layer</h2><p>Direct preview route is live from Replit Shell.</p></div>
      <div class="card"><span class="pill">PROTECTED</span><h2>BLE Runtime</h2><p>Native BLE, ACK, relay, and store-forward remain APK/device validation work.</p></div>
      <div class="card"><span class="pill">SIMULATION</span><h2>Living Mesh</h2><p>Local preview nodes are shown without API calls.</p></div>
      <div class="card"><span class="pill">SERVER ONLY</span><h2>System Brain</h2><p>Node fs/path file logic stays outside browser bundling.</p></div>
    </section>

    <section class="mesh">
      <div class="node a">A<br>96%</div>
      <div class="node b">B<br>82%</div>
      <div class="node c">C<br>74%</div>
      <div class="node d">D<br>31%</div>
    </section>

    <p class="truth">Truth: this proves the Replit web/static UI route. Real BLE discovery, native ACK routing, offline delivery, background Bluetooth, and live mesh API still require APK/device testing.</p>
  </main>
</body>
</html>`;

function handler(req, res) {
  res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
  res.setHeader("Pragma", "no-cache");
  res.setHeader("Expires", "0");

  if (req.url.startsWith("/api/health")) {
    res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify({ ok: true, service: "maurimesh-dual-port-server" }));
    return;
  }

  if (req.url.startsWith("/api/mesh/status")) {
    res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify({
      mode: "SIMULATION",
      truth: "Direct Replit fallback. Not live BLE.",
      nodes: [
        { id: "A", label: "Phone A", status: "online", signal: 96 },
        { id: "B", label: "Relay B", status: "relay", signal: 82 },
        { id: "C", label: "Phone C", status: "online", signal: 74 },
        { id: "D", label: "Store Forward D", status: "offline", signal: 31 }
      ]
    }));
    return;
  }

  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.end(html);
}

for (const port of [3000, 5000]) {
  const server = http.createServer(handler);
  server.on("error", (err) => {
    console.log(`Port ${port} failed: ${err.code}`);
  });
  server.listen(port, "0.0.0.0", () => {
    console.log(`MauriMesh direct server running on 0.0.0.0:${port}`);
  });
}
