# MacClean

**Storage Intelligence & Safe Cleanup Utility for macOS**

MacClean adalah aplikasi utilitas analisis dan pembersihan penyimpanan disk native untuk macOS yang dirancang dengan filosofi transparansi penuh, keandalan performa, dan keamanan mutlak (*Trash-Only Architecture*).

Aplikasi ini dibangun 100% menggunakan Swift dan SwiftUI murni tanpa dependensi eksternal, tanpa pelacakan (*zero telemetry*), dan berukuran sangat ringan (di bawah 1 MB).

---

## Daftar Isi
1. [Tentang MacClean](#tentang-macclean)
2. [Prinsip Keamanan Mutlak](#prinsip-keamanan-mutlak)
3. [Panduan Lengkap Informasi Antarmuka](#panduan-lengkap-informasi-antarmuka)
   - [Header Navigasi & Kontrol Global](#1-header-navigasi--kontrol-global)
   - [Hero Storage Visualizer](#2-hero-storage-visualizer)
   - [4 Kartu Kategori Bento](#3-4-kartu-kategori-bento)
   - [Tabel Detail Inspeksi Berkas](#4-tabel-detail-inspeksi-berkas)
   - [Floating Action Dock Terpadu](#5-floating-action-dock-terpadu)
   - [Lembar Penjelasan & Konfirmasi Pembersihan](#6-lembar-penjelasan--konfirmasi-pembersihan)
4. [Kategori Berkas yang Dideteksi](#kategori-berkas-yang-dideteksi)
5. [Persyaratan Sistem & Prasyarat (Prerequisites)](#persyaratan-sistem--prasyarat-prerequisites)
6. [Cara Instalasi & Menjalankan Aplikasi (Dengan / Tanpa Xcode)](#cara-instalasi--menjalankan-aplikasi-dengan--tanpa-xcode)
7. [Lisensi](#lisensi)

---

## Tentang MacClean

Banyak aplikasi pembersih disk tradisional di macOS yang membingungkan pengguna: menampilkan angka pembersihan yang tidak transparan, meminta izin administrator (*root*) yang berisiko, atau menghapus berkas secara permanen tanpa opsi pemulihan.

MacClean menjawab dua pertanyaan esensial pengguna Mac secara objektif dan aman:
1. **"Ruang disk Mac saya habis terpakai untuk apa saja secara akurat?"**
2. **"Berkas mana saja yang benar-benar aman dilepaskan sekarang tanpa merusak kestabilan sistem operasi atau menghilangkan berkas kerja penting saya?"**

---

## Prinsip Keamanan Mutlak

1. **Trash-Safe Only (100% Native macOS Trash)**:
   MacClean tidak pernah menjalankan perintah penghapusan permanen seperti `rm -rf` atau pembongkaran langsung (*unlink*). Semua berkas yang disetujui untuk dibersihkan selalu dipindahkan ke Tempat Sampah (*macOS Trash*) menggunakan API resmi Apple `FileManager.default.trashItem(at:resultingItemURL:)`. Pengguna dapat memeriksa atau memulihkan berkas tersebut kapan saja melalui Finder.
2. **Double-Layer Validation (Proteksi TOCTOU)**:
   Validasi kelayakan berkas dilakukan sebanyak dua kali:
   - Validasi pertama: Saat berkas dipindai dan dipilih pada tabel antarmuka.
   - Validasi kedua: Beberapa milidetik sebelum berkas dipindahkan ke Trash untuk mencegah *Time-of-Check to Time-of-Use* (TOCTOU) serta memastikan tidak ada penggantian berkas dengan tautan simbolik (*symlink attack*).
3. **Pengecualian Jalur Terlindungi (Hardcoded Protected Paths)**:
   MacClean secara ketat mengecualikan direktori inti macOS, kernel snapshot, dokumen pribadi (`~/Documents`, `~/Desktop`), pustaka foto, dan database penting dari kemungkinan pembersihan.

---

## Panduan Lengkap Informasi Antarmuka

Antarmuka MacClean didesain dengan tata letak padat, modern, dan adaptif (*Dark Obsidian* dan *Studio Light*). Berikut rincian seluruh elemen informasi yang ditampilkan:

### 1. Header Navigasi & Kontrol Global
- **Identitas Drive & APFS Tag**:
  - Menampilkan nama volume sistem aktif (misalnya `Macintosh HD`).
  - Label wadah APFS (`APFS Container disk3s1`) beserta kapasitas aktual drive yang terbaca langsung dari telemetri penyimpanan macOS.
  - Subtitel status sistem: *Kecerdasan Penyimpanan* (ID) atau *Storage Intelligence* (EN).
- **Pengalih Multi-Bahasa (Globe Button)**:
  - Tombol pengalih dwibahasa instan antara **Bahasa Indonesia (ID)** dan **English (EN)**. Seluruh teks antarmuka, judul kolom, penjelasan teknis, hingga dialog peringatan akan berganti secara langsung tanpa perlu memulai ulang aplikasi.
- **Pengalih Mode Gelap / Terang (Moon / Sun Button)**:
  - Tombol pengalih tema antara mode *Gelap* (*Dark Obsidian Canvas*) dan mode *Terang* (*Studio Light Canvas*) dengan kontras tinggi yang nyaman di mata.

### 2. Hero Storage Visualizer
- **Identitas Fisik Solid State Drive**:
  - Menampilkan tipe media internal (*Internal Solid State Drive*), indikator persentase kesehatan SSD, serta suhu operasional drive.
- **Badge Telemetri Penyimpanan**:
  - **TERPAKAI / USED**: Total ruang disk yang sedang digunakan dalam satuan GB beserta persentasenya terhadap kapasitas total.
  - **BEBAS / FREE**: Total ruang disk yang tersedia dengan indikator visual berdenyut.
  - **SMART Normal**: Status verifikasi integritas diagnostik perangkat keras drive APFS.
- **Visual Segmented Storage Bar**:
  - Batang proporsional berwarna yang memetakan komposisi disk:
    - Biru Neon: Aplikasi (*Applications*)
    - Sian: Data Pengembang (*Developer Data*)
    - Violet: Sistem & Berkas macOS (*System & macOS*)
    - Koral: Cache Sementara & Log (*Caches & Logs*)
    - Abu-abu Transparan: Ruang Bebas (*Free Space*)
  - Setiap segmen dilengkapi *tooltip* interaktif yang menampilkan angka byte aktual saat kursor diarahkan.
- **Pil Legenda Komposisi**:
  - Ringkasan warna dan angka kapasitas per kelompok berkas untuk pemahaman visual instan.

### 3. 4 Kartu Kategori Bento
Setiap kartu mewakili kelompok data dengan fungsi dan tingkat risiko spesifik:
- **Sisa Aplikasi (App Leftovers)**:
  - Berkas konfigurasi, Application Support, dan preferensi yang ditinggalkan oleh aplikasi yang telah dihapus (*uninstalled*) dari Mac.
  - Status badge: *Siap* (Aman dibersihkan sepenuhnya).
- **Cache Sistem (System Caches)**:
  - Cache WebKit, preview thumbnail usang, dan log sistem lama yang dapat dibuat ulang secara mandiri oleh macOS saat diperlukan.
  - Status badge: *Siap* (Aman dibersihkan).
- **Data Pengembang (Developer Data)**:
  - Build artifacts, DerivedData Xcode, cache manajer paket (CocoaPods, npm, Gradle, Maven).
  - Status badge: *Periksa* (Dapat dibuat ulang melalui kompilasi, namun memerlukan konfirmasi pengguna agar tidak menghapus dependensi aktif secara tidak sengaja).
- **Berkas & Arsip Besar (Large Files)**:
  - Berkas berukuran di atas 500 MB (berkas installer `.dmg`, arsip `.zip`/`.tar`, berkas disk image lama).
  - Status badge: *Ukuran Ambang Batas* (Misalnya `>500 MB`). Berkas dalam kategori ini tidak pernah dicentang otomatis oleh sistem rekomendasi demi menjaga berkas pribadi pengguna.

### 4. Tabel Detail Inspeksi Berkas
- **Toolbar Kontrol**:
  - **Tombol Pilih Rekomendasi / Batal Pilih**: Memilih atau membatalkan seluruh item yang terverifikasi aman dengan satu klik.
  - **Kolom Pencarian Real-Time**: Menyaring berkas berdasarkan nama berkas, jalur folder, maupun aplikasi pemilik secara instan.
  - **Menu Kategori**: Menyaring tabel untuk hanya menampilkan kategori tertentu (misalnya hanya Sisa Aplikasi).
  - **Menu Pengurutan**: Mengurutkan berkas berdasarkan Ukuran Terbesar, Ukuran Terkecil, Kategori, Nama Alfabetis, atau Tingkat Keyakinan Keamanan.
- **Kolom-Kolom Tabel**:
  - **Kotak Centang (Master & Row Checkbox)**: Memungkinkan seleksi granular per berkas.
  - **Nama Berkas & Penjelasan Manusiawi**: Nama file atau folder disertai penjelasan ringkas fungsi berkas tersebut (misalnya nama aplikasi yang ditinggalkan).
  - **Direktori Sistem**: Jalur lokasi berkas di penyimpanan disk dengan pemendekan karakter tilde (`~`) untuk direktori Home.
  - **Tingkat Keamanan (Safety Badge)**:
    - *Aman (Rekomendasi)*: Diverifikasi berisiko nol untuk dibersihkan.
    - *Periksa Ulang*: Berkas pengembang yang memerlukan peninjauan pengguna.
    - *Arsip Lama*: Berkas berukuran besar yang membutuhkan konfirmasi pribadi.
  - **Ukuran**: Ukuran aktual berkas pada disk fisik (KB, MB, atau GB).
  - **Aksi (Buka di Finder)**: Tombol pintasan langsung untuk membuka dan menyorot berkas di Finder macOS.

### 5. Floating Action Dock Terpadu
Dock mengambang di bagian bawah layar menjadi pusat kendali seluruh siklus pembersihan:
- **Kondisi Sebelum Pemindaian (Pre-Scan State)**:
  - Menampilkan status *"Pindai Sistem Siap Dilakukan"*.
  - Tombol utama aktif sebagai **"Mulai Pindai Cepat"** (*Start Quick Scan*) untuk memulai analisis disk menyeluruh.
- **Kondisi Saat Pemindaian (Scanning State)**:
  - Menampilkan indikator aktivitas, nama modul yang sedang diperiksa secara real-time, dan tombol **"Batal"** untuk menghentikan pemindaian seketika.
- **Kondisi Setelah Pemindaian (Post-Scan State)**:
  - Menampilkan jumlah item yang terpilih beserta total byte yang dapat dilepaskan.
  - Tombol sekunder: **"Pindai Ulang"** (*Rescan*).
  - Tombol primer: **"Bersihkan Sekarang (X GB)"** (*Clean Now*) yang memicu jendela peninjauan akhir.

### 6. Lembar Penjelasan & Konfirmasi Pembersihan
- **Lembar Penjelasan Item (Item Explanation Sheet)**:
  - Menjawab pertanyaan *"Mengapa item ini aman atau perlu ditinjau?"*.
  - Menjelaskan asal-usul berkas, fungsi aslinya, serta dampak apa yang terjadi pada aplikasi terkait setelah pembersihan dilakukan.
- **Jendela Tinjauan Akhir (Review Cleanup View)**:
  - Menyajikan daftar lengkap semua berkas yang akan dipindahkan.
  - Memverifikasi ulang integritas berkas dan menampilkan peringatan jika ada berkas yang berubah status.
  - Menampilkan rincian ruang per kategori dan dialog konfirmasi keselamatan sebelum eksekusi pemindahan ke Trash.
- **Kartu Hasil & Dampak (Cleanup Result View)**:
  - Menampilkan komparasi penyimpanan *Sebelum* (*BEFORE*) dan *Sesudah* (*AFTER*).
  - Menampilkan angka pasti penambahan ruang disk bebas yang berhasil diperoleh.
  - Tombol pintasan **"Buka Tempat Sampah di Finder"** untuk memeriksa berkas atau mengosongkan Trash secara permanen.

---

## Kategori Berkas yang Dideteksi

| Kategori | Deskripsi | Tingkat Rekomendasi | Perilaku Pembersihan |
| :--- | :--- | :--- | :--- |
| **Sisa Aplikasi** | Data residual aplikasi yang sudah tidak ada di `/Applications` | Aman (Rekomendasi Otomatis) | Dipindahkan ke Tempat Sampah |
| **Cache Sistem** | Log usang, cache browser WebKit, cache thumbnail gambar | Aman (Rekomendasi Otomatis) | Dipindahkan ke Tempat Sampah |
| **Data Pengembang** | Xcode DerivedData, build folder, package managers cache | Perlu Tinjauan (Manual) | Dipindahkan ke Tempat Sampah |
| **Berkas Besar** | Installer DMG lama, arsip ZIP/TAR berukuran >500 MB | Perlu Tinjauan (Manual) | Dipindahkan ke Tempat Sampah |

---

## Persyaratan Sistem & Prasyarat (Prerequisites)

Tergantung pada cara penggunaan yang Anda pilih, berikut adalah daftar prasyarat yang dibutuhkan:

### 1. Prasyarat Umum Perangkat Keras & Sistem Operasi
Berlaku untuk semua pengguna (baik mengunduh aplikasi jadi maupun membangun dari kode sumber):
- **Sistem Operasi**: macOS 14.0 (Sonoma), macOS 15.0 (Sequoia), atau versi yang lebih baru.
- **Arsitektur Perangkat Keras**: Universal Binary, mendukung penuh prosesor **Apple Silicon** (M1, M2, M3, M4, Pro, Max, Ultra) dan Mac berbasis **Intel 64-bit**.
- **Hak Akses Sistem**: Hanya memerlukan izin pengguna standar (*standard user account*). MacClean **tidak pernah** meminta kata sandi administrator (`sudo`/root).
- **Ruang Disk Bebas**: Minimal 10 MB untuk menampung aplikasi dan cache eksekusi sementara.

### 2. Matriks Prasyarat Berdasarkan Metode Instalasi

| Komponen Prasyarat | Pilihan 1: Aplikasi Siap Pakai (`.app`) | Pilihan 2: Terminal / Swift CLI | Pilihan 3: Xcode IDE |
| :--- | :--- | :--- | :--- |
| **Xcode IDE (~15 GB)** | **Tidak Perlu** | **Tidak Perlu** | Diperlukan (v15.0+) |
| **Apple Command Line Tools** | **Tidak Perlu** | Diperlukan (`xcode-select --install`) | Sudah termasuk di dalam Xcode |
| **Swift Compiler & SPM** | **Tidak Perlu** | Sudah termasuk di Command Line Tools | Sudah termasuk di dalam Xcode |
| **Git CLI** | **Tidak Perlu** | Opsional (untuk kloning repositori) | Opsional |
| **XcodeGen** | **Tidak Perlu** | **Tidak Perlu** | Opsional (jika edit `project.yml`) |

### 3. Pengaturan Izin Privasi macOS (Opsional / Anjuran)
- **Full Disk Access (Akses Disk Penuh)**:
  - macOS membatasi akses aplikasi ke beberapa folder tertentu melalui sistem keamanan TCC (*Transparency, Consent, and Control*).
  - MacClean secara otomatis menangani pembatasan ini dengan aman: folder yang dibatasi akan dilewati tanpa menyebabkan aplikasi berhenti atau *crash*.
  - Jika Anda menginginkan analisis penyimpanan yang 100% tuntas mencakup seluruh direktori sistem dan cache pengguna secara menyeluruh, Anda dapat memberikan izin *Full Disk Access*:
    1. Buka **System Settings** di Mac Anda.
    2. Pilih menu **Privacy & Security** > **Full Disk Access**.
    3. Aktifkan sakelar untuk **MacClean** (atau tanda `+` untuk menambahkan jika belum muncul).

---

## Cara Instalasi & Menjalankan Aplikasi (Dengan / Tanpa Xcode)

Anda dapat menggunakan MacClean dengan beberapa pilihan sesuai kebutuhan:

### Pilihan 1: Unduh Aplikasi Siap Pakai (Pengguna Umum — Tanpa Perlu Xcode atau Kompilasi)
Jika Anda adalah pengguna akhir yang ingin langsung memakai aplikasi tanpa memasang alat pengembang (*developer tools*):
1. Unduh arsip **`MacClean.zip`** dari tab [Releases](https://github.com/).
2. Ekstrak file zip tersebut untuk mendapatkan berkas **`MacClean.app`** (ukuran bundle sangat ringan, di bawah 1 MB).
3. Pindahkan `MacClean.app` ke direktori `/Applications`.
4. Buka aplikasi secara normal.

> [!NOTE]
> Karena aplikasi ini bertanda tangan ad-hoc (*self-signed*), jika macOS Gatekeeper menampilkan pesan peringatan saat pertama kali dibuka, silakan klik kanan pada icon `MacClean.app` lalu pilih **Open**, atau buka **System Settings > Privacy & Security** lalu klik **Open Anyway**.

---

### Pilihan 2: Menggunakan Terminal & Swift CLI (Hanya Butuh Command Line Tools ~500 MB, Tanpa Xcode IDE ~15 GB)
Jika Anda tidak menginstal aplikasi Xcode IDE yang berukuran besar (~15 GB), Anda tetap bisa mengompilasi dan menjalankan MacClean hanya bermodalkan **Apple Command Line Tools** bawaan macOS:
1. Pasang Command Line Tools jika belum ada (ukuran hanya sekitar 500 MB):
   ```bash
   xcode-select --install
   ```
2. Jalankan aplikasi langsung dari repositori:
   ```bash
   ./run.sh
   # atau
   swift run
   ```
3. Jika ingin membuat berkas bundle `MacClean.app` dan paket zip sendiri:
   ```bash
   ./build_release.sh
   ```
   Skrip ini akan mengompilasi kode dengan optimasi ukuran `-Osize`, melakukan *dead-code stripping*, membungkus struktur `.app`, menerapkan tanda tangan ad-hoc, dan menghasilkan arsip `MacClean.zip`.

---

### Pilihan 3: Menggunakan Xcode IDE (Untuk Pengembang / Developer)
Jika Anda memiliki Xcode 15.0 atau yang lebih baru:
1. Buka berkas proyek `MacClean.xcodeproj` di Xcode.
2. Pilih target dan skema `MacClean` dengan tujuan *My Mac*.
3. Tekan pintasan **Cmd + R** untuk menjalankan aplikasi secara langsung.
4. Jika ingin membuat ulang struktur proyek Xcode dari konfigurasi `project.yml`, Anda dapat menggunakan XcodeGen:
   ```bash
   xcodegen generate
   ```

#### Menjalankan Perintah Build & Unit Test via Terminal
```bash
# Menjalankan build debug aplikasi
xcodebuild -scheme MacClean -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO

# Menjalankan seluruh suite pengujian unit otomatis (73 test)
xcodebuild -scheme MacClean -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO
```

---

## Lisensi

Didistribusikan di bawah Lisensi MIT. Silakan lihat berkas [LICENSE](LICENSE) untuk informasi lebih lanjut.