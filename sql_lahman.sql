--1. Find all players in the database who played at Vanderbilt University. 
--   Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
--   Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
-- SELECT namefirst, namelast, SUM(salary)::numeric::money AS total_salary, COUNT(DISTINCT yearid) AS years_played
-- FROM people
-- INNER JOIN salaries
-- USING(playerid)
-- WHERE playerid IN (
-- 	SELECT playerid
-- 	FROM collegeplaying
-- 	LEFT JOIN schools
-- 	USING(schoolid)
-- 	WHERE schoolid = 'vandy'
-- )
-- GROUP BY playerid, namefirst, namelast
-- ORDER BY total_salary DESC;
-- ANSWER: David Price

--2. Using the fielding table, group players into three groups based on their position: 
--   label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
--   and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

-- SELECT 
-- 	(CASE
-- 		WHEN pos = 'OF' THEN 'Outfield'
-- 		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
-- 		WHEN pos IN ('P', 'C') THEN 'Battery'
-- 	END) AS position, 
-- 	SUM(po) AS Putouts
-- FROM fielding
-- WHERE yearid = '2016'
-- GROUP BY position;

--3. Find the average number of strikeouts per game by decade since 1920. 
--   Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

-- WITH decades AS (
-- 	SELECT * FROM generate_series(1870, 2021, 10)AS gen)
-- SELECT gen AS Decade, ROUND(AVG((so / g)), 2) AS avg_strikeouts_per_game
-- FROM pitching p
-- INNER JOIN decades
-- ON p.yearid BETWEEN gen AND gen+9
-- GROUP BY Decade;

--4. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. 
--(A stolen base attempt results either in a stolen base or being caught stealing.) 
--Consider only players who attempted at least 20 stolen bases. 
--Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.

SELECT nameFirst, nameLast, stolen_bases, total_attempts, (stolen_bases / total_attempts) AS success
FROM(SELECT nameFirst, nameLast, SUM(sb) AS stolen_bases, SUM(cs) AS caught_stealing, (SUM(sb) + SUM(cs)) AS total_attempts
FROM people
INNER JOIN batting
USING(playerid)
WHERE sb >= 20 AND yearid = 2016
GROUP BY nameFirst, nameLast) AS bases
ORDER BY success DESC;
