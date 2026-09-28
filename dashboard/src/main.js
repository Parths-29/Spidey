'use strict';

// ===== NAV SCROLL =====
const nav = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 20);
}, { passive: true });

// ===== NAV HAMBURGER =====
const hamburger = document.getElementById('hamburger-btn');
const navLinks  = document.querySelector('.nav-links');
hamburger.addEventListener('click', () => {
  const open = navLinks.classList.toggle('open');
  hamburger.setAttribute('aria-expanded', String(open));
});
document.addEventListener('click', (e) => {
  if (!nav.contains(e.target)) navLinks.classList.remove('open');
});

// ===== WEB CANVAS BACKGROUND =====
(function initWebCanvas() {
  const canvas = document.getElementById('web-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  let W, H, nodes;
  const NODE_COUNT = 60;

  function resize() {
    W = canvas.width  = canvas.offsetWidth;
    H = canvas.height = canvas.offsetHeight;
  }

  function makeNodes() {
    nodes = Array.from({ length: NODE_COUNT }, () => ({
      x: Math.random() * W,
      y: Math.random() * H,
      vx: (Math.random() - 0.5) * 0.35,
      vy: (Math.random() - 0.5) * 0.35,
      r: Math.random() * 1.8 + 0.5
    }));
  }

  function draw() {
    ctx.clearRect(0, 0, W, H);

    // Draw connecting lines
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const dx = nodes[i].x - nodes[j].x;
        const dy = nodes[i].y - nodes[j].y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 130) {
          const alpha = (1 - dist / 130) * 0.18;
          ctx.beginPath();
          ctx.moveTo(nodes[i].x, nodes[i].y);
          ctx.lineTo(nodes[j].x, nodes[j].y);
          ctx.strokeStyle = `rgba(67, 97, 238, ${alpha})`;
          ctx.lineWidth = 0.8;
          ctx.stroke();
        }
      }
    }

    // Draw nodes
    for (const n of nodes) {
      ctx.beginPath();
      ctx.arc(n.x, n.y, n.r, 0, Math.PI * 2);
      ctx.fillStyle = 'rgba(76, 201, 240, 0.4)';
      ctx.fill();
    }
  }

  function update() {
    for (const n of nodes) {
      n.x += n.vx; n.y += n.vy;
      if (n.x < 0 || n.x > W) n.vx *= -1;
      if (n.y < 0 || n.y > H) n.vy *= -1;
    }
  }

  function loop() {
    update();
    draw();
    requestAnimationFrame(loop);
  }

  resize();
  makeNodes();
  loop();
  window.addEventListener('resize', () => { resize(); makeNodes(); }, { passive: true });
})();

// ===== CODE TABS =====
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => {
    const panelId = tab.getAttribute('aria-controls');
    document.querySelectorAll('.tab').forEach(t => {
      t.classList.remove('active');
      t.setAttribute('aria-selected', 'false');
    });
    document.querySelectorAll('.code-panel').forEach(p => {
      p.classList.remove('active');
      p.hidden = true;
    });
    tab.classList.add('active');
    tab.setAttribute('aria-selected', 'true');
    const panel = document.getElementById(panelId);
    if (panel) { panel.classList.add('active'); panel.hidden = false; }
  });
});

// ===== COPY BUTTONS =====
document.querySelectorAll('.copy-btn').forEach(btn => {
  btn.addEventListener('click', async () => {
    const targetId = btn.dataset.target;
    const code = document.getElementById(targetId)?.textContent ?? '';
    try {
      await navigator.clipboard.writeText(code);
      btn.textContent = '✓ Copied!';
      btn.classList.add('copied');
      setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 2000);
    } catch {
      btn.textContent = 'Failed';
      setTimeout(() => { btn.textContent = 'Copy'; }, 2000);
    }
  });
});

// ===== DEMO DASHBOARD =====
const FAKE_URLS = [
  'https://example.com/', 'https://example.com/about', 'https://example.com/contact',
  'https://example.com/blog', 'https://example.com/blog/post-1', 'https://example.com/blog/post-2',
  'https://example.com/products', 'https://example.com/products/widget-a',
  'https://example.com/products/widget-b', 'https://example.com/pricing',
  'https://example.com/docs', 'https://example.com/docs/getting-started',
  'https://example.com/docs/api-reference', 'https://example.com/docs/examples',
  'https://example.com/login', 'https://example.com/signup',
  'https://cdn.example.com/assets/main.css', 'https://example.com/sitemap.xml',
  'https://example.com/careers', 'https://example.com/team',
];

let demoInterval = null;
let demoTimer   = null;
let elapsed     = 0;
let isCrawling  = false;
const stats     = { requests: 0, success: 0, errors: 0, links: 0 };
let graphNodes  = [];

const logOutput    = document.getElementById('log-output');
const startBtn     = document.getElementById('start-demo-btn');
const resetBtn     = document.getElementById('reset-demo-btn');
const clearLogBtn  = document.getElementById('clear-log-btn');
const graphCanvas  = document.getElementById('graph-canvas');
const graphCtx     = graphCanvas.getContext('2d');

function padTime(n) { return String(n).padStart(2, '0'); }

function formatElapsed(sec) {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${padTime(m)}:${padTime(s)}`;
}

function updateStat(key, value, maxVal = 20) {
  const el  = document.getElementById(`val-${key}`);
  const fill = document.getElementById(`fill-${key}`);
  if (el)   el.textContent = value;
  if (fill) fill.style.width = `${Math.min((value / maxVal) * 100, 100)}%`;
}

function appendLog(msg, type = 'info') {
  const isAtBottom = logOutput.scrollHeight - logOutput.scrollTop <= logOutput.clientHeight + 10;
  if (logOutput.querySelector('.log-placeholder')) logOutput.innerHTML = '';
  const now = new Date();
  const ts  = `${padTime(now.getHours())}:${padTime(now.getMinutes())}:${padTime(now.getSeconds())}`;
  const div = document.createElement('div');
  div.className = `log-line ${type}`;
  div.innerHTML = `<span class="log-time">[${ts}]</span>${escapeHtml(msg)}`;
  logOutput.appendChild(div);
  if (isAtBottom) logOutput.scrollTop = logOutput.scrollHeight;
}

function escapeHtml(str) {
  return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function setProgress(pct) {
  document.getElementById('progress-fill').style.width = pct + '%';
  document.getElementById('progress-pct').textContent  = pct + '%';
}

// Graph rendering
function resizeGraphCanvas() {
  graphCanvas.width  = graphCanvas.offsetWidth;
  graphCanvas.height = graphCanvas.offsetHeight;
}
window.addEventListener('resize', resizeGraphCanvas, { passive: true });
resizeGraphCanvas();

function addGraphNode(url, status = 'queued') {
  const angle = Math.random() * Math.PI * 2;
  const r     = 30 + Math.random() * (Math.min(graphCanvas.width, graphCanvas.height) / 2 - 40);
  const cx    = graphCanvas.width  / 2;
  const cy    = graphCanvas.height / 2;
  graphNodes.push({
    x:      cx + Math.cos(angle) * r,
    y:      cy + Math.sin(angle) * r,
    label:  new URL(url).pathname || '/',
    status,
    r:      6
  });
  drawGraph();
}

function drawGraph() {
  const gCtx = graphCtx;
  const W    = graphCanvas.width;
  const H    = graphCanvas.height;
  gCtx.clearRect(0, 0, W, H);

  // Center node (root)
  const cx = W / 2, cy = H / 2;

  // Draw edges
  for (const n of graphNodes) {
    gCtx.beginPath();
    gCtx.moveTo(cx, cy);
    gCtx.lineTo(n.x, n.y);
    gCtx.strokeStyle = 'rgba(255,255,255,0.07)';
    gCtx.lineWidth   = 1;
    gCtx.stroke();
  }

  // Draw nodes
  for (const n of graphNodes) {
    const color = n.status === 'crawled' ? '#06d6a0'
                : n.status === 'error'   ? '#e63946'
                : '#4361ee';
    gCtx.beginPath();
    gCtx.arc(n.x, n.y, n.r, 0, Math.PI * 2);
    gCtx.fillStyle = color;
    gCtx.shadowColor = color;
    gCtx.shadowBlur  = 8;
    gCtx.fill();
    gCtx.shadowBlur  = 0;
  }

  // Center node
  gCtx.beginPath();
  gCtx.arc(cx, cy, 10, 0, Math.PI * 2);
  gCtx.fillStyle   = '#e63946';
  gCtx.shadowColor = '#e63946';
  gCtx.shadowBlur  = 16;
  gCtx.fill();
  gCtx.shadowBlur  = 0;
  gCtx.fillStyle   = '#fff';
  gCtx.font        = '12px Inter, sans-serif';
  gCtx.textAlign   = 'center';
  gCtx.textBaseline = 'middle';
  gCtx.fillText('🕷', cx, cy);
}

function resetDemo() {
  if (demoInterval) clearInterval(demoInterval);
  if (demoTimer)    clearInterval(demoTimer);
  demoInterval = null;
  demoTimer    = null;
  isCrawling   = false;
  elapsed      = 0;

  stats.requests = stats.success = stats.errors = stats.links = 0;
  updateStat('requests', 0); updateStat('success', 0);
  updateStat('errors', 0);   updateStat('links', 0);
  setProgress(0);
  document.getElementById('elapsed-time').textContent = '00:00';

  logOutput.innerHTML = `
    <div class="log-placeholder">
      <span class="spider-spin" aria-hidden="true">🕷</span>
      <span>Start a crawl to see live output…</span>
    </div>`;

  graphNodes = [];
  graphCtx.clearRect(0, 0, graphCanvas.width, graphCanvas.height);

  document.getElementById('demo-btn-text').textContent = '▶ Start Crawl';
  startBtn.disabled = false;
}

function startDemo() {
  if (isCrawling) return;
  isCrawling = true;
  startBtn.disabled = true;
  document.getElementById('demo-btn-text').textContent = '⏳ Crawling…';

  const baseUrl    = document.getElementById('demo-url').value || 'https://example.com';
  const depth      = parseInt(document.getElementById('demo-depth').value, 10) || 2;
  const rateLimit  = parseInt(document.getElementById('demo-rate').value, 10)  || 3;

  const totalJobs  = Math.min(FAKE_URLS.length, depth * 7);
  let   jobsDone   = 0;
  let   urlIdx     = 0;

  appendLog(`Spidey v1.0.0 initialised`, 'info');
  appendLog(`Starting crawl: ${baseUrl}`, 'info');
  appendLog(`Config — depth: ${depth}, rate: ${rateLimit} req/s`, 'info');

  // Elapsed timer
  demoTimer = setInterval(() => {
    elapsed++;
    document.getElementById('elapsed-time').textContent = formatElapsed(elapsed);
  }, 1000);

  // Crawl simulation
  const intervalMs = Math.max(400, Math.round(1000 / rateLimit));

  demoInterval = setInterval(() => {
    if (urlIdx >= FAKE_URLS.length || jobsDone >= totalJobs) {
      clearInterval(demoInterval);
      clearInterval(demoTimer);
      appendLog(`Crawl complete! ${stats.requests} requests, ${stats.success} OK, ${stats.errors} errors`, 'success');
      setProgress(100);
      document.getElementById('demo-btn-text').textContent = '✓ Done';
      isCrawling = false;
      return;
    }

    const url    = FAKE_URLS[urlIdx++];
    const isErr  = Math.random() < 0.07;
    const links  = Math.floor(Math.random() * 8) + 1;

    stats.requests++;
    if (isErr) {
      stats.errors++;
      appendLog(`✗ ERROR  ${url} — 404 Not Found`, 'error');
      addGraphNode(url, 'error');
    } else {
      stats.success++;
      stats.links += links;
      appendLog(`✓ GET    ${url} — 200 OK (${links} links)`, 'success');
      addGraphNode(url, 'crawled');
    }

    jobsDone++;
    updateStat('requests', stats.requests);
    updateStat('success',  stats.success);
    updateStat('errors',   stats.errors);
    updateStat('links',    stats.links, 80);

    const pct = Math.round((jobsDone / totalJobs) * 100);
    setProgress(pct);
  }, intervalMs);
}

startBtn.addEventListener('click', startDemo);
resetBtn.addEventListener('click', resetDemo);
clearLogBtn.addEventListener('click', () => {
  logOutput.innerHTML = `
    <div class="log-placeholder">
      <span class="spider-spin" aria-hidden="true">🕷</span>
      <span>Log cleared…</span>
    </div>`;
});

// ===== INTERSECTION OBSERVER (animate on scroll) =====
const observer = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      e.target.style.opacity    = '1';
      e.target.style.transform  = 'translateY(0)';
    }
  });
}, { threshold: 0.1 });

document.querySelectorAll('.feature-card, .doc-card').forEach(el => {
  el.style.opacity   = '0';
  el.style.transform = 'translateY(24px)';
  el.style.transition = 'opacity 0.55s ease, transform 0.55s ease';
  observer.observe(el);
});
