# Customer Churn Analysis (SQL Server)

End-to-end SQL project: load raw data, profile data quality issues, build a cleaning pipeline, and answer business questions about why customers cancel their subscriptions.

> **Note:** The dataset is **synthetic** (21 original rows expanded to 10,000 customers). Data quality issues were deliberately included to practice profiling and cleaning.

## Business Questions
1. What is the overall churn rate?
2. Which plan churns the most?
3. Does contract type (Monthly vs Annual) matter?
4. Why do customers cancel?
5. Do customers who complained churn more?

## Tech Stack
- **SQL Server (SSMS):** T-SQL, CTEs, window functions, `CASE`, `TRY_CAST`, `SELECT ... INTO`
- **Python (pandas, SQLAlchemy):** loading the Excel sheets into SQL Server

## Dataset
Three tables loaded from `customer_churn_data_10k.xlsx`:

| Table | Rows | Description |
|---|---|---|
| `db_customer` | 10,040 | Customer details (40 duplicate rows) |
| `db_subscription` | 10,000 | Plan, contract, charges, cancellation date and reason |
| `db_support` | 4,005 | Support complaints (escalation, CSAT score, comment) |

A customer is counted as **churned** when `cancellation_date` is not null.

## Project Structure
```
.
├── load_data.ipynb              # Load Excel sheets into SQL Server (raw tables)
├── customer_churn_data_10k.xlsx # Synthetic dataset
├── 00_profiling.sql             # Data quality checks on raw tables
├── 01_customer_clean.sql        # Builds customer_clean
├── 02_subscription_clean.sql    # Builds subscription_clean
├── 03_support_clean.sql         # Builds support_clean
└── 04_analysis.sql              # Business questions and insights
```

## Data Cleaning
Raw tables are never modified; cleaned copies are created as new `_clean` tables.

| Issue found | Fix |
|---|---|
| 40 duplicate customers | Removed with `ROW_NUMBER()` (10,040 to 10,000 rows) |
| Gender in 4 variants (Male/Men, Female/Women) | Standardized to Male / Female |
| 1,551 blank `country` values | Filled from `state` (checked that each state maps to one country) |
| `Refferal` spelling (3,044 rows) | Corrected to `Referral` |
| Dates stored as text | Converted to `DATE` with `TRY_CAST` (NULL counts verified before and after) |
| 121 rows with wrong prices (1.2%) | Flagged with `is_price_outlier` instead of deleting, to keep their churn and support data |
| Typo in support comments (404 rows) | Corrected `demaned refund` to `demanded refund` |
| Empty junk columns (`pincode`, `col_1`) | Dropped |

Validation checks (row counts, distinct values, NULL counts) are included after each cleaning step.

## Key Findings
1. **Overall churn is 24.64%** (2,464 of 10,000 customers), about 1 in 4.
2. **Basic plan churns the most:** Basic 29.71%, Standard 24.77%, Premium 19.42%.
3. **Monthly contracts churn about 1.8x more than Annual** (32.54% vs 18.17%). The gap holds inside every plan (Basic 1.4x, Standard 2.0x, Premium 2.0x), so it is not only a plan-mix effect. Monthly Basic and Standard together account for 46.2% of all churn.
4. **Two reasons explain almost half of churn:** switching to a competitor (24.31%) and price (23.21%). Poor support and poor streaming quality add another 29.2%, which the company can fix directly.
5. **Customers who complained churn about 2.1x more** (39.15% vs 18.66%). They are 29.2% of customers but 46.4% of churn. Still, 53.6% of churn came from customers who never complained.

## Suggestions
- Pilot an Annual-plan discount for Standard Monthly customers (largest churn group) and measure the effect and cost.
- Run retention offers for price-sensitive Basic users.
- Follow up after resolved complaints and collect proactive feedback from customers who never complain.

## Limitations
- The data is synthetic, so findings illustrate the method rather than a real business.
- The analysis shows associations, not causes. For example, customers who choose Annual plans may already be more committed.

## How to Run
1. In SSMS: `CREATE DATABASE churn_db;`
2. Open `load_data.ipynb`, set `SERVER` to your SQL Server instance, and run all cells (expected counts: 10040, 10000, 4005).
3. Run the SQL files in order: `01`, `02`, `03`, then `04`. `00_profiling.sql` can be run any time to inspect the raw data.
