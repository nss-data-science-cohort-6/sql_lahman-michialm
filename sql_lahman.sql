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

-- SELECT success.nameFirst, success.nameLast, CAST(CAST(Success.stolen_bases AS DECIMAL(5, 2)) / success.total_attempts * 100 AS DECIMAL(5, 2)) AS success_stealing 
-- FROM(SELECT nameFirst, nameLast, SUM(sb) AS stolen_bases, SUM(sb + cs) AS total_attempts
-- 	FROM people
-- 	INNER JOIN batting AS B
-- 	USING(playerid)
-- 	WHERE sb >= 20 
-- 		AND yearid = 2016
-- 	GROUP BY nameFirst, nameLast) AS success
-- ORDER BY success_stealing DESC
-- LIMIT 1;

--5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series?

-- SELECT teamid, COUNT(w) as number_of_wins
-- FROM teams
-- WHERE teamid NOT IN (
-- 	SELECT teamid
-- 	FROM teams
-- 	WHERE yearid BETWEEN 1970 AND 2016 
-- 		AND wswin = 'Y')
-- GROUP BY teamid
-- ORDER BY number_of_wins DESC
-- LIMIT 1;

--   What is the smallest number of wins for a team that did win the world series?
-- WITH winning AS (SELECT yearid, teamid
-- 			   FROM teams
-- 			   WHERE yearid BETWEEN 1970 AND 2016
-- 			   	AND wswin = 'Y')
-- SELECT winning.yearid AS Year, winning.teamid AS Team, COUNT(w) as number_of_wins
-- FROM teams
-- INNER JOIN winning
-- USING (yearid)
-- GROUP BY Team, Year
-- ORDER BY number_of_wins ASC
-- LIMIT 1;



--   Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. 
--"The 1976 Reds became, and remain, the only team to sweep an entire multi-tier postseason, one of the crowning achievements of the franchise's Big Red Machine era.[1] 
--They also became the third NL team (following the Chicago Cubs in 1907–08 and the New York Giants in 1921–22) to win consecutive World Series, and remain the last to do so."
-- Wikipedia '1976 World Series'

--Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? 
--   What percentage of the time?
-- WITH problem_year AS (SELECT DISTINCT yearid
-- 					 FROM teams
-- 					 WHERE yearid = 1976),
-- -- 	Years AS (SELECT * 
-- -- 			  FROM generate_series(1970, 2016, 1) AS gen),
-- 	winning_teams AS (SELECT yearid, teamid, SUM(SELECT yearid, teamid, SUM(w) FROM teams GROUP BY yearid, teamid) AS wins
-- 					  FROM teams
-- 					  WHERE yearid BETWEEN 1970 AND 2016
-- 					 GROUP BY yearid, teamid
-- 					 ORDER BY wins DESC)
-- SELECT winning_teams.yearid AS Year, winning_teams.teamid AS Team, MAX(winning_teams.wins) AS Max_Wins
-- FROM teams
-- INNER JOIN problem_year
-- USING (yearid)
-- LEFT JOIN winning_teams
-- USING (yearid)
-- WHERE winning_teams.yearid NOT IN (SELECT yearid FROM problem_year)
-- GROUP BY Year, TEAM
-- ORDER BY Year;

-- WITH wins AS (SELECT yearid, teamid, SUM(w) as win_count
-- 				FROM teams 
-- 				WHERE yearid BETWEEN 1970 AND 2016
-- 				GROUP BY yearid, teamid)
-- SELECT DISTINCT wins.yearid, wins.teamid, MAX(wins.win_count)
-- FROM teams
-- INNER JOIN wins
-- USING (yearid)
-- GROUP BY wins.yearid, wins.teamid
-- ORDER BY yearid;

--6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award.
-- WITH management AS (SELECT yearid, playerid, nameFIRST, nameLast, managers.teamid AS Team
-- 				FROM people
-- 				INNER JOIN managers
-- 				USING (playerid)
-- 				GROUP BY yearid, playerid, Team)
-- SELECT TSN_Winners.yearid, nameFirst, nameLast, management.Team
-- FROM (SELECT yearid, playerid, awardid
-- FROM awardsmanagers
-- WHERE awardid LIKE '%TSN%') AS TSN_Winners
-- INNER JOIN management
-- USING (yearid)
-- GROUP BY TSN_Winners.yearid, nameFirst, nameLast


-- SELECT yearid, playerid, nameFIRST, nameLast, managers.teamid AS Team
-- FROM managers
-- INNER JOIN people
-- USING (playerid)
-- WHERE playerid IN (SELECT playerid FROM awardsmanagers WHERE awardid LIKE '%TSN%')
-- ORDER BY yearid

-- SELECT awardsmanagers.yearid, playerid, teamid
-- FROM awardsmanagers 
-- INNER JOIN managers
-- USING (playerid)
-- WHERE awardid LIKE '%TSN%'
-- GROUP BY awardsmanagers.yearid

--7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? 
-- 	 Only consider pitchers who started at least 10 games (across all teams). 
--   Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

-- SELECT DISTINCT p.playerid, SUM(so) AS strikeouts, SUM(salary) AS Total_Salary, CAST(SUM(so) / SUM(salary)) as EFFICIENCY
-- FROM pitching p
-- INNER JOIN salaries s
-- USING (playerid)
-- WHERE p.yearid = 2016 AND gs >= 10
-- GROUP BY p.playerid
-- ORDER BY EFFICIENCY