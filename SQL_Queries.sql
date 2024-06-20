SELECT *
FROM hr_data;

UPDATE hr_data
SET termdate = FORMAT(CONVERT(DATETIME, LEFT(termdate, 19), 120), 'yyyy-MM-dd');

-- Update from nvachar to date
-- First, add a new date column
ALTER TABLE hr_data
ADD new_termdate DATE;

-- Update the new date column with the converted values
UPDATE hr_data
SET new_termdate = CASE
    WHEN termdate IS NOT NULL AND ISDATE(termdate) = 1
        THEN CAST(termdate AS DATETIME)
        ELSE NULL
    END;

-- populate new column with age
UPDATE hr_data
SET age = DATEDIFF(YEAR, birthdate, GETDATE());

SELECT birthdate, age
FROM hr_data
ORDER BY age;

-- min and max ages
SELECT 
 MIN(age) AS min_age, 
 MAX(AGE) AS max_age
FROM hr_data;

-- 1) What's the average length of employment in the company?
SELECT
 AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
 FROM hr_data
 WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE();

-- 2) What's the age distribution in the company?
SELECT 
 MIN(age) AS Youngest, 
 MAX(age) AS Oldest
FROM hr_data;

-- age distribution 

SELECT
  age_group,
  COUNT(*) AS count
FROM (
  SELECT
    CASE
      WHEN age <= 21 AND age <= 30 THEN '21 to 30'
      WHEN age <= 31 AND age <= 40 THEN '31 to 40'
      WHEN age <= 41 AND age <= 50 THEN '41-50'
      ELSE '50+'
    END AS age_group
  FROM hr_data
  WHERE new_termdate IS NULL
) AS Subquery
GROUP BY age_group
ORDER BY age_group;
-- age group by gender

SELECT
  age_group,
  gender,
  COUNT(*) AS count
FROM (
  SELECT
    CASE
      WHEN age <= 21 AND age <= 30 THEN '21 to 30'
      WHEN age <= 31 AND age <= 40 THEN '31 to 40'
      WHEN age <= 41 AND age <= 50 THEN '41-50'
      ELSE '50+'
    END AS age_group,
	gender
  FROM hr_data
  WHERE new_termdate IS NULL
) AS Subquery
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- 3) Which department has the highest turnover rate?
-- get total count
-- get terminated count
-- terminated count/total count

SELECT
 department,
 total_count,
 terminated_count,
 round(CAST(terminated_count AS FLOAT)/total_count, 2) AS turnover_rate
FROM 
   (SELECT
   department,
   count(*) AS total_count,
   SUM(CASE
        WHEN new_termdate IS NOT NULL AND new_termdate <= getdate()
		THEN 1 ELSE 0
		END
   ) AS terminated_count
  FROM hr_data
  GROUP BY department
  ) AS Subquery
ORDER BY turnover_rate DESC;

-- 4) How have employee hire counts varied over time?
SELECT
hire_yr,
hires,
terminations,
hires - terminations AS net_change,
(hires - terminations)/hires AS percent_hire_change
FROM  
  (SELECT
  YEAR(hire_date) AS hire_yr,
  count(*) as hires,
  SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) terminations
  FROM hr_data
  GROUP BY year(hire_date)
  ) AS subquery
ORDER BY percent_hire_change ASC;

-- fixes zero values from the above query
SELECT
    hire_yr,
    hires,
    terminations,
    hires - terminations AS net_change,
    (round(CAST(hires - terminations AS FLOAT) / NULLIF(hires, 0), 2)) *100 AS percent_hire_change
FROM  
    (SELECT
        YEAR(hire_date) AS hire_yr,
        COUNT(*) AS hires,
        SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) terminations
    FROM hr_data
    GROUP BY YEAR(hire_date)
    ) AS subquery
ORDER BY hire_yr ASC;

-- 5) How many employees work remotely for each department?
SELECT
 location,
 count(*) AS count
 FROM hr_data
 WHERE new_termdate IS NULL
 GROUP BY location;
