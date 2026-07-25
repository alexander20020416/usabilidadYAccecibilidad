const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const rootDirectory = __dirname;
const port = Number(process.env.PORT) || 8080;

const contentTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.jpeg': 'image/jpeg',
  '.jpg': 'image/jpeg',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.mp4': 'video/mp4',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.webm': 'video/webm',
  '.webp': 'image/webp'
};

function sendText(response, statusCode, message) {
  response.writeHead(statusCode, { 'Content-Type': 'text/plain; charset=utf-8' });
  response.end(message);
}

const server = http.createServer((request, response) => {
  let pathname;

  try {
    pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
  } catch {
    sendText(response, 400, 'Bad request');
    return;
  }

  if (pathname === '/') {
    pathname = '/index.html';
  }

  let filePath = path.resolve(rootDirectory, `.${pathname}`);
  const allowedRoot = `${path.resolve(rootDirectory)}${path.sep}`;

  if (!filePath.startsWith(allowedRoot)) {
    sendText(response, 403, 'Forbidden');
    return;
  }

  fs.stat(filePath, (statError, stats) => {
    if (!statError && stats.isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }

    fs.readFile(filePath, (readError, content) => {
      if (readError) {
        sendText(response, readError.code === 'ENOENT' ? 404 : 500, 'Page not found');
        return;
      }

      const contentType = contentTypes[path.extname(filePath).toLowerCase()]
        || 'application/octet-stream';
      response.writeHead(200, {
        'Content-Type': contentType,
        'X-Content-Type-Options': 'nosniff'
      });

      if (request.method === 'HEAD') {
        response.end();
        return;
      }

      response.end(content);
    });
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`English Up is running on port ${port}`);
});
