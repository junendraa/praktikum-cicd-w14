# Praktikum CI/CD & Deployment Workflow

Studi kasus: otomatisasi validasi dan deployment definisi DAG pemrosesan data penjualan.

## Isi proyek
- `dags/`: definisi DAG Python demonstrasi.
- `src/`: fungsi transformasi data.
- `data/`: dataset CSV latihan.
- `tests/`: unit test menggunakan `unittest`.
- `.github/workflows/ci-cd.yml`: pipeline GitHub Actions.
- `scripts/deploy.sh`: deployment dengan release directory dan symlink `current`.
- `scripts/rollback.sh`: rollback ke release sebelumnya.

Ikuti panduan lengkap pada `PANDUAN_PRAKTIKUM_CICD.md` (file MD terpisah dalam paket unduhan).

> Catatan: DAG di proyek ini adalah representasi Python yang netral-platform, bukan DAG Apache Airflow. Tujuannya mempraktikkan alur CI/CD dan pemindahan file. Integrasi dengan platform orkestrasi tertentu memerlukan penyesuaian.
