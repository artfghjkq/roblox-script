import fs from "fs";
import path from "path";

export default function handler(req, res) {
  const accept = req.headers["accept"] || "";

  if (accept.includes("text/html")) {
    res.setHeader("Content-Type", "text/html");
    return res.send(`
      <!DOCTYPE html>
      <html>
        <head><title>404 - Not Found</title></head>
        <body><h1>404</h1><p>Page not found.</p></body>
      </html>
    `);
  }

  const script = fs.readFileSync(path.join(process.cwd(), "core"), "utf8");
  res.setHeader("Content-Type", "text/plain");
  res.send(script);
}