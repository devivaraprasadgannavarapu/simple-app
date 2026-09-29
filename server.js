const http = require('node:http');

const port = Number(process.env.PORT || 8080);
const runtime = {
  podName: process.env.POD_NAME || 'unknown',
  namespace: process.env.POD_NAMESPACE || 'unknown',
  nodeName: process.env.NODE_NAME || 'unknown',
  podIp: process.env.POD_IP || 'unknown',
  nodeIp: process.env.NODE_IP || 'unknown'
};

function page() {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sample App Runtime</title>
  <style>
    :root { color-scheme: dark; font-family: Inter, ui-sans-serif, system-ui, sans-serif; }
    body { margin: 0; min-height: 100vh; background: #101820; color: #eef4f1; }
    main { width: min(980px, calc(100% - 32px)); margin: 0 auto; padding: 56px 0; }
    .eyebrow { color: #65d6b4; font-size: 12px; font-weight: 700; letter-spacing: .14em; text-transform: uppercase; }
    h1 { margin: 12px 0 8px; font-size: clamp(34px, 7vw, 68px); line-height: .98; max-width: 720px; }
    .intro { color: #a9bbb5; font-size: 18px; max-width: 650px; line-height: 1.6; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 14px; margin-top: 36px; }
    .item { padding: 20px; border: 1px solid #29433e; background: #15231f; border-radius: 8px; }
    .label { color: #8ca59e; font-size: 12px; text-transform: uppercase; letter-spacing: .1em; }
    .value { margin-top: 10px; color: #ffffff; font: 600 16px ui-monospace, SFMono-Regular, Consolas, monospace; overflow-wrap: anywhere; }
    .flow { margin-top: 36px; padding-top: 24px; border-top: 1px solid #29433e; color: #c6d5d0; line-height: 1.7; }
    .flow strong { color: #65d6b4; }
  </style>
</head>
<body>
  <main>
    <div class="eyebrow">Sample application · live runtime</div>
    <h1>Running inside the cluster.</h1>
    <p class="intro">This page is served by the application pod currently handling your request. Refreshing may show another pod because two replicas are running.</p>
    <section class="grid" aria-label="Runtime details">
      <div class="item"><div class="label">Pod name</div><div class="value">${runtime.podName}</div></div>
      <div class="item"><div class="label">Namespace</div><div class="value">${runtime.namespace}</div></div>
      <div class="item"><div class="label">Node name</div><div class="value">${runtime.nodeName}</div></div>
      <div class="item"><div class="label">Pod IP</div><div class="value">${runtime.podIp}</div></div>
      <div class="item"><div class="label">Node IP</div><div class="value">${runtime.nodeIp}</div></div>
      <div class="item"><div class="label">Container port</div><div class="value">${port}</div></div>
    </section>
    <p class="flow"><strong>Request path:</strong> public load balancer → cluster service → one of the application pods → Node.js HTTP server.</p>
  </main>
</body>
</html>`;
}

const server = http.createServer((request, response) => {
  if (request.url === '/health') {
    response.writeHead(200, { 'content-type': 'application/json' });
    response.end(JSON.stringify({ status: 'ok', pod: runtime.podName }));
    return;
  }

  response.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
  response.end(page());
});

server.listen(port, '0.0.0.0', () => {
  console.log(`sample-app listening on port ${port}`);
});
