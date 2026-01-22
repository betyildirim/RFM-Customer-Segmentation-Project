# 🚀 RFM Customer Segmentation & Sales Analytics Project

![SQL](https://img.shields.io/badge/Language-PostgreSQL-blue?style=for-the-badge&logo=postgresql)
![Power BI](https://img.shields.io/badge/Tool-Microsoft%20Power%20BI-yellow?style=for-the-badge&logo=powerbi)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)

---

## 💼 Business Scenario & Problem Statement

A UK-based online retail business was struggling with a generic mass-marketing approach and lacked visibility into customer behavior.

**Objective:** Segment customers using **RFM (Recency, Frequency, Monetary)** analysis to enable data-driven marketing, retention, and churn prevention strategies.

---

## 🛠️ Technical Solution & Methodology

### 1️⃣ Data Cleaning & Preparation (PostgreSQL)
- Removed cancelled transactions (Invoices starting with `C`)
- Removed records with `NULL` Customer IDs
- Converted text-based fields into numeric and timestamp formats

### 2️⃣ RFM Analysis & Scoring
Customers were scored from **1 to 5** using SQL window functions (`NTILE`):
- **Recency:** Days since last purchase (lower is better)
- **Frequency:** Number of unique invoices (higher is better)
- **Monetary:** Total revenue per customer (higher is better)

### 3️⃣ Customer Segmentation
Customers were grouped into business-friendly segments such as:
- **Champions**
- **Loyal Customers**
- **At Risk**
- **Hibernating**

Segmentation logic was implemented using `CASE WHEN` rules in SQL.

---

## 📊 Power BI Dashboard

The processed RFM data was visualized in Power BI to provide executive-level KPIs and exportable customer lists.

📄 **Dashboard Preview (PDF):** [👉 Click here to view the Dashboard PDF](rfm_customer_segmentation_dashboard.pdf)

📁 **Power BI Source File:** [Download .pbix File](rfm_customer_segmentation_dashboard.pbix)

---

## 💡 Key Insights & Recommendations

| Segment | Insight | Recommended Action |
|------|------|------|
| **🏆 Champions** | High-value, highly engaged customers | VIP loyalty programs & early access |
| **💤 Hibernating** | Largest group with low engagement | Low-cost automated reactivation |
| **⚠️ At Risk** | Previously valuable but inactive | Immediate win-back campaigns |

---

## 📂 Repository Contents

- `RFM_Project.sql` – Full PostgreSQL pipeline (ETL, RFM calculation, segmentation)
- `rfm_customer_segmentation_dashboard.pbix` – Power BI dashboard source file
- `rfm_customer_segmentation_dashboard.pdf` – High-quality dashboard export
- `README.md` – Project documentation

---

## 🚀 How to Reproduce

1. Import a retail transaction dataset into PostgreSQL.
2. Run `RFM_Project.sql`.
3. Open the Power BI `.pbix` file and connect to your database.

> *Dataset is not included due to size and licensing constraints.*

---

**Author:** Fatma Betül Yıldırım
