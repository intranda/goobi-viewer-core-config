const gulp = require('gulp');
const path = require('path');
const fs = require('fs');
const os = require('os');
const XML = require('pixl-xml');
const through = require('through2');
const colors = require('ansi-colors');
const log = require('fancy-log');

const toPosix = (p) => (p ? p.replace(/\\/g, '/') : p);
const joinPosix = (...segs) => toPosix(path.join(...segs));

const paths = {
    srcRoot: 'src/main/resources',
    messagesGlob: 'messages_*.properties',
};

function resolveConfigDir() {
    const cfgPath =
        process.env.GV_VIEWER_CFG ||
        (process.platform.toLowerCase().startsWith('win')
            ? 'c:/opt/digiverso/viewer/config/config_viewer.xml'
            : '/opt/digiverso/viewer/config/config_viewer.xml');

    try {
        XML.parse(fs.readFileSync(cfgPath, 'utf-8'));
    } catch (e) {
        throw new Error(`Cannot parse ${cfgPath}: ${e.message}`);
    }
    return path.dirname(cfgPath);
}

const CONFIG_DIR = resolveConfigDir();
const pretty = (p) => toPosix(p.replace(os.homedir(), '~'));

function safeDestConfig() {
    if (!fs.existsSync(CONFIG_DIR) || !fs.statSync(CONFIG_DIR).isDirectory()) {
        log(colors.yellow(`[deploy] config dir missing, skipping: ${pretty(CONFIG_DIR)}`));
        return through.obj((f, _e, cb) => cb(null, f));
    }
    return gulp.dest(CONFIG_DIR);
}

/* ╔══════════════════════════════════════════════════════════════════════╗
   ║ Helpers                                                              ║
   ╚══════════════════════════════════════════════════════════════════════╝ */

const tStart = () => process.hrtime.bigint();
const elapsedMs = (t0) =>
    ((Number(process.hrtime.bigint() - t0) / 1e6) || 0).toFixed(0) + ' ms';

function logBlock(title, lines) {
    console.log(colors.white(`\n[${title}]`));
    lines.forEach((l) => console.log('  ' + l));
}
function taskFooter(copied, started) {
    return colors.green('✓ ') + colors.white(`${copied} copied · `) + colors.magenta(elapsedMs(started));
}

/* ╔══════════════════════════════════════════════════════════════════════╗
   ║ Copy helpers                                                         ║
   ╚══════════════════════════════════════════════════════════════════════╝ */

function syncAll() {
    const started = tStart();
    let copied = 0;
    const srcGlob = joinPosix(paths.srcRoot, paths.messagesGlob);
    return gulp
        .src(srcGlob, { allowEmpty: true })
        .pipe(
            through.obj((file, _, cb) => {
                if (file?.stat?.isFile()) copied++;
                cb(null, file);
            })
        )
        .pipe(safeDestConfig())
        .on('finish', () => {
            logBlock('sync-all', [
                `src: ${colors.green(srcGlob)}`,
                `dst: ${colors.blue(pretty(CONFIG_DIR))}`,
                taskFooter(copied, started),
            ]);
        });
}

function copyOne(filePath) {
    const started = tStart();
    return gulp
        .src(filePath, { allowEmpty: true })
        .pipe(safeDestConfig())
        .on('finish', () => {
            logBlock('messages', [
                `changed: ${colors.green(filePath)}`,
                `dst: ${colors.blue(pretty(path.join(CONFIG_DIR, path.basename(filePath))))}`,
                taskFooter(1, started),
            ]);
        });
}

/* ╔══════════════════════════════════════════════════════════════════════╗
   ║ Watch mode                                                           ║
   ╚══════════════════════════════════════════════════════════════════════╝ */

function dev() {
    const glob = joinPosix(paths.srcRoot, paths.messagesGlob);
    const opts = { ignoreInitial: true, awaitWriteFinish: { stabilityThreshold: 400, pollInterval: 50 } };
    gulp.watch(glob, opts)
        .on('add',  (p) => copyOne(p))
        .on('change', (p) => copyOne(p));
}

/* ╔══════════════════════════════════════════════════════════════════════╗
   ║ Target info                                                          ║
   ╚══════════════════════════════════════════════════════════════════════╝ */

function target(cb) {
    logBlock('targets', [
        `platform: ${colors.cyan(process.platform)}  node: ${colors.cyan(process.version)}`,
        `CONFIG_DIR   ${colors.green(fs.existsSync(CONFIG_DIR) ? '✓' : '✗')}  ${colors.blue(pretty(CONFIG_DIR))}`,
        colors.gray('hint: override config path with GV_VIEWER_CFG=/path/to/config_viewer.xml'),
    ]);
    cb();
}

exports.dev = dev;
exports['sync-all'] = syncAll;
exports.target = target;

/* ── Task exports ────────────────────────────────────────────────────────────────────────
   - npm run dev     → Watch messages_*.properties and mirror to CONFIG_DIR
   - npm run sync    → One-shot copy of all messages_* into CONFIG_DIR
   - npm run target  → Show resolved CONFIG_DIR

   Env flags:
   - GV_VIEWER_CFG   → absolute path to config_viewer.xml (its folder is the destination)
─────────────────────────────────────────────────────────────────────────────────────────── */