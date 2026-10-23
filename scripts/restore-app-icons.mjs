import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

mkdirSync('public', { recursive: true });
for (const size of [180, 192, 512]) {
  const encoded = readFileSync(`assets/playart-icon-${size}.png.b64`, 'utf8').trim();
  writeFileSync(`public/playart-icon-${size}.png`, Buffer.from(encoded, 'base64'));
}
