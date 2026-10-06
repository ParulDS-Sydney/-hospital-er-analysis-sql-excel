/* =====================================================================
   Hospital Emergency Room Analysis | SQL Server (SSMS)
   Database: PracticeDB   Table: HospitalER (9,216 rows)

   Notes
   - Gender had M, F and Male mixed: cleaned with CASE WHEN.
   - Department_Referral had many NULLs: shown as 'No Referral'.
   - Admission date is stored as text (dd-mm-yyyy hh:mm): TRY_CONVERT style 105.
   - Patient_Admission_Flag is a bit; assumed 1 = Admitted, 0 = Discharged.
   - Satisfaction score is NULL for most patients, so satisfaction queries
     use only patients who gave a score.
   ===================================================================== */

USE PracticeDB;
GO

/* Data checks */
SELECT Patient_Gender, COUNT(*) AS n FROM HospitalER GROUP BY Patient_Gender;
SELECT Patient_Admission_Flag, COUNT(*) AS n FROM HospitalER GROUP BY Patient_Admission_Flag;
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN TRY_CONVERT(datetime, Patient_Admission_Date, 105) IS NULL THEN 1 ELSE 0 END) AS bad_dates
FROM HospitalER;   -- 9,216 rows, 0 bad dates

/* Q1: Admitted vs Discharged
   Finding: 4,612 admitted (50.0%) and 4,604 discharged (50.0%). */
SELECT
    CASE WHEN Patient_Admission_Flag = 1 THEN 'Admitted' ELSE 'Discharged' END AS outcome,
    COUNT(*) AS patients,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS pct
FROM HospitalER
GROUP BY Patient_Admission_Flag;

/* Q2: Patients per department
   Finding: 5,400 (58.6%) had no referral; General Practice busiest among referred (1,840). */
SELECT COALESCE(Department_Referral, 'No Referral') AS department, COUNT(*) AS patients
FROM HospitalER
GROUP BY COALESCE(Department_Referral, 'No Referral')
ORDER BY patients DESC;

/* Q3: Average wait by gender
   Finding: Male 35.4 min, Female 35.1 min, almost identical. */
WITH base AS (
    SELECT
        CASE WHEN Patient_Gender IN ('M','Male')   THEN 'Male'
             WHEN Patient_Gender IN ('F','Female') THEN 'Female'
             ELSE 'Other/Unknown' END AS gender,
        Patient_Waittime
    FROM HospitalER
)
SELECT gender, COUNT(*) AS patients, AVG(CAST(Patient_Waittime AS FLOAT)) AS avg_wait_min
FROM base
GROUP BY gender;

/* Q4: Departments slower than the hospital average
   Finding: Neurology 36.8, Physiotherapy 36.6, Gastroenterology 35.8,
   Cardiology 35.4, No Referral 35.3 vs about 35.3 overall. Gaps are small. */
SELECT COALESCE(Department_Referral, 'No Referral') AS department,
       AVG(CAST(Patient_Waittime AS FLOAT)) AS avg_wait_min
FROM HospitalER
GROUP BY COALESCE(Department_Referral, 'No Referral')
HAVING AVG(CAST(Patient_Waittime AS FLOAT)) >
       (SELECT AVG(CAST(Patient_Waittime AS FLOAT)) FROM HospitalER)
ORDER BY avg_wait_min DESC;

/* Q5: Satisfaction by age group (2,517 patients with a score)
   Finding: Adults 5.09, Children 5.01, Seniors 4.77. */
WITH aged AS (
    SELECT
        CASE WHEN Patient_Age < 18 THEN '1. Child (0-17)'
             WHEN Patient_Age < 60 THEN '2. Adult (18-59)'
             ELSE '3. Senior (60+)' END AS age_group,
        Patient_Satisfaction_Score
    FROM HospitalER
    WHERE Patient_Satisfaction_Score IS NOT NULL
)
SELECT age_group, COUNT(*) AS patients,
       AVG(CAST(Patient_Satisfaction_Score AS FLOAT)) AS avg_satisfaction
FROM aged
GROUP BY age_group
ORDER BY age_group;

/* Q6: Wait time vs satisfaction (cut-offs chosen by me)
   Finding: Short 5.13, Medium 4.87, Long 5.02. No steady drop with longer waits. */
WITH bucketed AS (
    SELECT
        CASE WHEN Patient_Waittime <= 24 THEN '1. Short (up to 24 min)'
             WHEN Patient_Waittime <= 44 THEN '2. Medium (25-44 min)'
             ELSE '3. Long (45+ min)' END AS wait_bucket,
        Patient_Satisfaction_Score
    FROM HospitalER
    WHERE Patient_Satisfaction_Score IS NOT NULL AND Patient_Waittime IS NOT NULL
)
SELECT wait_bucket, COUNT(*) AS patients,
       AVG(CAST(Patient_Satisfaction_Score AS FLOAT)) AS avg_satisfaction
FROM bucketed
GROUP BY wait_bucket
ORDER BY wait_bucket;

/* Q7: Admission rate by department
   Finding: 48.2% (General Practice) to 53.5% (Renal, only 86 patients). */
SELECT COALESCE(Department_Referral, 'No Referral') AS department,
       COUNT(*) AS patients,
       CAST(100.0 * SUM(CASE WHEN Patient_Admission_Flag = 1 THEN 1 ELSE 0 END)
            / COUNT(*) AS DECIMAL(5,1)) AS admitted_pct
FROM HospitalER
GROUP BY COALESCE(Department_Referral, 'No Referral')
ORDER BY admitted_pct DESC;

/* Q8: RANK vs DENSE_RANK (Renal department)
   Finding: after ties RANK skips numbers (59,59 then 4) while DENSE_RANK does not (3). */
SELECT TOP 20
    Patient_Waittime,
    RANK()       OVER (ORDER BY Patient_Waittime DESC) AS rnk,
    DENSE_RANK() OVER (ORDER BY Patient_Waittime DESC) AS dense_rnk
FROM HospitalER
WHERE Department_Referral = 'Renal' AND Patient_Waittime IS NOT NULL
ORDER BY Patient_Waittime DESC;

/* Q9: Monthly patients and change vs previous month (CTE + LAG)
   Finding: about 485 per month (431 to 530), no clear trend; Aug 2024 busiest. */
WITH monthly AS (
    SELECT YEAR(TRY_CONVERT(datetime, Patient_Admission_Date, 105))  AS yr,
           MONTH(TRY_CONVERT(datetime, Patient_Admission_Date, 105)) AS mth,
           COUNT(*) AS patients
    FROM HospitalER
    WHERE TRY_CONVERT(datetime, Patient_Admission_Date, 105) IS NOT NULL
    GROUP BY YEAR(TRY_CONVERT(datetime, Patient_Admission_Date, 105)),
             MONTH(TRY_CONVERT(datetime, Patient_Admission_Date, 105))
)
SELECT yr, mth, patients,
       LAG(patients) OVER (ORDER BY yr, mth) AS prev_month,
       patients - LAG(patients) OVER (ORDER BY yr, mth) AS change_vs_prev
FROM monthly
ORDER BY yr, mth;

/* Q10: Top 3 longest waits per department (ROW_NUMBER)
   Finding: every department's longest wait is 60 min and many tie at 60, so
   ROW_NUMBER picks arbitrarily among ties; not very informative. */
WITH ranked AS (
    SELECT COALESCE(Department_Referral, 'No Referral') AS department,
           Patient_Waittime,
           ROW_NUMBER() OVER (PARTITION BY COALESCE(Department_Referral,'No Referral')
                              ORDER BY Patient_Waittime DESC) AS rn
    FROM HospitalER
    WHERE Patient_Waittime IS NOT NULL
)
SELECT department, Patient_Waittime, rn
FROM ranked
WHERE rn <= 3
ORDER BY department, rn;
