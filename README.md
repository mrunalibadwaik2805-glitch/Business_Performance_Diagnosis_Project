# Business_Performance_Diagnosis_Project
# 📉 Business Performance Diagnosis: Why Is Margin Falling While Revenue Grows?

An interactive Power BI dashboard, backed by Python and PostgreSQL analysis, that finds why a company's operating margin fell from 9.1% to 5.2% while revenue grew 58.6%, and quantifies a $313K annual profit recovery plan.

---

## 1. Short Description / Purpose

The Business Performance Diagnosis dashboard is a three-page Power BI report that helps managers see where profit is leaking in a growing business. It breaks the margin decline down by product category, sales channel, region and cost line, then shows what three specific actions are worth.

The same analysis is built three ways (Python, PostgreSQL and DAX in Power BI), and all three give the same numbers. It is intended for finance managers, business analysts and operations leaders who need clear answers and not raw data. A one-page executive summary is included for stakeholders.

> **Note:** all data in this project is **simulated**. It was generated to show a realistic margin-decline pattern, so the numbers demonstrate the method, not a real company.

---

## 2. Tech Stack

| Tool | How it was used |
|---|---|
| 🐘 **PostgreSQL** | Schema with primary and foreign keys, CSV loading, data-quality checks, and the full analysis in SQL: window functions (`RANK`, `LAG`, `SUM() OVER`), CTEs, the `FILTER` clause, `DATE_TRUNC`, `PERCENTILE_CONT`, views and materialized views. 29 queries, each tested on PostgreSQL |
| 🐍 **Python** (pandas, numpy, matplotlib) | Data validation, KPI calculation, margin bridge, business-impact scenarios, charts |
| 📓 **Jupyter Notebook** | The full analysis in one reproducible file |
| 📊 **Power BI Desktop** | Dashboard, interactive visuals, bookmarks |
| 🧠 **DAX** | Measures for margins, discounts, the margin bridge and the action values |
| 🧩 **Data modeling** | Star schema: one sales fact table with products, customers and a Date table, plus the monthly expenses table |
| 🎨 **Power BI theme (JSON)** | Consistent colours, light and dark versions |

---

## 3. Data Source

The data is synthetic, generated with Python (fixed seed, so it is reproducible). It covers **24 months, January 2023 to December 2024**.

| File | Content |
|---|---|
| `sales_transactions.csv` | 17,445 orders: date, product, customer, region, channel, quantity, list price, discount, net revenue, COGS, freight |
| `products.csv` | 12 products in 3 categories (Electronics, Furniture, Accessories) |
| `customers.csv` | 400 customers, 3 segments, 4 regions |
| `monthly_opex.csv` | Monthly marketing, salaries and admin costs |

**Data quality:** 37 automated checks in Python (missing values, duplicates, data types, valid ranges, links between files, revenue logic, text consistency) all pass before any analysis is run. The same checks in PostgreSQL (duplicate orders, missing values, invalid discounts and quantities, revenue logic, orphan products) all return 0.

---

## 4. Features / Highlights

### Business Problem
Revenue grew **58.6%** from FY23 to FY24 ($4.56M to $7.24M), yet operating margin fell from **9.1% to 5.2%** and operating profit dropped **9%**. Management needed to know:

- Why is margin declining despite revenue growth?
- What three specific actions should management take?

### Goal of the Dashboard
Let a manager answer three questions in under a minute:

1. Is margin really falling?
2. Where is it leaking (product, channel, region, cost line)?
3. What is the fix worth?

### Walkthrough of Key Visuals

**Page 1: Problem**
- **KPI cards:** Net revenue FY24 ($7.24M), orders (17,445), customers (400), gross margin (24.9%), operating margin (5.2%).
- **Revenue vs operating margin (columns and line, by month):** revenue rises every month while margin falls from about 10% to 3%. Three phases (Baseline, Erosion, Squeeze) show when it started.

**Page 2: Analysis**
- **Revenue mix by category (donut):** Electronics is 76% of revenue but earns only 16% margin. Accessories earn 58% on 7% of sales.
- **Average discount by channel (clustered columns):** Distributor discounts rose from 8.8% to 12.4%.
- **Profitability by region (table with Overall / Detailed toggle, built with bookmarks):** all four regions earn about 20%, and freight stays near 5% of revenue, so the problem is not regional.

**Page 3: Root cause and recommendation**
- **Operating margin bridge (waterfall, FY23 to FY24):** COGS costs 5.3 points and marketing 1.8 points. Lower salary and admin ratios give back 3.1 points. Freight is not a cause.
- **Distributor discount and marketing share (monthly):** both rose steadily with no spending control.
- **Three actions (bar chart):** the annual profit value of each recommendation.

### Business Impact and Insights

| # | Action | Annual value |
|---|---|---|
| 1 | Reprice and rebalance Electronics (+2% price or supplier terms, bundle Accessories) | about $110K |
| 2 | Cap Distributor discounts at the FY23 level (8.8%) | about $71K |
| 3 | Hold marketing at the FY23 share of revenue (5.9%) | about $132K |
| | **Total** | **about $313K** |

- **Result:** operating margin recovers from 5.2% to about **9.5%**, back to the FY23 level.
- **Root causes:** a shift towards low-margin Electronics, discount creep in the Distributor channel, and marketing spend outgrowing revenue.
- **Ruled out:** freight and regional differences, tested with data.
- **Limits:** the Electronics price action assumes no lost sales, so it should be piloted in one region first.

### Same Answer, Three Tools

| Result | Python | PostgreSQL | Power BI (DAX) |
|---|---|---|---|
| FY24 net revenue | $7,238,411 | $7,238,411 | $7.24M |
| Operating margin FY23 to FY24 | 9.07% to 5.21% | 9.07% to 5.21% | 9.1% to 5.2% |
| Total upside of three actions | $313,523 | $313,523 | $313.5K |
| Margin after the actions | 9.54% | 9.54% | 9.5% |

