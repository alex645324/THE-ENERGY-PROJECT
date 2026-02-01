
---

Use `tools/P.md` to execute the task below.

---

# **AI Agent Task: Deploy Flutter Web Build to GitHub Pages**

## Critical Information

**IMPORTANT**: This deployment requires a **full clean rebuild** to avoid stale caching issues.
Flutter generates a service worker file even when `--pwa-strategy=none` is used, so it **must be manually removed**.

**BASE-HREF WARNING**: For GitHub Pages project sites (like `momsbondgit.github.io/bas`), the `--base-href` must be set to `/bas/` (the repository name with slashes), NOT `/`. Using `/` will cause a **blank white screen** because the browser won't find the JavaScript assets at the correct paths.

**Deployment Target**

* Deployment branch: `deployment_7`
* Working branch: **current branch (or the branch I specify)**
* Folder served by GitHub Pages: `docs/`

---

## Deployment Steps

### 1. Clean Existing Web Build (on working branch)

```bash
rm -rf build/web
```

---

### 2. Build Flutter Web (Service Worker Disabled)

```bash
flutter build web --pwa-strategy=none --base-href /bas/
```

---

### 3. Manually Remove Service Worker (Required)

```bash
rm build/web/flutter_service_worker.js
```

Verify:

```bash
ls -la build/web/ | grep -i service || echo "✓ No service worker file"
```

---

### 4. Backup Fresh Build (Before Branch Switch)

```bash
cp -r build/web /tmp/fresh_build_$(date +%s)
```

---

### 5. Switch to Deployment Branch

If conflicts appear, remove generated folders first.

```bash
rm -rf .dart_tool build
git checkout deployment_7
```

---

### 6. Fully Wipe Existing `docs/` Folder

```bash
rm -rf docs/
```

---

### 7. Deploy Fresh Build into `docs/`

```bash
# Find latest backup
ls -dt /tmp/fresh_build_* | head -1

# Recreate docs and copy build
mkdir docs
cp -r /tmp/fresh_build_[timestamp]/* docs/
```

---

### 8. Remove Non-Web Platform Folders (If Present)

```bash
rm -rf android/ ios/ macos/
```

---

### 9. Verify No Service Worker in Deployment

```bash
ls -la docs/ | grep -i service || echo "✓ Confirmed: No service worker in docs/"
```

---

### 10. Commit and Push Deployment

```bash
git add -A
git status

git commit -m "Deploy: clean web rebuild with no service worker

- Manual removal of flutter_service_worker.js
- Complete wipe and recreate of docs/
- Prevents stale caching issues"

git push origin deployment_7
```

---

### 11. Return to Working Branch

```bash
git checkout <working-branch>
```

(`working-branch` = current branch or the branch I tell you to use)

---

## GitHub Pages Configuration

* Repository: `momsbondgit/bas`
* Branch: `deployment_7`
* Folder: `docs/`
* Deployment: automatic on push

---

## Troubleshooting

**If users see an old version**

1. Confirm `flutter_service_worker.js` is completely absent
2. Check GitHub Pages build status
3. Wait 1–2 minutes for propagation
4. Hard refresh (Cmd+Shift+R / Ctrl+Shift+R)

**If branch switch fails**

```bash
rm -rf .dart_tool build
git restore <modified_file>
```

**If build disappears**

* Restore from `/tmp/fresh_build_[timestamp]`
* Always back up **before** switching branches

---

## Key Rules

1. Always fully delete old builds
2. Always manually remove service worker
3. Always back up before branch switching
4. Verify file absence—not emptiness
5. GitHub Pages serves from `docs/`

---

## Goal

✅ Clean deploy
✅ No service worker
✅ No cached artifacts
✅ GitHub Pages serving from `docs/`

---