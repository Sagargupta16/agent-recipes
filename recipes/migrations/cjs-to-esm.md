# CommonJS to ES Modules Migration

> Convert a Node.js project from CommonJS (require/module.exports) to ES Modules (import/export) with proper configuration and edge case handling.

## When to Use

- When modernizing a Node.js project to use native ES modules
- When a dependency you rely on has gone ESM-only (e.g., many popular npm packages)
- When aligning a Node.js project with frontend code that already uses ESM
- When preparing for better tree-shaking and static analysis

## The Prompt

```
You are a Node.js module system expert. Convert this CommonJS project to ES Modules. This migration involves more than just changing require() to import, there are subtle runtime differences that must be handled correctly to avoid breaking the application.

## STEP 1: CONFIGURATION CHANGES

### package.json
- Add `"type": "module"` to package.json
- If some files must remain CommonJS (e.g., config files for tools that don't support ESM), rename them to .cjs

### tsconfig.json (if TypeScript)
- Set `"module": "Node16"` or `"module": "NodeNext"`
- Set `"moduleResolution": "Node16"` or `"moduleResolution": "NodeNext"`
- Ensure `"esModuleInterop": true` is set

### Other config files
- Check if these tools need .cjs extensions: jest.config.js, .eslintrc.js, babel.config.js, prettier.config.js, knexfile.js, etc.
- Many tools now support ESM configs, but verify each one

## STEP 2: CONVERT IMPORTS AND EXPORTS

### Basic conversions
```javascript
// CommonJS                              // ESM
const fs = require('fs');                import fs from 'fs';
const { readFile } = require('fs');      import { readFile } from 'fs';
const myModule = require('./myModule');   import myModule from './myModule.js';
module.exports = myFunc;                 export default myFunc;
module.exports = { a, b, c };            export { a, b, c };
module.exports.myFunc = myFunc;          export { myFunc };  // or: export function myFunc() {}
exports.myFunc = myFunc;                 export { myFunc };
```

### CRITICAL: File extensions are REQUIRED in ESM
```javascript
// CommonJS (extensions optional)
const utils = require('./utils');
const config = require('./config/index');

// ESM (extensions MANDATORY)
import utils from './utils.js';          // Must include .js
import config from './config/index.js';  // Must include /index.js
```

This is the #1 source of migration bugs. Every relative import MUST have a file extension.

### Directory imports don't work in ESM
```javascript
// CommonJS (works)
const routes = require('./routes');  // resolves to ./routes/index.js

// ESM (DOES NOT WORK)
import routes from './routes';       // Error: directory import not supported

// ESM (correct)
import routes from './routes/index.js';
```

## STEP 3: HANDLE COMMONJS-SPECIFIC PATTERNS

### __dirname and __filename
These do not exist in ESM. Replace with:
```javascript
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
```

Only add these if the file actually uses __dirname or __filename.

### require.resolve
```javascript
// CommonJS
const modulePath = require.resolve('./myModule');

// ESM
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const modulePath = require.resolve('./myModule');
```

### Dynamic require()
```javascript
// CommonJS
const plugin = require(dynamicPath);

// ESM
const plugin = await import(dynamicPath);
// NOTE: import() is async and returns a promise! The containing function must be async.
// NOTE: import() returns a module namespace object. Access .default for default exports.
```

### JSON imports
```javascript
// CommonJS
const config = require('./config.json');

// ESM Option 1: Import assertion (Node 18.20+, Node 20.10+, Node 21+)
import config from './config.json' with { type: 'json' };

// ESM Option 2: Read and parse (works in all Node versions)
import { readFileSync } from 'fs';
const config = JSON.parse(readFileSync(new URL('./config.json', import.meta.url), 'utf-8'));

// ESM Option 3: createRequire
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const config = require('./config.json');
```

### Conditional imports
```javascript
// CommonJS (works at any level)
if (process.env.NODE_ENV === 'test') {
  const mock = require('./mock');
}

// ESM (top-level import() is async)
let mock;
if (process.env.NODE_ENV === 'test') {
  mock = await import('./mock.js');  // top-level await, only in ESM
}
```

## STEP 4: HANDLE INTEROP WITH COMMONJS DEPENDENCIES

Some npm packages are still CommonJS-only. They generally work with ESM imports, but watch for:

```javascript
// If a CJS package uses module.exports = function() { ... }
// Default import works:
import express from 'express';  // works

// If a CJS package uses module.exports = { a, b }
// Named imports may or may not work depending on Node's static analysis:
import { a, b } from 'cjs-package';  // might fail

// Safe fallback: import default and destructure
import cjsPackage from 'cjs-package';
const { a, b } = cjsPackage;
```

## STEP 5: UPDATE SCRIPTS AND TOOLING

- Update any shell scripts that use `node -e "require(...)"` to use `node -e "import(...)"`
- Update Jest config (either use --experimental-vm-modules, or switch to Vitest which supports ESM natively)
- Update ESLint config (may need flat config or .cjs extension)
- Update any build scripts that assume CJS

## OUTPUT FORMAT

1. List all configuration file changes (package.json, tsconfig.json, etc.)
2. For each source file, provide the converted version
3. List all files that need .cjs extension (tool configs that don't support ESM)
4. List all edge cases found (dynamic requires, __dirname usage, JSON imports, CJS interop issues)
5. List any test/tooling changes needed
6. Provide a verification checklist: commands to run to verify the migration works
```

## Example

### Input

```javascript
// src/server.js
const express = require('express');
const path = require('path');
const { loadConfig } = require('./config');
const routes = require('./routes');
const pkg = require('../package.json');

const config = loadConfig();
const app = express();

app.use(express.json());
app.use('/static', express.static(path.join(__dirname, 'public')));
app.use('/api', routes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: pkg.version });
});

app.listen(config.port, () => {
  console.log(`Server running on port ${config.port}`);
});

module.exports = app;
```

### Output

```javascript
// src/server.js
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { readFileSync } from 'fs';
import { loadConfig } from './config/index.js';
import routes from './routes/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pkg = JSON.parse(
  readFileSync(new URL('../package.json', import.meta.url), 'utf-8')
);

const config = loadConfig();
const app = express();

app.use(express.json());
app.use('/static', express.static(path.join(__dirname, 'public')));
app.use('/api', routes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: pkg.version });
});

app.listen(config.port, () => {
  console.log(`Server running on port ${config.port}`);
});

export default app;
```

**Changes made:**
1. `require('express')` -> `import express from 'express'` (CJS default interop works for express)
2. `require('path')` -> `import path from 'path'`
3. Added `fileURLToPath` import and `__dirname` polyfill (used in `express.static`)
4. `require('../package.json')` -> `readFileSync` + `JSON.parse` (most compatible approach)
5. `require('./config')` -> `import from './config/index.js'` (added file extension and explicit index.js)
6. `require('./routes')` -> `import from './routes/index.js'`
7. `module.exports = app` -> `export default app`

**Verification checklist:**
- [ ] `node src/server.js` starts without errors
- [ ] All API routes respond correctly
- [ ] Static file serving works (`/static/` path)
- [ ] Health endpoint returns version from package.json

## Customization Tips

- **For TypeScript projects**, add: "Change file extensions from .ts to .ts (no change needed) but update all import paths to use .js extensions (TypeScript compiles .ts to .js, so imports should reference the output extension)."
- **For monorepos**, add: "Each package must have its own `type: module` in package.json. Cross-package imports must use the package name, not relative paths. Verify workspace tooling (Turborepo, Nx, Lerna) supports ESM."
- **For gradual migration**, add: "Instead of converting everything at once, keep `type: commonjs` (default) and rename individual files to .mjs as they are converted. This allows incremental migration without breaking the entire project."
- **For libraries that are published to npm**, add: "Set up dual CJS/ESM exports in package.json using the `exports` field with `import` and `require` conditions. This ensures consumers using either module system can import your library."

## Tags

`migration` `esm` `commonjs` `node` `modules` `javascript`
