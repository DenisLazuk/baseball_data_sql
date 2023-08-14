-- Task 1. Heaviest Hitters
-- This award goes to the team with the highest average weight of its batters on a given year.
WITH weights AS(
  SELECT batting.yearid AS year, teams.name AS team, ROUND(AVG(weight),2) AS avg_weight
	FROM batting
	JOIN people
		ON batting.playerid = people.playerid
	JOIN teams
		ON batting.team_id = teams.id
  WHERE weight IS NOT NULL
	GROUP BY batting.yearid, teams.name
),
  winner AS(
    SELECT MAX(avg_weight) as highest_avg, year
    FROM weights
    GROUP BY year
)
SELECT winner.year, highest_avg, team
FROM winner
JOIN weights
 ON winner.year = weights.year AND winner.highest_avg = weights.avg_weight
ORDER BY 1 DESC;

-- Task 2. Shortest Sluggers
-- This award goes to the team with the smallest average height of its batters on a given year.
-- This query should look very similar to the one you wrote to find the heaviest teams.
WITH heights AS(
  SELECT batting.yearid AS year, ROUND(AVG(height),2) as avg_height, teams.name AS team
  FROM batting
  JOIN people
  	ON batting.playerid = people.playerid
  JOIN teams
  	ON batting.team_id = teams.id
  WHERE people.height IS NOT NULL
  GROUP BY 1,3
),
  winner AS(
    SELECT MIN(avg_height) AS min_avg_height, year
    FROM heights
    GROUP BY 2
)
SELECT winner.year, winner.min_avg_height, heights.team
FROM winner
JOIN heights
	ON winner.year = heights.year AND winner.min_avg_height = heights.avg_height
ORDER BY 1 DESC;

-- Task 3. Biggest Spenders
-- This award goes to the team with the largest total salary of all players in a given year.
WITH total_salaries AS(
  SELECT salaries.yearid AS year, teams.name AS team, SUM(salary) AS total_salary
  FROM salaries
  JOIN teams
  ON salaries.teamid = teams.teamid
	GROUP BY 1, 2
),
winner AS (
  SELECT year, MAX(total_salary) as max_total_salary
  FROM total_salaries
  GROUP BY 1
)
SELECT winner.year, winner.max_total_salary, total_salaries.team
FROM winner
JOIN total_salaries
	ON  winner.year = total_salaries.year AND winner.max_total_salary = total_salaries.total_salary
ORDER BY year DESC;

-- Task 4. Most Bang For Their Buck In 2010
-- This award goes to the team that had the smallest “cost per win” in 2010.
-- Cost per win is determined by the total salary of the team divided by the number of wins in a given year.


SELECT teams.name AS most_bang_for_their_buck,
	teams.w AS wins,
  	SUM(salary) AS team_salary,
    	ROUND((SUM(salary) / teams.w)) AS cost_per_win
 FROM salaries
 JOIN teams
 	ON salaries.teamid = teams.teamid
WHERE salaries.yearid = 2010 AND teams.yearid = 2010
GROUP BY 1, 2
ORDER BY 4 ASC
LIMIT 1;

-- Task 5. Priciest Starter
-- This award goes to the pitcher who, in a given year, cost the most money per game in which they were the starting pitcher.
-- Note that many pitchers only started a single game, so to be eligible for this award, you had to start at least 10 games.

WITH join_table AS(
  SELECT pitching.yearid, people.namegiven, pitching.teamid, pitching.gs, salary
	FROM pitching
	JOIN salaries
		ON pitching.playerid = salaries.playerid AND pitching.teamid = salaries.teamid AND pitching.yearid = salaries.yearid
	JOIN people
		ON pitching.playerid = people.playerid
	WHERE gs >= 10
),
winner AS(
 SELECT MAX(salary) AS max_salary, yearid
 FROM join_table
 GROUP BY 2
)
SELECT winner.yearid, winner.max_salary, join_table.namegiven, join_table.teamid, join_table.gs
FROM winner
JOIN join_table
	ON winner.yearid = join_table.yearid AND winner.max_salary = join_table.salary
ORDER BY yearid DESC;

-- Task 6. Bean Machine: The pitcher most likely to hit a batter with a pitch
-- This award goes to the pitcher who hit batters by pitch most

SELECT pitching.playerid, CONCAT(people.namefirst,' ', people.namelast) AS name, people.debut, SUM(hbp) as bean_machine
FROM pitching
JOIN people
	ON pitching.playerid = people.playerid
WHERE hbp IS NOT NULL
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 1;

-- Task 7. Canadian Ace: The pitcher with the lowest ERA who played for a team whose stadium is in Canada
-- This award goes to the pitcher who has the lowest ERA and plays in Canadian-based park.
WITH era_table AS(
  SELECT pitching.playerid, CONCAT(people.namefirst,' ', people.namelast) AS name, pitching.team_id, teams.park, MIN(pitching.era) as min_era
	FROM pitching
	JOIN people
		ON pitching.playerid = people.playerid
	JOIN teams
		ON pitching.teamid = teams.teamid
	WHERE pitching.era IS NOT NULL
	GROUP BY 1, 2, 3, 4
	ORDER BY min_era DESC
),
parks_in_canada AS(
  SELECT DISTINCT parks.parkname, parks.country
	FROM parks
	JOIN teams
		ON parks.parkname = teams.park
	WHERE parks.country != 'US'
)
SELECT parkname, country, name, min_era
FROM parks_in_canada
JOIN era_table
	ON parks_in_canada.parkname = era_table.park
LIMIT 1;

-- Task 8. Worst of the Best: The pitcher or batter inducted into the hall of fame with the worst career stats (you can decide what stat to look at)
-- Stats Used: Homeruns, Runs Batted In and Strikeouts
-- Players with more than 1000 games
WITH summary_table AS (
  SELECT batting.playerID, CONCAT(people.namefirst,' ', people.namelast) AS name, SUM(batting.hr) as sum_of_home_runs, SUM(batting.rbi) as sum_of_rbi, SUM(batting.so) as sum_of_so, SUM(batting.g) as sum_of_games
	FROM batting
  JOIN people
    ON batting.playerid = people.playerid
  
  GROUP BY 1, 2
  ORDER BY 3 DESC
),
poor_player AS(
  SELECT *
  FROM summary_table
  WHERE sum_of_home_runs < 10 AND sum_of_rbi < 10 AND sum_of_so < 10
)
SELECT *
FROM halloffame
LEFT JOIN poor_player
	ON halloffame.playerid = poor_player.playerid
WHERE category = 'Player' AND sum_of_games > 1000
