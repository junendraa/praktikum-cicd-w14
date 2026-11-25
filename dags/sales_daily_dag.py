"""Definisi DAG demonstrasi; bukan sintaks platform orkestrasi tertentu."""

from pathlib import Path

from src.sales_transform import load_sales, summarize_sales

DAG_ID = "sales_daily_summary"
DESCRIPTION = "Ringkasan transaksi dan omzet harian dari data/sales.csv"
SCHEDULE = "daily"
TASKS = ["extract_sales", "transform_sales", "validate_summary"]
DEPENDENCIES = [
    ("extract_sales", "transform_sales"),
    ("transform_sales", "validate_summary"),
]


def run_demo(project_root=None):
    """Menjalankan demonstrasi fungsi DAG secara lokal."""
    root = Path(project_root) if project_root else Path(__file__).resolve().parents[1]
    rows = load_sales(root / "data" / "sales.csv")
    summary = summarize_sales(rows)
    if not summary:
        raise ValueError("Dataset kosong")
    return summary


if __name__ == "__main__":
    print(run_demo())
