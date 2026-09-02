// Run a wasi_wasm32 build of the smoke test under Node's WASI runtime.
// Used by the "Generate bindings" workflow so the wasm target is actually
// executed, not just linked. Usage: node scripts/run_wasi.mjs <file.wasm>
import { WASI } from 'node:wasi';
import { readFile } from 'node:fs/promises';

const path = process.argv[2];
if (!path) {
	console.error('usage: node scripts/run_wasi.mjs <file.wasm>');
	process.exit(2);
}

const wasi = new WASI({ version: 'preview1', args: [path], env: {}, returnOnExit: true });
const module = await WebAssembly.compile(await readFile(path));
const instance = await WebAssembly.instantiate(module, wasi.getImportObject());

const code = wasi.start(instance);
if (code !== 0) {
	console.error(`wasm exited with code ${code}`);
}
process.exitCode = code;
