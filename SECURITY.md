# Security Architecture & Safety Policy

## 1. Safety Principles & Guarantees

> **Core Guarantee**: MacClean moves validated cleanup candidates to the macOS Trash. It does not permanently delete files, does not empty the Trash, and never executes destructive commands like `rm` or `rm -rf`.

1. **Scan First, Confirm Before Action**:
   Every action requires explicit user initiation and confirmation. No file mutation occurs during scanning or review.
2. **Fail Closed**:
   If there is ambiguity, uncertainty, missing permissions, or an unexpected file type, MacClean rejects the item (`REJECT`). It never guesses.
3. **Defense in Depth**:
   Safety checks are not only performed during scan and review in `CleanupValidator`, but re-executed immediately before trashing inside `TrashManager` (TOCTOU protection).
4. **No Elevated Privileges**:
   MacClean never executes `sudo`, never calls `AuthorizationExecuteWithPrivileges`, and never invokes external shell commands (`/bin/sh`, `zsh`, `bash`). All filesystem operations use native macOS Foundation APIs.

---

## 2. Cleanup Scope & Boundary Enforcement

- **Scope**: User home directory (`~`) only.
- **Strict Containment**:
  - Naive prefix matching is strictly forbidden. MacClean uses normalized path component matching (`ProtectedPaths.isContained`) to reject sibling directory attacks (e.g. `/Users/test2` mistakenly matching `/Users/test`).
  - The home directory itself (`~`) is protected and can never be selected or moved.
  - External volumes (`/Volumes`), root filesystem (`/`), and other users' home directories are strictly forbidden.

---

## 3. Protected Paths Matrix

MacClean enforces protection at both system and user levels:

### System Protected Paths
- `/System` and `/System/Applications`
- `/Library` (Root Library)
- `/Applications` (System-wide Applications)
- `/usr`, `/bin`, `/sbin`
- `/private`, `/var`, `/etc`, `/tmp`
- `/opt`, `/Volumes`, `/dev`

### User Protected Directories
- User root directory (`~`)
- Personal Documents & Desktop (`~/Documents`, `~/Desktop`, `~/Downloads`)
- Media directories (`~/Movies`, `~/Music`, `~/Pictures`)
- Security & Cloud credentials (`~/.ssh`, `~/.gnupg`, `~/.aws`)
- Personal data in `~/Library`:
  - `~/Library/Keychains`
  - `~/Library/Mobile Documents` (iCloud Drive)
  - `~/Library/Mail`, `~/Library/Messages`, `~/Library/Safari`, `~/Library/Photos`, `~/Library/Cookies`
  - Apple system Application Support directories (e.g., `AddressBook`, `CallHistoryDB`, `Knowledge`, etc.)

---

## 4. Symlink & Traversal Defense

1. **Symlink Rejection**:
   - Symbolic links (including dangling/broken symlinks) are strictly rejected from cleanup candidates.
   - Symlink checks use `lstat(2)` and `NSFileTypeSymbolicLink` attributes to avoid blindly following redirected targets.
   - Any path whose canonical path resolves outside the home directory or into a protected location is rejected.
2. **Path Traversal Prevention**:
   - Relative path tokens (`..`, `./`, redundant slashes) are rejected and sanitized.
   - All filesystem checks operate on standardized, canonical URLs (`standardizedFileURL.resolvingSymlinksInPath()`).

---

## 5. TOCTOU & Race Condition Safety

Between scanning and user confirmation, files on the filesystem may be modified, moved, or deleted.
Immediately before moving any item to the Trash:
1. `TrashManager` executes `validator.validate(item)`.
2. `TrashManager` verifies the file still exists, is not a symlink, is strictly contained in the home directory, and is not protected.
3. If a file was deleted or changed between scan and trash:
   - It is marked as `.disappeared` or `.rejected`.
   - The operation proceeds without crashing.
   - No error dialog blocks the rest of the batch.
4. If a file is locked or permission is denied:
   - It is caught gracefully by the native `FileManager.default.trashItem` handler and marked as `.failed`.
   - MacClean does not prompt for `sudo`.

---

## 6. Privacy & Logging

1. **Cleanup History Privacy**:
   - `CleanupHistoryManager` persists only execution metadata: timestamp, total item count, and total bytes moved.
   - No individual filenames, document names, file contents, hashes, or full directory paths are stored in history.
2. **System Logging (`os.Logger`)**:
   - `Logger` messages do not expose raw personal filenames or sensitive home directory paths.
   - Log interpolations use privacy qualifiers (e.g., `privacy: .public` for enum categories, omitting personal paths).
