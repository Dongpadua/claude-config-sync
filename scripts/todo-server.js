// todo-server.js — Local REST API for claude-todo sidebar
// Usage: node todo-server.js [port]
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.argv[2] || 3899;
const REPO_DIR = process.env.TODO_REPO || path.join(process.env.USERPROFILE, '.claude-config-sync');
const DATA_FILE = path.join(REPO_DIR, 'todos', 'todo.json');
const HTML_FILE = path.join(REPO_DIR, 'todos', 'index.html');

function readTodos() {
  try {
    return JSON.parse(fs.readFileSync(DATA_FILE, 'utf-8'));
  } catch (e) {
    return { updated: new Date().toISOString(), tasks: [] };
  }
}

function writeTodos(data) {
  data.updated = new Date().toISOString();
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2), 'utf-8');
}

function uid() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

function sendJSON(res, code, data) {
  res.writeHead(code, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
  });
  res.end(JSON.stringify(data));
}

function serveFile(res, filePath, contentType) {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(content);
  } catch (e) {
    res.writeHead(404);
    res.end('Not found');
  }
}

function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', () => {
      try { resolve(JSON.parse(body)); } catch { resolve({}); }
    });
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET,POST,OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' });
    return res.end();
  }

  // API: GET /api/todos
  if (url.pathname === '/api/todos' && req.method === 'GET') {
    return sendJSON(res, 200, readTodos());
  }

  // API: POST /api/todos/add
  if (url.pathname === '/api/todos/add' && req.method === 'POST') {
    const body = await parseBody(req);
    const data = readTodos();
    const task = {
      id: uid(),
      title: body.title || 'Untitled',
      done: false,
      priority: body.priority || 'medium',
      due: body.due || '',
      note: body.note || '',
    };
    data.tasks.push(task);
    writeTodos(data);
    return sendJSON(res, 200, task);
  }

  // API: POST /api/todos/add-batch — Claude dumps multiple tasks at once
  if (url.pathname === '/api/todos/add-batch' && req.method === 'POST') {
    const body = await parseBody(req);
    const data = readTodos();
    const items = body.items || [];
    const added = [];
    for (const item of items) {
      if (!item || !item.trim()) continue;
      const task = {
        id: uid(),
        title: item.trim(),
        done: false,
        priority: body.priority || 'medium',
        due: '',
        note: '',
      };
      data.tasks.push(task);
      added.push(task);
    }
    if (added.length > 0) writeTodos(data);
    return sendJSON(res, 200, { added, count: added.length });
  }

  // API: POST /api/todos/toggle
  if (url.pathname === '/api/todos/toggle' && req.method === 'POST') {
    const body = await parseBody(req);
    const data = readTodos();
    const task = data.tasks.find((t) => t.id === body.id);
    if (task) {
      task.done = !task.done;
      writeTodos(data);
      return sendJSON(res, 200, task);
    }
    return sendJSON(res, 404, { error: 'Task not found' });
  }

  // API: POST /api/todos/delete
  if (url.pathname === '/api/todos/delete' && req.method === 'POST') {
    const body = await parseBody(req);
    const data = readTodos();
    const idx = data.tasks.findIndex((t) => t.id === body.id);
    if (idx !== -1) {
      data.tasks.splice(idx, 1);
      writeTodos(data);
      return sendJSON(res, 200, { deleted: body.id });
    }
    return sendJSON(res, 404, { error: 'Task not found' });
  }

  // API: POST /api/todos/edit
  if (url.pathname === '/api/todos/edit' && req.method === 'POST') {
    const body = await parseBody(req);
    const data = readTodos();
    const task = data.tasks.find((t) => t.id === body.id);
    if (task) {
      if (body.title !== undefined) task.title = body.title;
      if (body.priority !== undefined) task.priority = body.priority;
      if (body.due !== undefined) task.due = body.due;
      if (body.note !== undefined) task.note = body.note;
      writeTodos(data);
      return sendJSON(res, 200, task);
    }
    return sendJSON(res, 404, { error: 'Task not found' });
  }

  // Static: index.html
  if (url.pathname === '/' || url.pathname === '/index.html') {
    return serveFile(res, HTML_FILE, 'text/html; charset=utf-8');
  }

  // 404
  sendJSON(res, 404, { error: 'Not found' });
});

server.listen(PORT, () => {
  console.log(`Todo server running at http://localhost:${PORT}`);
});
