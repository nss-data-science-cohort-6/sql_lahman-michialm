--1. Find all players in the database who played at Vanderbilt University. 
--   Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
--   Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

-- SELECT p.namefirst, p.namelast, COALESCE(SUM(s2.salary), 0) AS total_salary
-- FROM people p
-- LEFT JOIN collegeplaying c
-- USING(playerid)
-- LEFT JOIN schools s
-- ON s.schoolid = c.schoolid
-- LEFT JOIN salaries s2
-- USING(playerid)
-- WHERE schoolname = 'Vanderbilt University'
-- GROUP BY p.namefirst, p.namelast
-- ORDER BY total_salary DESC;
-- ANSWER: David Price

--2. Using the fielding table, group players into three groups based on their position: 
--   label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
--   and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

-- SELECT 
-- 	(CASE
-- 		WHEN pos = 'OF' THEN 'Outfield'
-- 		WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
-- 		WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
-- 	END) AS position, 
-- 	SUM(po) AS Putouts
-- FROM fielding
-- WHERE yearid = '2016'
-- GROUP BY (CASE
-- 		WHEN pos = 'OF' THEN 'Outfield'
-- 		WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
-- 		WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
-- 	END);

--3. Find the average number of strikeouts per game by decade since 1920. 
--   Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

WITH decades AS (
	SELECT generate_series(1870, 1880, 10)AS gen)
SELECT yearid, gen
FROM pitching
INNER JOIN decades
ON yearid BETWEEN gen 
LIMIT 5;
