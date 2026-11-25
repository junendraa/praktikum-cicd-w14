"""Unit test fungsi transformasi penjualan."""

import tempfile
import unittest
from pathlib import Path

from src.sales_transform import load_sales, summarize_sales, total_revenue

ROOT = Path(__file__).resolve().parents[1]


class TestSalesTransform(unittest.TestCase):
    def setUp(self):
        self.rows = load_sales(ROOT / "data" / "sales.csv")

    def test_dataset_has_eight_orders(self):
        self.assertEqual(len(self.rows), 8)

    def test_total_revenue(self):
        self.assertEqual(total_revenue(self.rows), 351000)

    def test_daily_summary_contains_three_dates(self):
        summary = summarize_sales(self.rows)
        self.assertEqual(len(summary), 3)
        self.assertEqual(summary["2026-10-01"]["orders"], 3)
        self.assertEqual(summary["2026-10-01"]["revenue"], 146000)

    def test_invalid_quantity_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            csv_path = Path(temp_dir) / "invalid.csv"
            csv_path.write_text(
                "order_id,order_date,product,quantity,unit_price\n"
                "BAD-001,2026-10-01,Kopi,0,1000\n",
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                load_sales(csv_path)


if __name__ == "__main__":
    unittest.main()
