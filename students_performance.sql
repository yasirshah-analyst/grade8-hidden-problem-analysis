create table students_performance(
	StudentID text,
	Grade int,
    Section text,
	Subject	text,
    ExamDate date,	
    Score int,	
    PassFlag text,	
    TeacherID text
    );

select* from students_performance;

-- How healthy is overall school performance?
select 
	count(*) as total_records,
	round(avg(score),2) as avg_score,
	round(100*sum(case when passflag = 'Yes' then 1 else 0 end)/count(*),2) as pass_rate
from students_performance;

-- Which grade is struggling most?
-- This query reveals the main story.
select 
	grade,
	count(*) as total_records,
	round(avg(score),2) as avg_score,
	round(100*sum(case when passflag = 'Yes' then 1 else 0 end)/count(*),2) as pass_rate
from students_performance
group by grade
order by grade;

-- Which subjects are driving poor results?
select 
	subject,
	count(*) as total_records,
	round(avg(score),2) as avg_score,
	round(100*sum(case when passflag = 'Yes' then 1 else 0 end)/count(*),2) as pass_rate
from students_performance
group by subject
order by avg_score;

-- Is the problem concentrated in specific subjects within a grade?
-- This is usually where the "why" emerges
select 
	grade,
	subject,
	count(*) as total_records,
	round(avg(score),2) as avg_score,
	round(100*sum(case when passflag = 'Yes' then 1 else 0 end)/count(*),2) as pass_rate
from students_performance
group by grade,subject
order by grade, avg_score;

-- Are certain sections underperforming?
select 
	grade,
	section,
	round(avg(score),2) as avg_score,
	round(100*sum(case when passflag = 'Yes' then 1 else 0 end)/count(*),2) as pass_rate
from students_performance
group by grade,section
order by grade ,avg_score;

-- Are some teachers consistently associated with better outcomes?
select 
	teacherid,
	round(avg(score),2) as avg_score,
	round(100*sum(case when passflag = 'Yes' then 1 else 0 end)/count(*),2) as pass_rate
from students_performance
WHERE grade = 8 AND subject in ('Mathematics','English')
group by teacherid
order by avg_score desc;

-- Has this always been broken, or did it start recently?
SELECT DATE_TRUNC('month', examdate) AS month,
	   subject,
       COUNT(*) AS students,
       ROUND(AVG(CASE WHEN passflag='Yes' THEN 1.0 ELSE 0 END)*100, 1) AS pass_rate_pct
FROM students_performance
WHERE grade = 8 AND subject in ('Mathematics','English')
GROUP BY DATE_TRUNC('month', examdate),subject
ORDER BY month;

-- Why does English's pass rate appear to swing by month?
SELECT 
    DATE_TRUNC('month', examdate) AS month,
    section,
    COUNT(*) AS total_records,
    ROUND(100.0 * SUM(CASE WHEN passflag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pass_rate_pct
FROM students_performance
WHERE grade = 8 AND subject = 'English'
GROUP BY DATE_TRUNC('month', examdate), section
ORDER BY month;