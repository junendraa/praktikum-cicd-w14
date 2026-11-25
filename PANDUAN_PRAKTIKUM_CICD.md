# MODUL PRAKTIKUM
# CI/CD & Deployment Workflow dengan Git, GitHub Actions, Python, dan Ubuntu Server

**Studi kasus:** Otomatisasi validasi dan deployment file DAG pemrosesan data penjualan  
**Level:** Praktikum dasar–menengah  
**Perkiraan durasi:** 2–3 pertemuan (masing-masing 2–3 jam)  
**Platform CI/CD:** GitHub Actions  
**Lingkungan target:** Ubuntu Server 22.04/24.04 LTS pada VM  
**Bahasa:** Python 3.11  
**Tools validasi:** Black, Flake8, dan `unittest`

---

## 1. Hubungan praktikum dengan materi teori

Modul ini mengikuti topik dalam materi teori CI/CD & Deployment Workflow:

| Materi teori | Implementasi praktikum |
|---|---|
| CI, Continuous Delivery, Continuous Deployment | Memahami validasi otomatis dan deployment setelah validasi |
| Git dan repository | `init`, `add`, `commit`, `push`, branch, riwayat |
| GitOps | Repository sebagai sumber acuan kode yang akan diterapkan |
| Pipeline, workflow, job, step, runner | Workflow GitHub Actions dengan job `validate` dan `deploy` |
| Black dan Flake8 | Pemeriksaan format dan linting |
| Unit testing | `unittest` untuk fungsi transformasi penjualan |
| Trigger push | Push ke `main` memicu pipeline |
| Deployment DAG | Salin direktori DAG dan modul pendukung ke release di server target |
| Verification | Memastikan file tersedia pada release aktif |
| Secret dan least privilege | Runner khusus, user non-root, akses direktori terbatas |
| Rollback | Mengubah symlink `current` ke release sebelumnya |

### Batasan implementasi yang perlu dipahami

Materi teori tidak menetapkan platform orkestrasi DAG tertentu. Oleh karena itu, file `dags/sales_daily_dag.py` pada praktikum ini adalah **definisi DAG Python demonstrasi yang netral-platform**, bukan sintaks Apache Airflow, Prefect, atau Dagster. Praktikum berfokus pada proses Git → pipeline → validasi → pemindahan file → verifikasi. Pada sistem nyata, sintaks DAG dan pemeriksaan pemuatan DAG harus disesuaikan dengan platform orkestrasi yang dipakai.

Untuk membuat target deployment dapat dipraktikkan tanpa membuka port SSH ke internet, digunakan **GitHub self-hosted runner pada VM Ubuntu target**. Runner mengambil job dari GitHub melalui koneksi keluar. Gunakan VM khusus dan repository privat untuk latihan ini; jangan memasang runner pada server produksi.

---

## 2. Studi kasus

Sebuah tim data mengembangkan workflow untuk merangkum transaksi penjualan harian. Developer mengubah file Python dan definisi DAG pada repository. Setiap perubahan yang di-push ke branch `main` harus melalui pemeriksaan otomatis.

### Kebutuhan sistem

1. Dataset penjualan berbentuk CSV.
2. Kode Python membaca dataset dan menghitung jumlah transaksi serta omzet per tanggal.
3. Black memeriksa konsistensi format kode.
4. Flake8 memeriksa gaya dan temuan kode tertentu.
5. Unit test memeriksa hasil fungsi transformasi.
6. Pipeline hanya boleh melanjutkan deployment jika seluruh validasi lulus.
7. File `dags/` dan modul pendukung `src/` diterapkan ke VM Ubuntu target.
8. Sistem menyimpan setiap deployment sebagai release terpisah.
9. Symlink `current` menunjuk release aktif; `previous` menunjuk release sebelumnya.
10. Mahasiswa dapat melakukan rollback dan membuktikan versi aktif berubah.

### Alur akhir

```text
Developer
   |
   v
Git add -> commit -> push main
   |
   v
GitHub repository
   |
   v
GitHub Actions: job validate (runner GitHub)
   |
   +--> Black --check
   |
   +--> Flake8
   |
   +--> Python unittest
   |
   v
Semua validasi lulus?
   | Tidak                  | Ya
   v                        v
Pipeline gagal         job deploy
                            |
                            v
                  Self-hosted runner
                  pada VM Ubuntu target
                            |
                            v
                  Buat release baru
                            |
                            v
                  Alihkan symlink current
                            |
                            v
                  Verifikasi file DAG
```

---

## 3. Target kompetensi praktikum

Setelah praktikum, mahasiswa dapat:

1. Menyiapkan lingkungan pengembangan Python dan Git.
2. Membuat repository dan mengelola perubahan dengan Git.
3. Menjelaskan hubungan push, workflow, job, step, dan runner.
4. Menjalankan Black, Flake8, dan unit test secara lokal.
5. Membuat workflow GitHub Actions.
6. Menyiapkan self-hosted runner secara aman pada VM target.
7. Mengotomatisasi deployment file DAG setelah validasi lulus.
8. Memeriksa release aktif dan melakukan rollback.
9. Mendiagnosis kegagalan validasi atau deployment.

---

## 4. Arsitektur dan kebutuhan environment

### 4.1 Perangkat keras minimum

| Komponen | Rekomendasi |
|---|---|
| Komputer mahasiswa | 4 core CPU, RAM 8 GB, ruang kosong 20 GB |
| VM Ubuntu target | 2 vCPU, RAM 2 GB, disk 15–20 GB |
| Jaringan | Internet untuk GitHub dan instalasi paket |
| Virtualisasi | VirtualBox, Hyper-V, VMware, atau cloud VM |

VM target dapat menggunakan NAT. Self-hosted runner memerlukan koneksi keluar ke layanan GitHub; praktikum ini tidak memerlukan port SSH masuk dari internet.

### 4.2 Perangkat lunak

| Tools | Fungsi |
|---|---|
| Windows 10/11, Linux, atau macOS | Komputer pengembangan |
| Ubuntu Server 22.04/24.04 LTS | Mesin target dan self-hosted runner |
| Git | Version control |
| Python 3.11 | Runtime kode |
| `venv` dan `pip` | Isolasi dan instalasi paket Python |
| Visual Studio Code (opsional) | Editor kode |
| GitHub account | Repository dan GitHub Actions |
| Black | Formatter / pemeriksaan format |
| Flake8 | Linter |
| Python `unittest` | Unit test |
| GitHub Actions runner | Menjalankan job deployment di VM target |

### 4.3 Pilihan topologi

```text
+-------------------------+       HTTPS keluar       +--------------------+
| Laptop / PC mahasiswa   | -----------------------> | GitHub             |
| Git + Python + editor   |                           | Repository         |
+-------------------------+                           | Actions CI         |
                                                      +---------+----------+
                                                                |
                                                  job deploy (polling HTTPS)
                                                                |
                                                                v
                                                      +--------------------+
                                                      | Ubuntu target VM   |
                                                      | Self-hosted runner |
                                                      | /opt/data-cluster  |
                                                      +--------------------+
```

Job validasi menggunakan runner GitHub-hosted (`ubuntu-latest`). Job deployment menggunakan self-hosted runner yang telah dipasang pada VM target. Dengan `needs: validate`, job deployment tidak berjalan jika validasi gagal.

---

## 5. Persiapan instalasi

### Praktik 1 — Menyiapkan komputer pengembangan

#### 5.1 Windows: instalasi Git

1. Unduh Git for Windows dari https://git-scm.com/download/win.
2. Jalankan installer.
3. Gunakan pilihan default jika tidak ada kebijakan khusus.
4. Buka PowerShell atau Git Bash.
5. Verifikasi:

```powershell
git --version
```

#### 5.2 Windows: instalasi Python

1. Unduh Python 3.11 dari https://www.python.org/downloads/.
2. Jalankan installer.
3. Aktifkan opsi **Add Python to PATH**.
4. Verifikasi:

```powershell
py -3.11 --version
py -3.11 -m pip --version
```

Jika memakai WSL Ubuntu, lakukan instalasi Git dan Python di dalam WSL, lalu jalankan seluruh perintah Linux pada terminal WSL. Hindari mencampur interpreter Windows dan WSL dalam satu virtual environment.

#### 5.3 Ubuntu: instalasi Git dan Python

```bash
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip
git --version
python3 --version
```

Pastikan Python yang digunakan adalah versi yang sesuai. Workflow contoh menggunakan Python 3.11.

#### 5.4 Editor kode (opsional)

Unduh Visual Studio Code dari https://code.visualstudio.com/. Instal ekstensi Python bila diperlukan. Editor bukan syarat agar pipeline berjalan.

---

## 6. Menyiapkan VM Ubuntu sebagai target deployment

### Praktik 2 — Instalasi dan konfigurasi server target

1. Buat VM baru dengan Ubuntu Server 22.04/24.04 LTS.
2. Atur minimal 2 vCPU, RAM 2 GB, dan disk 15 GB.
3. Hubungkan adapter jaringan ke NAT atau bridge sesuai fasilitas jaringan.
4. Selesaikan instalasi Ubuntu dan buat user administrator VM.
5. Login ke VM, lalu perbarui paket:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl tar gzip ca-certificates python3 python3-venv
```

6. Pastikan jam dan koneksi internet tersedia:

```bash
date
curl -I https://github.com
```

7. Buat user khusus untuk runner. Jangan menjalankan runner sebagai root:

```bash
sudo adduser --disabled-password --gecos "" ghrunner
```

8. Buat direktori deployment dan berikan kepemilikan hanya kepada user runner:

```bash
sudo mkdir -p /opt/data-cluster/releases
sudo chown -R ghrunner:ghrunner /opt/data-cluster
sudo chmod 750 /opt/data-cluster
```

9. Pastikan user runner dapat menulis:

```bash
sudo -u ghrunner test -w /opt/data-cluster && echo "Akses tulis OK"
```

**Mengapa memakai user khusus?** Prinsip least privilege membatasi dampak apabila job atau kredensial runner disalahgunakan. User runner tidak perlu menjadi administrator sistem.

---

## 7. Membuat akun dan repository GitHub

### Praktik 3 — Menyiapkan repository

1. Buka https://github.com/ dan login.
2. Pilih **New repository**.
3. Beri nama `cicd-dag-sales-practicum`.
4. Pilih **Private** untuk praktikum self-hosted runner.
5. Jangan centang pembuatan README jika akan mengunggah proyek yang sudah disiapkan.
6. Buat repository.
7. Di komputer pengembangan, ekstrak paket proyek.
8. Masuk ke direktori proyek:

```bash
cd cicd-deployment-practicum
```

Jika direktori hasil ekstraksi memiliki nama lain, sesuaikan path `cd`.

9. Atur identitas Git:

```bash
git config --global user.name "Nama Mahasiswa"
git config --global user.email "email-github-anda"
```

Gunakan email yang terdaftar pada GitHub atau alamat noreply GitHub jika tidak ingin menampilkan email pribadi.

10. Inisialisasi repository dan push:

```bash
git init
git branch -M main
git add .
git status
git commit -m "Initial commit: CI/CD DAG sales practicum"
git remote add origin https://github.com/USERNAME/cicd-dag-sales-practicum.git
git push -u origin main
```

Ganti `USERNAME` dengan username GitHub sendiri. Jika diminta autentikasi HTTPS, gunakan mekanisme autentikasi GitHub yang didukung (misalnya browser login/Git Credential Manager); jangan menaruh token di perintah atau file.

11. Buka repository GitHub dan pastikan struktur proyek muncul.

### 7.1 Struktur proyek

```text
cicd-deployment-practicum/
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── dags/
│   └── sales_daily_dag.py
├── src/
│   ├── __init__.py
│   └── sales_transform.py
├── tests/
│   ├── __init__.py
│   └── test_sales_transform.py
├── data/
│   └── sales.csv
├── scripts/
│   ├── deploy.sh
│   └── rollback.sh
├── .flake8
├── .gitignore
├── pyproject.toml
├── requirements-dev.txt
└── README.md
```

---

## 8. Menyiapkan Python environment dan menguji aplikasi lokal

### Praktik 4 — Virtual environment

Dari root repository:

**Linux/macOS/WSL:**

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements-dev.txt
```

**Windows PowerShell:**

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements-dev.txt
```

Jika PowerShell membatasi aktivasi script, gunakan Git Bash atau terminal WSL; jangan mengubah kebijakan keamanan komputer tanpa memahami dampaknya.

Verifikasi:

```bash
python --version
black --version
flake8 --version
```

### 8.1 Memahami data praktikum

Dataset `data/sales.csv` berisi 8 transaksi contoh. Kolomnya:

| Kolom | Makna |
|---|---|
| `order_id` | Identitas transaksi |
| `order_date` | Tanggal transaksi |
| `product` | Nama produk |
| `quantity` | Jumlah unit |
| `unit_price` | Harga per unit dalam rupiah |

Contoh data:

```csv
order_id,order_date,product,quantity,unit_price
ORD-001,2026-10-01,Kopi,2,25000
ORD-002,2026-10-01,Teh,3,12000
ORD-003,2026-10-01,Roti,4,15000
```

Dataset ini sintetis untuk latihan, bukan data transaksi riil.

### 8.2 Menjalankan fungsi transformasi

```bash
python -m dags.sales_daily_dag
```

Hasil yang diharapkan berupa ringkasan per tanggal. Dengan dataset awal:
- 1 Oktober 2026: 3 transaksi, omzet Rp146.000.
- 2 Oktober 2026: 3 transaksi, omzet Rp121.000.
- 3 Oktober 2026: 2 transaksi, omzet Rp84.000.
- Total omzet: Rp351.000.

### 8.3 Menjalankan Black

Periksa format tanpa mengubah file:

```bash
black --check .
```

Jika ada file belum sesuai format:

```bash
black .
black --check .
```

### 8.4 Menjalankan Flake8

```bash
flake8 .
```

Jika ditemukan pelanggaran, baca nama file, nomor baris, dan kode temuan. Perbaiki sumbernya, lalu ulangi pemeriksaan.

### 8.5 Menjalankan unit test

```bash
python -m unittest discover -s tests -v
```

Hasil yang diharapkan: seluruh test lulus (`OK`). Bila ada test gagal, jangan lanjut ke deployment sebelum penyebabnya diperbaiki.

**Catatan koreksi data:** Total omzet yang benar dari 8 baris dataset adalah **Rp318.000**. Gunakan nilai ini sebagai hasil acuan praktikum.

---

## 9. Memahami source code dan dataset

### 9.1 `src/sales_transform.py`

File ini menyediakan tiga fungsi:
- `load_sales()`: membaca CSV, memeriksa kolom, dan mengonversi nilai numerik.
- `summarize_sales()`: menghitung jumlah transaksi dan omzet per tanggal.
- `total_revenue()`: menghitung total omzet seluruh transaksi.

### 9.2 `dags/sales_daily_dag.py`

File ini mendefinisikan:
- `DAG_ID`
- deskripsi workflow
- jadwal konseptual
- daftar task
- hubungan dependensi task
- fungsi `run_demo()` untuk menjalankan contoh proses

File ini sengaja tidak mengimpor framework orkestrasi. Jika kampus menggunakan Apache Airflow atau platform lain, file ini dapat dijadikan dasar untuk membuat DAG platform tersebut.

### 9.3 `tests/test_sales_transform.py`

Unit test memeriksa jumlah transaksi, total omzet, ringkasan tanggal, dan perilaku fungsi terhadap input tidak valid. Test merupakan contoh pemeriksaan fungsi, bukan pengganti integration test terhadap database atau platform orkestrasi.

---

## 10. Menyiapkan self-hosted runner pada VM target

### Praktik 5 — Registrasi runner

1. Pastikan repository GitHub bersifat **Private** dan VM target merupakan VM praktikum khusus.
2. Buka repository GitHub.
3. Masuk ke **Settings → Actions → Runners**.
4. Pilih **New self-hosted runner**.
5. Pilih Linux dan arsitektur VM (umumnya x64).
6. GitHub akan menampilkan perintah download, ekstraksi, dan konfigurasi runner. Ikuti perintah yang tampil pada halaman tersebut karena URL dan token registrasi bersifat dinamis.
7. Jalankan perintah instalasi sebagai user `ghrunner`, bukan root.

Contoh perpindahan user:

```bash
sudo su - ghrunner
mkdir -p ~/actions-runner
cd ~/actions-runner
```

Lanjutkan dengan perintah **Download**, **Configure**, dan **Run** yang diberikan GitHub pada halaman Add runner. Jangan menyalin token registrasi ke laporan, screenshot, atau repository. Token registrasi bersifat sementara dan rahasia.

8. Pada langkah konfigurasi runner, berikan label tambahan:

```text
cicd-target
```

Workflow contoh mencari runner dengan label `self-hosted`, `linux`, `x64`, dan `cicd-target`.

9. Uji runner dengan menjalankan perintah `run.sh` sesuai instruksi GitHub. Pastikan status runner pada halaman Settings berubah menjadi **Idle/Online**.
10. Untuk penggunaan berkelanjutan, pasang runner sebagai service mengikuti petunjuk resmi yang muncul pada versi runner yang diunduh. Jalankan konfigurasi service sesuai dokumentasi GitHub dan user khusus `ghrunner`.

Dokumentasi resmi: https://docs.github.com/actions/hosting-your-own-runners/managing-self-hosted-runners

### 10.1 Pemeriksaan akses deployment

Pada VM target, sebagai administrator:

```bash
sudo -u ghrunner test -w /opt/data-cluster
echo $?
```

Nilai `0` berarti user dapat menulis. Pastikan runner benar-benar berjalan sebagai `ghrunner`. Jangan memberi `sudo` tanpa password atau hak root kepada runner untuk memudahkan deployment.

### 10.2 Catatan keamanan self-hosted runner

- Gunakan repository privat dan VM khusus praktikum.
- Jangan jalankan workflow dari fork atau pull request yang tidak dipercaya pada runner ini.
- Jangan menyimpan secret dalam source code.
- Batasi siapa yang dapat mengubah workflow dan branch `main`.
- Jangan gunakan runner praktikum untuk server produksi.
- Matikan runner jika praktikum selesai dan tidak digunakan.
- Perbarui runner sesuai pemberitahuan keamanan GitHub.

---

## 11. Memahami konfigurasi pipeline GitHub Actions

File `.github/workflows/ci-cd.yml` sudah disiapkan dalam proyek.

### 11.1 Trigger

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
```

Makna:
- Push ke branch `main` memicu pipeline.
- `workflow_dispatch` memungkinkan workflow dijalankan manual dari antarmuka GitHub.

### 11.2 Job validate

Job ini berjalan pada runner GitHub-hosted:
1. Checkout source code.
2. Setup Python 3.11.
3. Install Black dan Flake8.
4. Jalankan `black --check .`.
5. Jalankan `flake8 .`.
6. Jalankan `python -m unittest discover -s tests -v`.

Jika salah satu perintah gagal, job `validate` berstatus gagal.

### 11.3 Job deploy

Job deployment memiliki:

```yaml
needs: validate
if: github.ref == 'refs/heads/main'
runs-on: [self-hosted, linux, x64, cicd-target]
```

Artinya:
- Deployment menunggu job `validate`.
- Deployment hanya berlaku pada branch `main`.
- Job dijalankan pada self-hosted runner di VM target.

`needs: validate` adalah gerbang penting: job deploy tidak akan berjalan apabila validasi gagal.

### 11.4 Memahami mekanisme release

Script deployment:
- membuat direktori release berdasarkan commit dan run ID;
- menyalin `dags/`, `src/`, dan `data/`;
- memeriksa keberadaan file wajib;
- menyimpan penunjuk release lama pada `previous`;
- mengalihkan symlink `current` ke release baru.

Struktur target:

```text
/opt/data-cluster/
├── releases/
│   ├── <commit-a>-<run-id>/
│   │   ├── dags/
│   │   ├── src/
│   │   └── data/
│   └── <commit-b>-<run-id>/
├── current  -> releases/<release-aktif>
└── previous -> releases/<release-sebelumnya>
```

Dengan pola ini, file release sebelumnya tidak langsung dihapus. Ini memudahkan demonstrasi rollback.

---

## 12. Menjalankan deployment pertama

### Praktik 6 — Trigger dengan `git push`

1. Pastikan runner VM berstatus Online.
2. Pastikan workflow sudah ada pada repository.
3. Dari komputer pengembangan, ubah satu baris deskripsi atau komentar pada `dags/sales_daily_dag.py`.
4. Jalankan:

```bash
git status
git add dags/sales_daily_dag.py
git commit -m "Update deskripsi DAG penjualan"
git push origin main
```

5. Buka tab **Actions** pada repository GitHub.
6. Buka workflow `CI-CD-DAG`.
7. Amati job `validate`.
8. Pastikan Black, Flake8, dan unit test lulus.
9. Amati job `deploy` berjalan pada self-hosted runner.
10. Pastikan job deployment berhasil.

### 12.1 Verifikasi di VM target

Pada VM Ubuntu:

```bash
ls -la /opt/data-cluster
readlink -f /opt/data-cluster/current
find -L /opt/data-cluster/current -maxdepth 2 -type f -print
```

Pastikan file berikut tersedia:

```text
/opt/data-cluster/current/dags/sales_daily_dag.py
/opt/data-cluster/current/src/sales_transform.py
/opt/data-cluster/current/data/sales.csv
```

Uji bahwa file DAG dan modul pendukung dapat diimpor dari release:

```bash
cd /opt/data-cluster/current
python3 -m dags.sales_daily_dag
```

Jika perintah terakhir tidak dapat menemukan modul karena direktori `dags` bukan package Python, uji dengan:

```bash
PYTHONPATH=/opt/data-cluster/current python3 /opt/data-cluster/current/dags/sales_daily_dag.py
```

---

## 13. Eksperimen kegagalan pipeline

### Praktik 7 — Membuktikan pipeline menghentikan deployment

Tujuan: menunjukkan bahwa kode yang tidak lolos validasi tidak diterapkan.

1. Pada komputer pengembangan, ubah kode dengan menambahkan variabel tidak terpakai pada salah satu file Python:

```python
unused_variable = 123
```

2. Simpan file.
3. Jalankan lokal:

```bash
flake8 .
```

4. Amati temuan Flake8.
5. Commit dan push perubahan:

```bash
git add .
git commit -m "Experiment: introduce lint error"
git push origin main
```

6. Buka GitHub Actions.
7. Pastikan job `validate` gagal.
8. Pastikan job `deploy` tidak berjalan (skipped), karena bergantung pada `validate`.
9. Pada VM target, periksa release aktif:

```bash
readlink -f /opt/data-cluster/current
```

10. Pastikan release aktif tidak berubah.

### 13.1 Memperbaiki kegagalan

1. Hapus variabel tidak terpakai.
2. Jalankan kembali:

```bash
black .
flake8 .
python -m unittest discover -s tests -v
```

3. Commit dan push perbaikan.
4. Pastikan pipeline kembali berhasil dan deployment berjalan.

---

## 14. Eksperimen unit test gagal

### Praktik 8 — Membuktikan unit test menjadi gerbang deployment

1. Ubah nilai ekspektasi pada salah satu assertion di `tests/test_sales_transform.py` sehingga tidak sesuai dengan hasil fungsi.
2. Jalankan:

```bash
python -m unittest discover -s tests -v
```

3. Pastikan test gagal.
4. Commit dan push perubahan.
5. Amati job `validate` gagal pada langkah unit test.
6. Pastikan job deploy dilewati dan release aktif tidak berubah.
7. Kembalikan assertion ke nilai yang benar, lalu commit dan push lagi.

**Pertanyaan:** Mengapa pipeline seharusnya tidak menerapkan perubahan ketika unit test gagal?

---

## 15. Praktik rollback

### Praktik 9 — Mengembalikan release sebelumnya

Rollback hanya dapat dilakukan jika sudah terdapat minimal dua release yang berhasil.

1. Pastikan `current` dan `previous` tersedia:

```bash
ls -l /opt/data-cluster/current /opt/data-cluster/previous
readlink -f /opt/data-cluster/current
readlink -f /opt/data-cluster/previous
```

2. Pada VM target, jalankan:

```bash
sudo -u ghrunner bash -lc \
  'bash /path/ke/repository/scripts/rollback.sh'
```

Ganti `/path/ke/repository` dengan lokasi checkout proyek pada VM runner. Jika tidak mengetahui lokasinya, lakukan rollback melalui salinan script yang sudah disiapkan pada direktori kerja runner atau checkout repository secara manual ke direktori praktikum.

3. Verifikasi:

```bash
readlink -f /opt/data-cluster/current
readlink -f /opt/data-cluster/previous
```

4. Pastikan `current` sekarang menunjuk release yang sebelumnya aktif.
5. Jalankan kembali verifikasi file.

**Catatan:** rollback script adalah alat praktikum yang mengubah symlink release. Untuk produksi, rollback harus mempertimbangkan kompatibilitas dependensi, konfigurasi, data, dan workflow yang sedang berjalan. Rollback kode tidak otomatis membatalkan perubahan data bisnis.

---

## 16. Eksperimen Git dan keterlacakan

### Praktik 10 — Melihat riwayat dan perubahan

```bash
git log --oneline --decorate -10
git status
git diff HEAD~1 HEAD
git branch
```

Diskusikan:
- Commit mana yang terakhir diterapkan?
- Bagaimana menghubungkan commit dengan workflow run?
- Mengapa pesan commit harus deskriptif?
- Apa risiko mengizinkan seluruh branch memicu deployment target?

### Praktik 11 — Branch fitur

1. Buat branch:

```bash
git switch -c feature/update-summary
```

2. Ubah dokumentasi atau kode.
3. Commit dan push:

```bash
git add .
git commit -m "Update summary feature"
git push -u origin feature/update-summary
```

4. Amati bahwa workflow yang dikonfigurasi hanya memicu otomatis pada push ke `main` (workflow manual tetap tersedia).
5. Buat Pull Request ke `main`.
6. Review perubahan sebelum merge.
7. Setelah merge ke `main`, amati pipeline berjalan.

---

## 17. Keamanan dan least privilege

Checklist keamanan praktikum:

- [ ] Repository praktikum menggunakan akses privat.
- [ ] Self-hosted runner berjalan pada VM khusus, bukan server produksi.
- [ ] Runner berjalan sebagai user `ghrunner`, bukan root.
- [ ] Direktori `/opt/data-cluster` hanya dapat ditulis user/kelompok yang diperlukan.
- [ ] Workflow hanya deploy dari branch `main`.
- [ ] Job deploy menunggu job validasi.
- [ ] Tidak ada token/password/private key di source code.
- [ ] Hak akses repository dan runner dibatasi.
- [ ] Workflow dari fork atau kontributor tak tepercaya tidak dijalankan pada self-hosted runner.
- [ ] Log diperiksa agar tidak memuat informasi sensitif.

Praktikum ini tidak membutuhkan SSH secret karena self-hosted runner bekerja langsung pada VM target. Pada arsitektur lain, deployment dapat memakai SSH atau mekanisme transfer yang aman; kredensialnya harus disimpan sebagai GitHub Actions Secrets dan diberi hak akses minimum.

---

## 18. Troubleshooting

| Gejala | Kemungkinan penyebab | Pemeriksaan / solusi |
|---|---|---|
| `git: command not found` | Git belum terpasang | Install Git, buka terminal baru |
| `python: command not found` | Nama executable berbeda | Gunakan `python3` atau `py -3.11` |
| `No module named venv` | Paket venv belum terpasang | `sudo apt install python3-venv` |
| `black --check` gagal | Format belum sesuai | Jalankan `black .`, lalu cek ulang |
| Flake8 gagal | Ada pelanggaran lint | Baca file/baris/kode temuan, perbaiki |
| Unit test gagal | Assertion atau fungsi tidak sesuai | Jalankan test lokal dan telusuri output |
| Workflow tidak muncul | File YAML tidak di branch atau path salah | Pastikan `.github/workflows/ci-cd.yml` |
| Runner Offline | Runner/service berhenti atau koneksi keluar terputus | Periksa status service dan koneksi GitHub |
| Job deploy menunggu terus | Label runner tidak cocok | Cocokkan label `cicd-target`, `linux`, `x64` |
| Permission denied di `/opt/data-cluster` | Kepemilikan direktori salah | Periksa `chown` dan user service runner |
| Deploy skipped | Validasi gagal atau branch bukan `main` | Buka log job `validate`, periksa ref branch |
| File tidak ditemukan di target | Path sumber/tujuan salah | Periksa log deploy dan struktur release |
| Import Python gagal | Struktur atau `PYTHONPATH` tidak sesuai | Jalankan dari root release dan periksa modul |
| Rollback gagal | Belum ada `previous` atau symlink rusak | Pastikan dua release sukses dan periksa link |

Untuk mendiagnosis pipeline, mulai dari job dan step pertama yang gagal. Jangan langsung mengulang deployment tanpa memahami penyebab kegagalan.

---

## 19. Tugas praktikum dan hasil yang dikumpulkan

### Tugas A — Implementasi dasar

1. Siapkan komputer pengembangan dan VM Ubuntu target.
2. Buat repository GitHub.
3. Jalankan program dan semua pemeriksaan lokal.
4. Aktifkan self-hosted runner.
5. Lakukan push ke `main`.
6. Buktikan job validasi dan deployment berhasil.

### Tugas B — Pengujian kegagalan

1. Buat satu kesalahan linting.
2. Buktikan pipeline gagal.
3. Buktikan deployment tidak berjalan.
4. Perbaiki kode dan jalankan ulang.

### Tugas C — Unit testing

1. Tambahkan satu fungsi baru untuk menghitung rata-rata nilai transaksi.
2. Buat minimal dua test case.
3. Jalankan test lokal.
4. Push dan pastikan pipeline memeriksa test baru.

### Tugas D — Rollback

1. Lakukan dua deployment sukses.
2. Catat target `current` dan `previous`.
3. Jalankan rollback.
4. Lampirkan bukti bahwa `current` berubah ke release sebelumnya.

### Berkas/bukti yang dikumpulkan

- URL repository (akses diberikan kepada dosen sesuai kebijakan).
- Screenshot struktur repository.
- Screenshot workflow sukses.
- Screenshot linting dan unit test sukses.
- Screenshot eksperimen pipeline gagal dan job deploy tidak berjalan.
- Output verifikasi direktori target.
- Bukti rollback.
- Laporan ringkas analisis hasil dan kendala.

Jangan mengunggah token, secret, private key, atau informasi autentikasi ke laporan.

---

## 20. Rubrik penilaian praktikum

| Komponen | Indikator | Bobot |
|---|---|---:|
| Persiapan environment | Git, Python, VM, dan runner siap | 15% |
| Pengelolaan Git | Repository, commit, push, branch | 15% |
| CI pipeline | Black, Flake8, unit test berjalan otomatis | 25% |
| Deployment DAG | Deploy hanya setelah validasi sukses | 20% |
| Verifikasi dan rollback | Release diverifikasi dan rollback berhasil | 15% |
| Keamanan dan dokumentasi | Least privilege, secret hygiene, laporan | 10% |
| **Total** | | **100%** |

---

## 21. Pertanyaan analisis

1. Apa perbedaan CI, Continuous Delivery, dan Continuous Deployment pada implementasi ini?
2. Mengapa repository Git menjadi sumber acuan perubahan?
3. Apa perbedaan working directory, staging area, dan commit?
4. Apa hubungan push dengan trigger workflow?
5. Apa perbedaan fungsi Black dan Flake8?
6. Mengapa linting tidak cukup untuk memastikan logika program benar?
7. Mengapa unit test dijalankan sebelum deployment?
8. Apa fungsi `needs: validate` pada job deployment?
9. Apa perbedaan GitHub-hosted runner dan self-hosted runner pada praktikum?
10. Mengapa self-hosted runner perlu VM khusus dan user non-root?
11. Mengapa transfer file sukses belum tentu berarti DAG dapat dijalankan oleh platform orkestrasi?
12. Apa yang harus diubah bila kampus menggunakan Apache Airflow?
13. Bagaimana cara menghubungkan release aktif dengan commit Git?
14. Apa risiko bila semua branch dapat melakukan deployment?
15. Apa batasan rollback berbasis symlink?

---

## 22. Pengembangan lanjutan

Setelah praktikum dasar berhasil, sistem dapat dikembangkan dengan:
1. Mengganti DAG demonstrasi dengan DAG platform orkestrasi yang digunakan kampus.
2. Menambahkan pemeriksaan sintaks atau import DAG sesuai platform.
3. Menambahkan environment development, staging, dan production.
4. Menambahkan persetujuan manual sebelum deployment produksi (Continuous Delivery).
5. Menggunakan SSH/rsync atau mekanisme artifact deployment bila runner tidak ditempatkan pada target.
6. Menambahkan notifikasi status pipeline.
7. Menambahkan pemeriksaan dependensi dan pemindaian keamanan.
8. Menambahkan retensi dan pembersihan release lama.
9. Menambahkan mekanisme rekonsiliasi untuk implementasi GitOps yang lebih lengkap.

---

## 23. Referensi resmi

- Git Documentation: https://git-scm.com/doc
- GitHub Actions: https://docs.github.com/actions
- Self-hosted runners: https://docs.github.com/actions/hosting-your-own-runners/managing-self-hosted-runners
- GitHub workflow syntax: https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions
- Black: https://black.readthedocs.io/
- Flake8: https://flake8.pycqa.org/
- Python `unittest`: https://docs.python.org/3/library/unittest.html
- Python `venv`: https://docs.python.org/3/library/venv.html

---

## 24. Penutup

Praktikum ini menunjukkan bagaimana perubahan kode yang dikelola melalui Git dapat menjalani pemeriksaan kualitas, unit testing, dan deployment secara otomatis. Pipeline menjadi gerbang yang memastikan file DAG hanya diterapkan ketika validasi berhasil. Release terpisah, verifikasi, dan rollback membantu mahasiswa memahami aspek keandalan dan keterlacakan deployment.

**Hasil akhir yang diharapkan:** mahasiswa mampu melakukan perubahan kode, `git push`, mengamati pipeline, membuktikan validasi berhasil/gagal, memeriksa file DAG di target, dan mengembalikan release sebelumnya.
