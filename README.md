# MacClean 🧼

**Storage Intelligence & Safe Cleanup for macOS**

MacClean is an ultra-lightweight, native macOS utility designed to answer two fundamental questions:
1. **"What is using my Mac's storage?"** (Storage Explorer & Top Space Consumers)
2. **"What can I safely clean right now?"** (Smart Clean Intelligence)

Built 100% with Swift and native SwiftUI. Zero telemetry, zero bloat, and zero external dependencies. The entire app bundle is **under 1 MB**.

---

## Key Features

### 1. Smart Clean
- **3-Second Comprehension**: Clear distinction between *Total Storage Used* and verified *Safe Cleanup Recommendation*.
- **3 Human Buckets**:
  - **App Leftovers**: Residual data from applications no longer installed on your Mac.
  - **Application Caches**: Regenerable cache files and temporary assets.
  - **Developer Caches**: Build artifacts (Xcode DerivedData, Gradle, npm, etc.).
- **Single-Click Review**: One primary review action with before-and-after storage statistics.

### 2. Storage Explorer
- **Composition Breakdown**: Segmented, color-coded storage estimate (Applications, Your Files, App Data, Caches, Developer Data, System).
- **Top Space Consumers**: Ranked largest disk consumers with instant **Reveal in Finder** buttons.
- **Large Files Inspector**: Deep bounded scanning (depth ≤ 3) with dynamic thresholds (`500+ MB`, `1+ GB`, `5+ GB`, `10+ GB`) and intelligent file classification (*Disk Images*, *Archives*, *Videos*, *VM Disks*, *Projects*).
- **Search & Filter**: Real-time filtering by status, category, full file path, and raw byte sorting.

### 3. Absolute Safety Guarantees
- **100% Native Trash**: Every cleanup operation calls `FileManager.default.trashItem(at:resultingItemURL:)`. **Zero** permanent deletion (`rm -rf` is never used).
- **Double-Layer Validation**: Validated at selection time and re-validated immediately before trash execution to prevent Time-of-Check to Time-of-Use (TOCTOU) and symlink replacement attacks.
- **Never Touches Protected Paths**: Core macOS system files, iCloud Drive, Photos Library, and user documents are strictly protected by hardcoded safety rules.

---

## Quick Start

```bash
# Jalankan aplikasi langsung
./run.sh

# Atau kompilasi jadi MacClean.app (< 1 MB)
./build_release.sh
```

### Download Pre-Built
Download `MacClean.zip` (~390 KB) dari [GitHub Releases](https://github.com/), ekstrak, dan pindahkan `MacClean.app` ke `/Applications`.

---

## System Requirements
- **macOS**: 14.0 (Sonoma) or later
- **Architecture**: Universal (Apple Silicon & Intel 64-bit)
- **Permissions**: Standard macOS user permissions

---

## License
Distributed under the MIT License. See [LICENSE](LICENSE) for details.
