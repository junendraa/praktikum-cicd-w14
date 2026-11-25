"""Transformasi sederhana untuk dataset penjualan praktikum."""

import csv
from collections import defaultdict
from pathlib import Path


def load_sales(csv_path):
    """Membaca CSV dan mengubah kolom numerik ke integer."""
    rows = []
    with Path(csv_path).open("r", encoding="utf-8", newline="") as csv_file:
        reader = csv.DictReader(csv_file)
        required = {"order_id", "order_date", "product", "quantity", "unit_price"}
        if not required.issubset(reader.fieldnames or []):
            raise ValueError("Kolom dataset tidak lengkap")

        for row in reader:
            quantity = int(row["quantity"])
            unit_price = int(row["unit_price"])
            if quantity <= 0 or unit_price < 0:
                raise ValueError("quantity harus > 0 dan unit_price tidak negatif")
            row["quantity"] = quantity
            row["unit_price"] = unit_price
            rows.append(row)
    return rows


def summarize_sales(rows):
    """Menghitung jumlah transaksi dan omzet per tanggal."""
    summary = defaultdict(lambda: {"orders": 0, "revenue": 0})
    for row in rows:
        date = row["order_date"]
        summary[date]["orders"] += 1
        summary[date]["revenue"] += row["quantity"] * row["unit_price"]
    return dict(summary)


def total_revenue(rows):
    """Menghitung total omzet seluruh baris."""
    return sum(row["quantity"] * row["unit_price"] for row in rows)

def average_transaction_value(rows):
    """Menghitung rata-rata nilai per transaksi (omzet / jumlah transaksi)."""
    if not rows:
        raise ValueError("Tidak ada transaksi untuk dihitung rata-ratanya")
    return total_revenue(rows) / len(rows)
