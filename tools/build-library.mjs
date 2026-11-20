import { createRequire } from 'node:module'
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
import { dirname, join, relative, resolve, sep } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const libraryRoot = resolve(process.argv[2] ?? join(here, '..'))
const oipRoot = resolve(process.argv[3] ?? '')
if (!process.argv[3]) {
  console.error('Usage: node tools/build-library.mjs <library-root> <OIP-source-root>')
  process.exit(2)
}

const require = createRequire(join(oipRoot, 'package.json'))
const { createServer } = require('vite')
const vite = await createServer({
  configFile: false,
  root: oipRoot,
  logLevel: 'error',
  server: { middlewareMode: true, hmr: false, ws: false },
  appType: 'custom',
  optimizeDeps: { noDiscovery: true },
})

const safeChild = (base, child) => {
  const full = resolve(base, child)
  const rel = relative(base, full)
  if (rel === '' || rel === '..' || rel.startsWith(`..${sep}`) || resolve(full) !== full) throw new Error(`Path escapes source folder: ${child}`)
  return full
}

try {
  const { partToOippartBytes, oippartBytesToFolder } = await vite.ssrLoadModule('/src/core/parts/partArchive.ts')
  const { buildPackage } = await vite.ssrLoadModule('/src/sim/buildPackage.ts')
  const { partFingerprint } = await vite.ssrLoadModule('/src/core/parts/partOrigin.ts')
  const { sha256HexOfBytes } = await vite.ssrLoadModule('/src/core/sha256.ts')
  const { LIBRARY_INDEX_FORMAT, checkLibraryDownload, validateLibraryIndex } = await vite.ssrLoadModule('/src/core/parts/partLibrary.ts')
  const { PART_SDK_LEVEL } = await vite.ssrLoadModule('/src/core/parts/partSdk.ts')

  const indexPath = join(libraryRoot, 'index.json')
  const index = existsSync(indexPath)
    ? JSON.parse(readFileSync(indexPath, 'utf8'))
    : {
        format: LIBRARY_INDEX_FORMAT,
        id: 'userlijun0727.industrial-parts',
        name: 'My Industrial Parts Library',
        licence: { code: 'All rights reserved', assets: 'All rights reserved' },
        parts: [],
      }
  const sourceRoot = join(libraryRoot, 'source')
  const sourceDirs = readdirSync(sourceRoot, { withFileTypes: true }).filter((x) => x.isDirectory()).map((x) => x.name).sort()
  if (sourceDirs.length === 0) throw new Error(`No source part folders found in ${sourceRoot}`)

  for (const dirName of sourceDirs) {
    const folder = join(sourceRoot, dirName)
    const manifest = JSON.parse(readFileSync(join(folder, 'manifest.json'), 'utf8'))
    const behavior = readFileSync(join(folder, 'behavior.js'), 'utf8')
    const entryPath = join(folder, 'library-entry.json')
    const entry = existsSync(entryPath) ? JSON.parse(readFileSync(entryPath, 'utf8')) : {}
    if (entry.id) manifest.id = entry.id
    else if (!String(manifest.id).startsWith('userlijun0727.')) manifest.id = `userlijun0727.${dirName.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`
    if (entry.name) manifest.name = entry.name
    if (entry.category) manifest.category = entry.category
    delete manifest.origin
    delete manifest.credit

    manifest.assets = (manifest.assets ?? []).map((asset) => {
      if (typeof asset.file !== 'string') return asset
      const assetPath = safeChild(folder, asset.file)
      const bytes = readFileSync(assetPath)
      const { file: _file, ...rest } = asset
      return { ...rest, data: bytes.toString('base64') }
    })

    let pkg = buildPackage(manifest, behavior)
    const fingerprint = partFingerprint(pkg)
    const sourceSdkLevel = Number.isInteger(manifest.sdk?.level) && manifest.sdk.level > 0 ? manifest.sdk.level : PART_SDK_LEVEL
    pkg = { ...pkg, sdk: { level: sourceSdkLevel, of: fingerprint } }
    const bytes = await partToOippartBytes(pkg)
    const sha256 = sha256HexOfBytes(bytes)
    const version = { file: `${pkg.id}/${sha256}.oippart`, sha256, fingerprint, sdk: sourceSdkLevel, published: new Date().toISOString().slice(0, 10) }
    const roundTrip = await oippartBytesToFolder(bytes)
    if ('error' in roundTrip) throw new Error(`${pkg.id}: archive read-back failed: ${roundTrip.error}`)
    const rebuilt = buildPackage(JSON.parse(roundTrip.manifestJson), roundTrip.behaviorJs)
    const downloadProblem = checkLibraryDownload(version, pkg.id, bytes, rebuilt)
    if (downloadProblem) throw new Error(`${pkg.id}: library verification failed: ${downloadProblem}`)

    let listing = index.parts.find((p) => p.id === pkg.id)
    if (!listing) {
      listing = { id: pkg.id, name: pkg.name, versions: [] }
      index.parts.push(listing)
    }
    listing.name = pkg.name
    if (pkg.category) listing.category = pkg.category
    else delete listing.category
    if (entry.description) listing.description = String(entry.description).replace(/\s+/g, ' ').trim()
    const latest = listing.versions.at(-1)
    if (latest?.fingerprint === fingerprint) {
      console.log(`= ${pkg.id}: unchanged, no duplicate version`)
      continue
    }
    const filePath = join(libraryRoot, version.file)
    if (existsSync(filePath)) {
      const oldHash = sha256HexOfBytes(new Uint8Array(readFileSync(filePath)))
      if (oldHash !== sha256) throw new Error(`Refusing to overwrite a different file: ${filePath}`)
    } else {
      mkdirSync(dirname(filePath), { recursive: true })
      writeFileSync(filePath, bytes)
    }
    listing.versions.push(version)
    console.log(`+ ${pkg.id}: ${version.file} (${(bytes.length / 1024).toFixed(0)} KB)`)
  }

  index.parts.sort((a, b) => a.id.localeCompare(b.id))
  const checked = validateLibraryIndex(index)
  if ('problems' in checked) throw new Error(`index.json invalid: ${checked.problems.join('; ')}`)
  writeFileSync(indexPath, `${JSON.stringify(index, null, 2)}\n`)
  console.log(`PASS: ${index.parts.length} part(s) in ${indexPath}`)
} finally {
  await vite.close()
}
