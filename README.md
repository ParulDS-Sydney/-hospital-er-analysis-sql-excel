Hospital Emergency Room Analysis (SQL Server + Excel)
Status: SQL analysis and Excel dashboard complete. Power BI version in progress.
Goal
Understand patient flow in a hospital emergency room: which departments are busiest, where patients wait longest, and whether longer waits go with lower satisfaction.
Dataset
Hospital ER practice dataset, 9,216 patient records, April 2023 to October 2024.
This is a public practice dataset, not data from a real hospital.
Columns used: admission date, gender, age, department referral, admission flag, satisfaction score, wait time. Patient IDs and names are not included in this repository.
Tools
Excel: data cleaning
SQL Server (SSMS): CASE WHEN, CTEs, subqueries, window functions (RANK, DENSE_RANK, ROW_NUMBER, LAG)
Key findings
Outcome: 4,612 patients (50.0%) were admitted and 4,604 (50.0%) were discharged.
Departments: 5,400 patients (58.6%) had no referral. Among referred patients, General Practice was busiest (1,840), then Orthopedics (995). Renal was smallest (86).
Gender: Average wait was almost the same for male (35.4 min) and female patients (35.1 min).
Wait by department: Neurology (36.8 min), Physiotherapy (36.6), Gastroenterology (35.8), Cardiology (35.4) and No Referral (35.3) were above the hospital average of about 35.3 minutes, but the gaps are small.
Age and satisfaction: Adults scored 5.09, children 5.01 and seniors 4.77 (patients with a score only).
Wait vs satisfaction: Short waits scored 5.13, medium 4.87 and long 5.02. Longer waits did not lead to steadily lower satisfaction.
Admission rate: 48.2% (General Practice) to 53.5% (Renal, only 86 patients).
Monthly volume: about 485 patients per month (431 to 530) with no clear trend; busiest month Aug 2024, quietest Feb 2024.
Longest waits: the maximum wait in every department is 60 minutes, with many ties.
Limitations
Satisfaction scores exist for only 2,517 of 9,216 patients (27.3%), so those results describe only patients who gave a score.
The admission flag is assumed to mean 1 = Admitted.
Wait-time buckets (up to 24, 25-44, 45+ minutes) were chosen by me.
The near 50/50 admission split suggests the data is synthetic, so findings should not be read as real hospital performance.
What I learned
RANK skips numbers after ties while DENSE_RANK does not.
ROW_NUMBER breaks ties arbitrarily, so top-N queries can mislead when many values tie.
Cleaning inconsistent categories (M, F, Male) before grouping.
Files
`hospital_er_analysis.sql`: all queries with findings in comments
Dashboard screenshot: coming soon
Next steps
Build the Excel dashboard (pivot tables, slicers).
Rebuild the dashboard in Power BI (learning in progress).
