Revenue Waterfall Analysis: Price-Volume-Mix Decomposition 

Technical Lead: Vincent Ta

Project Overview: This project provides a structured financial bridge to reconcile the variance between budgeted revenue and actual sales performance. By utilizing SQL Server, the analysis automates the decomposition of a 2.3M USD unfavorable variance into two distinct operational drivers: Price Effect and Volume Effect.
The goal of this model is to move beyond identifying "that" a miss occurred and instead pinpointing "why" it occurred, allowing for targeted management intervention.
Data Pipeline Architecture
The analysis is executed in three logical phases within the SQL environment: 

Phase 1: Budget Engineering and Target Setting
Because actual budget data is often stored in external systems, this stage simulates a corporate financial plan.
Design: Implements drop-and-create logic to ensure the environment remains clean across multiple executions. 
Stretch Goal Modeling: Establishes targets by applying a 5% increase to historical unit volume and a 10% increase to historical revenue.

Phase 2: Actuals Aggregation and Variance Logic
This phase utilizes Common Table Expressions (CTEs) to perform complex calculations without creating permanent overhead in the database.
Monthly Roll-ups: Aggregates thousands of granular transactions into monthly, category-specific figures.
Price vs. Volume Calculations: * Price Effect: Calculated as $((Actual Price - Budget Price) \times Actual Quantity)$. This measures the impact of discounts or changes in MSRP.
Volume Effect: Calculated as $((Actual Quantity - Budget Quantity) \times Budget Price)$. This measures the impact of market demand and sales velocity.
Error Handling: Employs NULLIF logic to prevent division-by-zero errors in categories with zero sales during the period.

Phase 3: Executive Reporting
The final output is formatted for immediate use by stakeholders.
Currency Formatting: Transforms raw integers into standardized currency strings for readability.
Exception Management: Uses CASE statements to categorize variances as "Favorable" or "Unfavorable," allowing analysts to quickly identify high-risk areas.
Business Case Study: Road Bikes
The model identified the Road Bikes category as the primary driver of regional underperformance:
Total Variance: 214,871 USD (Unfavorable).
Price Impact: 102,817 USD loss due to pricing pressure/discounts.
Volume Impact: 112,054 USD loss due to lower-than-anticipated sales units.

Technical Skills Demonstrated
Advanced SQL: CTEs, Window Functions (via DATEFROMPARTS), Joins, and CASE logic.
Financial Modeling: Variance analysis, PVM decomposition, and budget reconciliation.
Data Integrity: Implementation of Primary Keys and IDENTITY constraints to ensure record uniqueness.
