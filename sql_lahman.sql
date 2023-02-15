--1. Find all players in the database who played at Vanderbilt University. 
--   Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
--   Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT namefirst, namelast, SUM(salary)::numeric::money AS total_salary, COUNT(DISTINCT yearid) AS years_played
FROM people
INNER JOIN salaries
USING(playerid)
WHERE playerid IN (
	SELECT playerid
	FROM collegeplaying
	LEFT JOIN schools
	USING(schoolid)
	WHERE schoolid = 'vandy'
)
GROUP BY playerid, namefirst, namelast
ORDER BY total_salary DESC;
-- ANSWER: David Price

--2. Using the fielding table, group players into three groups based on their position: 
--   label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
--   and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT 
	(CASE
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
	END) AS position, 
	SUM(po) AS Putouts
FROM fielding
WHERE yearid = '2016'
GROUP BY position;

--3. Find the average number of strikeouts per game by decade since 1920. 
--   Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

--Michael's Code:
WITH decade_cte AS (SELECT generate_series(1920, 2020, 10) AS beginning_of_decade)
SELECT ROUND(SUM(hr) * 1.0 / (SUM(g) / 2), 2) AS hr_per_game,	ROUND(SUM(so) * 1.0 / (SUM(g) / 2), 2) AS so_per_game,
	beginning_of_decade::text || 's' AS decade
FROM teams
INNER JOIN decade_cte
ON yearid BETWEEN beginning_of_decade AND beginning_of_decade + 9
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;


-- My Code:
WITH decades AS (
	SELECT * FROM generate_series(1870, 2021, 10)AS gen)
SELECT gen AS Decade, ROUND(AVG((so / g)), 2) AS avg_strikeouts_per_game
FROM pitching p
INNER JOIN decades
ON p.yearid BETWEEN gen AND gen+9
GROUP BY Decade
ORDER BY Decade;

--4. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. 
--(A stolen base attempt results either in a stolen base or being caught stealing.) 
--Consider only players who attempted at least 20 stolen bases. 
--Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.

SELECT success.nameFirst, success.nameLast, CAST(CAST(Success.stolen_bases AS DECIMAL(5, 2)) / success.total_attempts * 100 AS DECIMAL(5, 2)) AS success_stealing 
FROM(SELECT nameFirst, nameLast, SUM(sb) AS stolen_bases, SUM(sb + cs) AS total_attempts
	FROM people
	INNER JOIN batting AS B
	USING(playerid)
	WHERE sb >= 20 
		AND yearid = 2016
	GROUP BY nameFirst, nameLast) AS success
ORDER BY success_stealing DESC
LIMIT 1;

--5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series?

SELECT teamid, yearid, MAX(w)
FROM teams
WHERE wswin = 'N' AND yearid BETWEEN 1970 AND 2016
GROUP BY teamid, yearid
ORDER BY MAX(w) DESC;

--   What is the smallest number of wins for a team that did win the world series?
SELECT teamid, yearid, MIN(w)
FROM teams
WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016
GROUP BY teamid, yearid
ORDER BY MIN(w);



--   Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. 
--The problem year is 1981, and this was a strike year. 

--Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? 
--   What percentage of the time?
WITH wins_by_year AS (SELECT yearid, franchid, w AS wins, wswin as world_series_win,
							RANK() OVER(PARTITION BY yearid ORDER BY w DESC) AS Rank_by_Total_Wins
						FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
						AND yearid <> 1981
						ORDER BY yearid)
SELECT yearid, franchid, world_series_win
FROM wins_by_year
WHERE wins_by_year.Rank_by_Total_Wins = 1 AND world_series_win = 'Y'
ORDER BY yearid
--ANSWER: 12/52

SELECT yearid, teamid, MAX(w)
FROM teams
WHERE yearid BETWEEN 1976 AND 2016
	AND yearid <> 1981
GROUP BY yearid, teamid
	
	
	
--MICHAEL'S CODE:
--WITH top_wins AS (	SELECT yearid, MAX(w) AS w	FROM teams	WHERE yearid between 1970 AND 2016	GROUP BY yearid),top_wins_teams AS (	SELECT teamid, yearid, w, wswin	FROM teams	INNER JOIN top_wins	USING(yearid, w))SELECT	SUM(CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END),	AVG(CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END)FROM top_wins_teamsWHERE yearid <> 1981 AND wswin IS NOT NULL;

-- SMITA'S CODE:
WITH topteam AS (
	SELECT yearid,
	MAX(w) AS win_time
	FROM teams
	WHERE yearid between 1970 AND 2016
		AND yearid != 1981
	GROUP By yearid),
team_wins AS(
 SELECT yearid, teamid, 
	w AS win_time,
	WSwin AS worldseries
FROM teams
	WHERE WSWin = 'Y'
),
wswin AS(
SELECT 
	CASE
	WHEN worldseries = 'Y' THEN 1
	ELSE 0
	END AS wswin_count,
	yearid, teamid, win_time, worldseries
-- 	ROUND(SUM(wswin_count)*100.0/COUNT(DISTINCT yearid), 2) AS percent
	FROM topteam
	LEFT JOIN team_wins
	USING (yearid, win_time)	
	
	ORDER by wswin_count DESC)
SELECT
	ROUND(SUM(wswin_count)*100.0/COUNT(DISTINCT yearid), 2) AS percent
	FROM wswin;


--6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award.

SELECT TSN_WINNERS_Names.playerid, TSN_WINNERS_Names.nameFirst, TSN_WINNERS_Names.nameLast,TSN_WINNERS_Names.Team2, COUNT( DISTINCT lgid) AS lg_count
		FROM (WITH TSN_WINNERS AS (SELECT awardsmanagers.yearid, awardsmanagers.playerid, awardsmanagers.lgid, managers.teamid AS Team, awardid
				FROM awardsmanagers
				INNER JOIN managers
				ON awardsmanagers.playerid = managers.playerid AND awardsmanagers.yearid = managers.yearid
				WHERE awardid LIKE '%TSN%')
			SELECT TSN_WINNERS.yearid, TSN_WINNERS.playerid, nameFirst, nameLast, TSN_WINNERS.Team AS Team2, TSN_WINNERS.lgid
			FROM people
			INNER JOIN TSN_WINNERS
			USING (playerid)) AS TSN_WINNERS_Names
		WHERE TSN_WINNERS_Names.playerid IN ('leylaji99', 'johnsda02', 'coxbo01', 'larusto01')
		GROUP BY TSN_WINNERS_Names.playerid, TSN_WINNERS_Names.nameFirst, TSN_WINNERS_Names.nameLast, TSN_WINNERS_Names.Team2
		ORDER BY lg_count DESC

SELECT Winners.First_Name, Winners.Last_Name, managers.teamid AS Team, COUNT( DISTINCT Winners.League) AS League_Count
FROM (WITH TSN_winners AS (SELECT playerid, awardid, yearid, lgid
						FROM awardsmanagers
						WHERE awardid LIKE '%TSN%'),
			TSN_named_winners AS (SELECT people.playerid AS playerid, nameFirst, nameLast
						 	FROM people
						 	INNER JOIN TSN_winners
						 	ON TSN_winners.playerid = people.playerid)
	SELECT TSN_named_winners.nameFirst AS First_Name, 
		TSN_named_winners.nameLast AS Last_Name, 
		TSN_winners.yearid AS Year, managers.lgid AS League
	FROM managers
	INNER JOIN TSN_winners
	ON TSN_winners.playerid = managers.playerid AND TSN_winners.yearid = managers.yearid
	INNER JOIN TSN_named_winners
	ON TSN_named_winners.playerid = managers.playerid) AS Winners
INNER JOIN managers
ON Winners.playerid 
GROUP BY Winners.First_Name, Winners.Last_Name, managers.teamid
HAVING COUNT(DISTINCT Winners.League) > 1;	

SELECT
 namefirst || ' ' || namelast AS full_name,
 awmg.yearid,
 awmg.lgid,
 teamid
FROM awardsmanagers AS awmg
INNER JOIN people
USING(playerid)
INNER JOIN managers AS m
ON awmg.playerid = m.playerid
 AND awmg.yearid = m.yearid
WHERE (awmg.playerid, awmg.awardid) IN (
 SELECT playerid,
  awardid
 FROM awardsmanagers
 WHERE awardid = 'TSN Manager of the Year'
  AND lgid IN ('NL','AL')
 GROUP BY playerid, awardid
 HAVING COUNT( DISTINCT lgid) = 2
)


--7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? 
-- 	 Only consider pitchers who started at least 10 games (across all teams). 
--   Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

SELECT playerid, (salary / so) AS efficiency
FROM (SELECT pitching.playerid, so, stint, salary
		FROM pitching
		INNER JOIN salaries
		ON pitching.playerid = salaries.playerid AND pitching.yearid = salaries.yearid
		WHERE pitching.yearid = 2016 AND pitching.gs >= 10
		ORDER BY salary DESC) AS salary_strikeouts
WHERE stint <> 2
ORDER BY efficiency DESC


--8. Find all players who have had at least 3000 career hits. 
SELECT playerid, SUM(h) AS total_hits
FROM batting
GROUP BY playerid
HAVING SUM(h) >= 3000
ORDER BY total_hits DESC


-- Report those players' names, total number of hits, and the year they were inducted into the hall of fame 
-- (If they were not inducted into the hall of fame, put a null in that column.) 
-- Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted column of the halloffame table.

WITH hit_count_three_thou AS (SELECT playerid, SUM(h) AS total_hits
								FROM batting
								GROUP BY playerid
								HAVING SUM(h) >= 3000
								ORDER BY total_hits DESC)
SELECT hit_count_three_thou.playerid, people.nameFirst AS First_Name, people.nameLast AS Last_Name, hit_count_three_thou.total_hits AS Total_Hits, halloffame.yearid AS Year_Inducted
			FROM people
			LEFT JOIN hit_count_three_thou
			ON people.playerid = hit_count_three_thou.playerid
			LEFT JOIN halloffame
			ON hit_count_three_thou.playerid = halloffame.playerid
			WHERE halloffame.inducted = 'Y'
ORDER BY hit_count_three_thou.total_hits DESC;



--9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.
WITH hits_by_team_player AS (SELECT teamid, playerid, SUM(h) AS total_hits
							FROM batting
							GROUP BY teamid, playerid
							HAVING SUM(h) >= 1000)
SELECT hits_by_team_player.playerid, nameFirst, nameLast, COUNT(teamid) AS team_count
FROM hits_by_team_player
INNER JOIN people
USING (playerid)
GROUP BY hits_by_team_player.playerid, nameFirst, nameLast
HAVING COUNT(teamid) >= 2

--10. Find all players who hit their career highest number of home runs in 2016. 
--    Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
--    Report the players' first and last names and the number of home runs they hit in 2016.

-- SELECT ID, nameFIRST, nameLast
-- FROM (WITH players AS (SELECT playerid, SUM(hr) AS Homers 
-- 				FROM batting 
-- 				WHERE yearid = 2016 
-- 				GROUP BY playerid)
-- 	SELECT players.playerid AS ID, yearid AS Year, players.Homers AS Homers2, MAX(hr) AS Max_Homers
-- 	FROM batting
-- 	INNER JOIN players
-- 	ON batting.playerid = players.playerid
-- 	WHERE players.Homers > 0
-- 	GROUP BY players.playerid, yearid, players.Homers
-- 	HAVING MAX(hr) = players.Homers) AS Homeruns
-- LEFT JOIN people
-- ON ID = people.playerid
-- WHERE year = 2016;