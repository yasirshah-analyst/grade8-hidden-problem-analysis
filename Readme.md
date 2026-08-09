# 📚 Grade 8 Mathematics: A Hidden School-Wide Problem

## 📌 Project Overview
This project was developed as a **portfolio project** to demonstrate an end-to-end data analytics workflow while simulating a real-world business scenario.
Most data analysis stops at "what happened." This project follows the modern data analytics workflow through to **data storytelling** — not just finding a problem, but tracing its exact cause through a rigorous, evidence-based elimination process, and translating it into a specific answer for each stakeholder who needs one.

Built entirely in **SQL (PostgreSQL)** — every claim in this README is backed by an actual query result, not assumption.

---

## 🎯 Business Problem

> Overall school performance data can look healthy while hiding a real, localized problem inside it. This project investigates whether such a hidden issue exists in this school's exam results — and if so, exactly where it lives, why it's happening, and what different stakeholders should do about it.

---

## 🗂️ Dataset
This project uses a **synthetic students performance dataset** generated with the assistance of the **DeepSeek AI platform** for portfolio and learning purposes.
200 exam records across 3 grades (7, 8, 9), 4 sections (A–D), 4 subjects (Mathematics, Science, English, History), 10 teachers, spanning January–December 2025.

Columns: `StudentID`, `Grade`, `Section`, `Subject`, `ExamDate`, `Score`, `PassFlag`, `TeacherID`

---

## 🔎 The Investigation — 8 SQL Queries

Each query either confirms or rules out a possible explanation, narrowing the search step by step. All percentage calculations use `100.0 *` (not `100 *`) to avoid PostgreSQL's integer-division truncation bug.

### Query 1 — How healthy is overall school performance?
```sql
SELECT 
    COUNT(*) AS total_records,
    ROUND(AVG(score), 2) AS avg_score,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_rate
FROM students_performance;
```
**Result:** Overall pass rate looks reasonably healthy at a glance — but this single blended number hides what's coming next.

---

### Query 2 — Which grade is struggling most?
```sql
SELECT 
    grade,
    COUNT(*) AS total_records,
    ROUND(AVG(score), 2) AS avg_score,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_rate
FROM students_performance
GROUP BY grade
ORDER BY grade;
```
**Result:** Grade 7 and Grade 9 both sit at a perfect **100% pass rate**. Grade 8 sits at **58.2%** — the entire school's weak spot is concentrated in one grade.

---

### Query 3 — Which subjects are driving poor results?
```sql
SELECT 
    subject,
    COUNT(*) AS total_records,
    ROUND(AVG(score), 2) AS avg_score,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_rate
FROM students_performance
GROUP BY subject
ORDER BY avg_score;
```
**Result:** Mathematics and English show the lowest school-wide averages — a first hint of where to look, but not yet grade-specific.

---

### Query 4 — Is the problem concentrated in specific subjects within Grade 8?
```sql
SELECT 
    grade,
    subject,
    COUNT(*) AS total_records,
    ROUND(AVG(score), 2) AS avg_score,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_rate
FROM students_performance
GROUP BY grade, subject
ORDER BY grade, avg_score;
```
**Result — this is where the story emerges:**
- Grade 8 **Mathematics: 0% pass rate**
- Grade 8 **English: 33.3% pass rate**
- Grade 8 **Science and History: 100% pass rate**

Only two of Grade 8's four subjects are affected — Science and History are completely healthy. This rules out a grade-wide problem and points specifically at Math and English.

---

### Query 5 — Are certain sections underperforming?
```sql
SELECT 
    grade,
    section,
    ROUND(AVG(score), 2) AS avg_score,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_rate
FROM students_performance
GROUP BY grade, section
ORDER BY grade, avg_score;
```
**Result:** Grade 8 only has 3 sections (A, B, C — no Section D exists for this grade). Narrowed to Mathematics and English specifically:
- **Mathematics: 0% in Section A, 0% in Section B, 0% in Section C** — every section fails equally
- **English: 0% in Section A, 100% in Section B, 0% in Section C** — only 2 of 3 sections fail

This is the key divergence: **Mathematics fails universally across all sections. English fails only in specific sections.** Two different patterns, likely two different causes.

---

### Query 6 — Are certain teachers consistently associated with better or worse outcomes?
```sql
SELECT 
    teacherid,
    subject,
    ROUND(AVG(score), 2) AS avg_score,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_rate
FROM students_performance
WHERE grade = 8 AND subject IN ('Mathematics', 'English')
GROUP BY teacherid, subject
ORDER BY subject, pass_rate DESC;
```
**Result:**
- **Mathematics: 0% pass rate for all 10 teachers**, with no exceptions — this rules out an individual teacher's competence as the cause
- Cross-check: the same 10 teachers achieve 94%+ pass rates when teaching other subjects/grades — confirming these are not weak teachers generally, only within this specific Grade 8 Mathematics assignment
- **English: pass rate varies by teacher** — but only because it tracks which section each teacher was assigned to, not teacher quality itself (see Query 5)

**Conclusion:** Mathematics' problem is structural — something about the Grade 8 Math curriculum, pacing, or exam design itself, not the people teaching it.

---

### Query 7 — Has this always been broken, or did it start recently?
```sql
SELECT 
    DATE_TRUNC('month', examdate) AS month,
    COUNT(*) AS students,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pass_rate_pct
FROM students_performance
WHERE grade = 8 AND subject = 'Mathematics'
GROUP BY DATE_TRUNC('month', examdate)
ORDER BY month;
```
**Result:** **0% pass rate in every single month from January through April 2025** — no variation, no recent decline, no partial recovery. This has been broken from the start of the data, not a new development.

---

### Query 8 — Why does English's pass rate appear to swing by month?
```sql
SELECT 
    DATE_TRUNC('month', examdate) AS month,
    section,
    COUNT(*) AS total_records,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pass_rate_pct
FROM students_performance
WHERE grade = 8 AND subject = 'English'
GROUP BY DATE_TRUNC('month', examdate), section
ORDER BY month;
```
**Result:** Each month's English exam includes students from only **one** section:

| Month | Section | Pass Rate |
|---|---|---|
| January | C | 0.0% |
| August | B | 100.0% |
| September | A | 0.0% |
| October | C | 0.0% |
| November | B | 100.0% |
| December | A | 0.0% |

**This is the critical finding:** English's month-to-month swing isn't a real time trend at all — it's a **confound**. Month and Section are tangled together in the exam schedule, so what looks like "varying by month" is actually just "which section tested that month." Unlike Mathematics, English does not have an independent time-based pattern — its real driver is Section (Query 5), not Month.

---

## 📖 The Data Story

### 📌 What happened?
Grade 8's overall pass rate is 58.2%, while Grade 7 and Grade 9 both achieve a perfect 100%.

### 📌 Why did it happen?
Entirely isolated to two subjects: **Mathematics (0% pass rate, every section, every teacher, every month)** and **English (33.3%, driven specifically by Sections A and C, while Section B passes fully)**. Science and History in Grade 8 are perfectly healthy. A rigorous elimination process ruled out section-specific and teacher-specific causes for Mathematics, and ruled out a "declining trend" explanation for English's apparent time pattern — it's actually a section effect in disguise.

### 📌 Why does it matter?
With zero month-to-month variation, Grade 8 Mathematics is not going to self-correct — every cohort passing through this grade will keep failing under the current structure until something changes.

### 📌 What should we do next?

🎯 **School Director** — *"Is this affecting our overall school results?"*
→ Not school-wide. Grades 7 and 9 are fully unaffected — this is isolated entirely to Grade 8.

🎯 **Principal** — *"What's causing it?"*
→ Not a Grade 8-wide issue either. Science and History in Grade 8 are perfect. It's specifically Mathematics (every section, every teacher — a structural/curriculum issue) and English (only 2 of 3 sections — worth investigating what's different about those specific sections' instruction or student composition).

🎯 **Mathematics Section Head** — *"What should we do about it?"*
→ Since all 10 teachers and all 3 sections show an identical 0% result, this is not a case for teacher retraining or section reassignment — it points to the curriculum, exam difficulty, or pacing for Grade 8 Mathematics specifically. Recommend an audit of the course material and assessment design, not personnel.

---

## 🛠️ Tools Used
- PostgreSQL (all analysis, no other tools)

## 📁 Project Structure
```
grade8-hidden-problem-analysis/
│
├── Data/
│   └── students.csv
│
├── Outputs/
│   ├── Q0.csv
│   ├── Q1.csv
│   ├── Q2.csv
│   ├── Q3.csv
│   ├── Q4.csv
│   ├── Q5.csv
│   ├── Q6.csv
│   ├── Q7.csv
│   └── Q8.csv
│
├── students_performance.sql
│
└── Readme.md
```

## 👤 Author
Yasir Shah | Primary School Teacher | Data Analyst

- [@yasirshah-analyst](https://github.com/yasirshah-analyst)
- www.linkedin.com/in/yasir-shah-2364183b3
- shahyasir443@gmail.com
