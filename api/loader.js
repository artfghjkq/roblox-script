import fs from "fs";
import path from "path";

export default function handler(req, res) {
  const script = fs.readFileSync(path.join(process.cwd(), "core"), "utf8");
  res.setHeader("Content-Type", "text/plain");
  res.send(script);
}