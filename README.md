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
5. [Persyaratan Sistem](#persyaratan-sistem)
6. [Kompilasi dan Menjalankan Proyek](#kompilasi-dan-menjalankan-proyek)
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

## Persyaratan Sistem

- **Sistem Operasi**: macOS 14.0 (Sonoma) atau versi yang lebih baru.
- **Arsitektur**: Universal Binary (Apple Silicon M1/M2/M3/M4 dan Intel 64-bit).
- **Hak Akses**: Izin pengguna standar macOS (tidak memerlukan akses root/sudo).

---

## Kompilasi dan Menjalankan Proyek

### Prasyarat
- Xcode 15.0 atau yang lebih baru.
- XcodeGen (opsional, untuk membuat ulang file `.xcodeproj` dari deklarasi `project.yml`).

### Menjalankan Proyek
Buka `MacClean.xcodeproj` di Xcode, pilih skema `MacClean`, dan tekan tombol **Run** (`Cmd + R`).

Atau melalui Terminal:
```bash
# Menjalankan build aplikasi
xcodebuild -scheme MacClean -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO

# Menjalankan rangkaian pengujian unit otomatis
xcodebuild -scheme MacClean -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO
```

---

## Lisensi

Didistribusikan di bawah Lisensi MIT. Silakan lihat berkas [LICENSE](LICENSE) untuk informasi lebih lanjut.
