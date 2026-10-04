**Status: In progress**

## Goal
Understand patient flow in a hospital emergency room: which departments are busiest, where patients wait longest, and whether longer waits go with lower satisfaction.

## Dataset
- Hospital ER practice dataset, 9,216 patient records (source: [add the link where you downloaded it]).
- This is a public practice dataset, not data from a real hospital.
- Columns used: admission date, gender, age, department referral, admission flag, satisfaction score, wait time.

## Tools
- Excel: data cleaning
- SQL Server (SSMS): analysis with CASE WHEN, CTEs and window functions

## Findings so far
1. Out of 9,216 ER patients, 4,612 (50.0%) were admitted and 4,604 (50.0%) were discharged.
2. 5,400 patients (58.6%) came with no department referral. Among referred patients, General Practice was the busiest with 1,840 visits, followed by Orthopedics with 995.

## Next steps
- Remaining SQL queries: wait time by gender, departments with above-average waits, satisfaction vs wait time, admission rate by department, monthly trend.
- Excel dashboard with pivot tables and slicers.
- Rebuild the dashboard in Power BI (learning in progress).




