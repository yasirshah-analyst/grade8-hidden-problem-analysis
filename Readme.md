# Diagnosing a 0% Pass Rate: Isolating Two Hidden Problems Inside One Grade's Exam Results

## Executive Summary
 
**The business question.** A school's overall exam results looked healthy at a glance, but a single blended pass rate can hide a real, localized problem underneath it. This project investigates whether such a hidden issue exists in the school's exam results — and if so, exactly where it lives, why it's happening, and what different stakeholders should do about it.
 
The goal of this project was to find out where the problem was, whether it was caused by a teacher, section, subject, or time period, and what the school should do about it.

**Trade-offs and assumptions.** This project uses a synthetic dataset generated with the assistance of the DeepSeek AI platform for portfolio and learning purposes — the data is synthetic, but the analysis was designed to simulate a realistic school performance investigation. The findings identify patterns and likely areas for investigation; they do not prove the underlying causal mechanism. The Grade 8 Mathematics findings support investigating curriculum and assessment design, but confirming either as the root cause would need additional information, and the English findings would need student-level and classroom data to confirm a specific cause. The data tells us where to investigate — it does not automatically tell us why the problem exists.
 
**Key insights.**
 
1. **The overall result hid a Grade 8 problem.** School-level results looked healthy, but breaking down by grade showed the problem concentrated entirely in Grade 8 — Grades 7 and 9 showed no such pattern.
2. **Grade 8 Mathematics: 0% pass rate, no exceptions.** Failed across all teachers, all sections, all months — ruling out a single-teacher or single-section explanation and pointing to a curriculum or assessment-level issue.
3. **Grade 8 English: a section-specific problem, not a subject-wide one.** Section B passed at 100%; Sections A and C performed far worse — suggesting something specific to those sections, not English instruction generally.
4. **The apparent English "monthly trend" was a confound.** Month and Section were entangled in the exam schedule — each month's exam represented only one section — so a simple month-over-month comparison would have produced a misleading conclusion. After separating the two variables, Section was the real driver, not Month.
 
**Key Recommendations**
 
1. Audit Grade 8 Mathematics' curriculum and assessment design — the 0% pass rate was consistent across every teacher and section.
2. Investigate what differs about Sections A and C in English, compared to Section B, which passed at 100%.
3. Address the Grade 8 Math issue immediately rather than waiting for future exams — the problem was consistent all year, with no sign of self-correcting.
---
 
---

## Dataset
 
200 synthetic exam records: Grades 7–9, Sections A–D, 4 subjects, 10 teachers, January–December 2025. Generated with DeepSeek for portfolio purposes — the data is synthetic, but the analysis was designed to simulate a realistic school performance investigation.
 
Columns: `StudentID`, `Grade`, `Section`, `Subject`, `ExamDate`, `Score`, `PassFlag`, `TeacherID`
 
---
 
## 🔎 The Investigation — 8 SQL Queries

Each query either confirms or rules out a possible explanation, narrowing the search step by step. 

### Query 0 — How healthy is overall school performance?
```sql
SELECT 
    COUNT(*) AS total_records,
    ROUND(AVG(score), 2) AS avg_score,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pass_rate
FROM students_performance;
```
**Result:** Overall pass rate looks reasonably healthy at a glance — but this single blended number hides what's coming next.

---

### Query 1 — Which grade is struggling most?
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

### Query 2 — Which subjects are driving poor results?
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

### Query 3 — Is the problem concentrated in specific subjects within Grade 8?
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

### Query 4 — Are certain sections underperforming?
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

### Query 5 — Are certain teachers consistently associated with better or worse outcomes?
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

### Query 6 — Has this always been broken, or did it start recently?
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

### Query 7 — Why does English's pass rate appear to swing by month?
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

## Stakeholder-Specific Answers
 
🎯 **School Director** — *"Is this affecting the whole school?"*
No. The problem is localized to Grade 8, not a school-wide performance issue.
 
🎯 **Principal** — *"Where should we focus the investigation?"*
Grade 8 Mathematics needs a curriculum/assessment review; Grade 8 English needs a section-level investigation — they are not the same problem.
 
🎯 **Mathematics Section Head** — *"Should we focus on one teacher?"*
No — the data doesn't support that. 0% occurred across every teacher and section, so the investigation should move toward curriculum and assessment factors, not personnel.
 
---
 
## Tools Used
 
PostgreSQL — all analysis performed in SQL.

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
