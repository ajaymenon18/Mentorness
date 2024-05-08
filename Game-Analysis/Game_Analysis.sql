
use game_analysis;

-- Problem Statement - Game Analysis dataset
-- 1) Players play a game divided into 3-levels (L0,L1 and L2)
-- 2) Each level has 3 difficulty levels (Low,Medium,High)
-- 3) At each level,players have to kill the opponents using guns/physical fight
-- 4) Each level has multiple stages at each difficulty level.
-- 5) A player can only play L1 using its system generated L1_code.
-- 6) Only players who have played Level1 can possibly play Level2 
--    using its system generated L2_code.
-- 7) By default a player can play L0.
-- 8) Each player can login to the game using a Dev_ID.
-- 9) Players can earn extra lives at each stage in a level.

select * from Game_Analysis.dbo.player_details;
select * from Game_Analysis.dbo.player_details;
select * from Game_Analysis.dbo.level_details2;


alter table Game_Analysis.dbo.player_details alter column L1_Status varchar(30);
alter table Game_Analysis.dbo.player_details alter column L2_Status varchar(30);
alter table Game_Analysis.dbo.player_details alter column P_ID INT NOT NULL;
alter table Game_Analysis.dbo.player_details add constraint PK_P_id PRIMARY KEY (P_ID);


alter table Game_Analysis.dbo.level_details2 drop myunknowncolumn;
alter table Game_Analysis.dbo.level_details2 alter column TimeStamp datetime NOT NULL;
alter table Game_Analysis.dbo.level_details2 alter column Dev_Id varchar(10) NOT NULL;
alter table Game_Analysis.dbo.level_details2 alter column Difficulty varchar(15);
alter table Game_Analysis.dbo.level_details2 add constraint PK_L_id PRIMARY KEY(P_ID);


-- pd (P_ID,PName,L1_status,L2_Status,L1_code,L2_Code)
-- ld (P_ID,Dev_ID,start_time,stages_crossed,level,difficulty,kill_count,
-- headshots_count,score,lives_earned)


-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
-- at level 0

SELECT pd.P_ID, ld.Dev_ID, pd.PName, ld.Difficulty FROM Game_Analysis.dbo.player_details pd
JOIN Game_Analysis.dbo.level_details2 ld ON pd.P_ID = ld.P_ID WHERE ld.Level = 0;

-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
--    3 stages are crossed

alter table Game_Analysis.dbo.level_details2 alter column Kill_Count INT;

SELECT pd.L1_Code, AVG(ld.Kill_Count) AS Avg_Kill_Count 
FROM Game_Analysis.dbo.player_details pd 
JOIN Game_Analysis.dbo.level_details2 ld ON pd.P_ID = ld.P_ID 
WHERE ld.Lives_Earned = 2 AND ld.Stages_crossed <= 3
GROUP BY pd.L1_code;

-- Q3) Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
 -- in decsreasing order of total number of stages crossed.

alter table Game_Analysis.dbo.level_details2 alter column Stages_crossed INT;

SELECT ld.Difficulty, SUM(ld.Stages_crossed) as Total_Stages_Crossed 
FROM Game_Analysis.dbo.level_details2 ld
JOIN Game_Analysis.dbo.player_details pd ON ld.P_ID = pd.P_ID
WHERE ld.Level = 2
AND ld.Dev_ID LIKE 'zm_%'
AND pd.L2_Status = 1
GROUP BY ld.Difficulty
ORDER BY Total_Stages_Crossed DESC;




-- Q4) Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.


SELECT ld.P_ID , COUNT(	DISTINCT CONVERT(DATE, TimeStamp)) AS Unique_Days_Played
FROM Game_Analysis.dbo.level_details2 ld
GROUP BY ld.P_ID
HAVING COUNT(DISTINCT CONVERT(DATE,Timestamp))> 1


-- Q5) Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.
-- Here we use a CTE, Common Table Expression 

WITH AverageKill AS (
    SELECT AVG(ld.Kill_Count) AS AvgKillCount
    FROM Game_Analysis.dbo.level_details2 ld
    WHERE ld.Difficulty = 'Medium'
)
SELECT ld.P_ID, ld.Level, SUM(ld.Kill_Count) AS Total_Kill_Count
FROM Game_Analysis.dbo.level_details2 ld, Averagekill ak
WHERE ld.Kill_Count > ak.AvgkillCount
AND ld.Difficulty = 'Medium'
GROUP BY ld.P_ID, ld.Level
ORDER BY ld.P_ID, ld.Level




-- Q6)  Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.


alter table Game_Analysis.dbo.level_details2 alter column Lives_Earned INT;

SELECT ld.Level,
	CASE 
		WHEN ld.Level = 1 THEN pd.L1_Code
		WHEN ld.Level = 2 THEN pd.L2_Code 
	END AS Level_Code, 
	SUM(ld.Lives_Earned) AS Total_Lives_Earned
FROM Game_Analysis.dbo.level_details2 ld
JOIN Game_Analysis.dbo.player_details pd 
ON pd.P_ID = ld.P_ID
WHERE ld.Level > 0
GROUP BY ld.Level,
	CASE
		WHEN ld.Level = 1 THEN pd.L1_Code
		WHEN ld.Level = 2 THEN pd.L2_Code
	END
ORDER BY ld.Level ASC

-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well

SELECT
	Dev_ID,
	Score,
	Difficulty, 
	ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Score DESC) AS Rank
FROM
	Game_Analysis.dbo.level_details2 
WHERE
	Rank <= 3

ORDER BY 
	Dev_ID, Rank ASC

SELECT * FROM (
    SELECT 
        Dev_ID,
        Score,
        Difficulty,
        ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Score DESC) AS Rank
    FROM 
        Game_Analysis.dbo.level_details2
) AS RankedScores
WHERE 
    Rank <= 3
ORDER BY 
    Dev_ID, Rank ASC;

-- Q8) Find first_login datetime for each device id
SELECT Dev_Id, MIN(TimeStamp) AS First_Login_Time 
FROM Game_Analysis.dbo.level_details2
GROUP BY Dev_ID
ORDER BY Dev_ID;

-- Q9) Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.

SELECT * FROM 
(  SELECT 
		Difficulty,
		Dev_id,
		Score,
		RANK() OVER (PARTITION BY Difficulty ORDER BY Score DESC) AS Rank
	FROM
		Game_Analysis.dbo.level_details2
) As RankedScores
WHERE
	Rank <= 5
ORDER BY
	Difficulty, Rank;
		


-- Q10) Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and 
-- first login datetime.

SELECT P_ID, Dev_ID, MIN(TimeStamp)
FROM Game_Analysis.dbo.level_details2
GROUP BY P_ID, Dev_ID
ORDER BY P_ID, Dev_ID

WITH FirstLogins AS (
    SELECT 
        P_ID,
        MIN(TimeStamp) AS First_Login_Time
    FROM 
        Game_Analysis.dbo.level_details2
    GROUP BY 
        P_ID
)
SELECT 
    ld.P_ID,
    ld.Dev_ID,
    fl.First_Login_Time
FROM 
    Game_Analysis.dbo.level_details2 AS ld
JOIN 
    FirstLogins AS fl ON ld.P_ID = fl.P_ID AND ld.TimeStamp = fl.First_Login_Time;



-- Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played -- by the player until that date.
-- a) window function

SELECT 
    P_ID, 
    CAST(TimeStamp AS DATE) AS Date,
    SUM(Kill_Count) OVER (PARTITION BY P_ID ORDER BY CAST(TimeStamp AS DATE)) AS Cumulative_Kills
FROM 
    Game_Analysis.dbo.level_details2
ORDER BY 
    P_ID, Date;

-- b) without window function
SELECT 
    a.P_ID, 
    CAST(a.TimeStamp AS DATE) AS Date,
    (SELECT SUM(b.Kill_Count) 
     FROM Game_Analysis.dbo.level_details2 b 
     WHERE b.P_ID = a.P_ID AND CAST(b.TimeStamp AS DATE) <= CAST(a.TimeStamp AS DATE)) AS Cumulative_Kills
FROM 
    Game_Analysis.dbo.level_details2 a
ORDER BY 
    a.P_ID, Date;

-- Q12) Find the cumulative sum of stages crossed over a start_datetime 

SELECT P_ID, TimeStamp, Stages_crossed, SUM(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS Cumulative_Stages_Crossed
FROM Game_Analysis.dbo.level_details2
ORDER BY P_ID, TimeStamp



-- Q13) Find the cumulative sum of an stages crossed over a start_datetime 
-- for each player id but exclude the most recent start_datetime

WITH PlayerSessions AS (
    SELECT
        P_ID,
        TimeStamp,
        Stages_crossed,
        ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY TimeStamp DESC) AS LatestSessionRank,
        SUM(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS Cumulative_Stages
    FROM
        Game_Analysis.dbo.level_details2
)

SELECT
    P_ID,
    TimeStamp,
    Stages_crossed,
    Cumulative_Stages
FROM
    PlayerSessions
WHERE
    LatestSessionRank > 1 
ORDER BY
    P_ID, TimeStamp;


-- Q14) Extract top 3 highest sum of score for each device id and the corresponding player_id

alter table Game_Analysis.dbo.level_details2 alter column Score INT;

WITH ScoreSums AS (
    SELECT
        Dev_ID,
        P_ID,
        SUM(Score) AS TotalScore,
        RANK() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS Rank
    FROM
        Game_Analysis.dbo.level_details2
    GROUP BY
        Dev_ID, P_ID
)

SELECT
    Dev_ID,
    P_ID,
    TotalScore
	
FROM
    ScoreSums
WHERE
    Rank <= 2
ORDER BY
    Dev_ID, Rank;

	-- Understand why this rank is done ??


-- Q15) Find players who scored more than 50% of the avg score scored by sum of 
-- scores for each player_id

WITH TotalScores AS (
    SELECT
        P_ID,
        SUM(Score) AS SumScore
    FROM
        Game_Analysis.dbo.level_details2
    GROUP BY
        P_ID
),
AverageScore AS (
    SELECT
        AVG(SumScore) AS AvgSumScore
    FROM
        TotalScores
)

SELECT 
    ts.P_ID,
    ts.SumScore
FROM 
    TotalScores ts, AverageScore av
WHERE 
    ts.SumScore > (av.AvgSumScore * 0.5)
ORDER BY 
    ts.P_ID;

-- Q16) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.

-- Q17) Create a function to return sum of Score for a given player_id.

CREATE FUNCTION GetSumOfScores (@PlayerID INT)
RETURNS INT
AS
BEGIN
    DECLARE @TotalScore INT;

    SELECT @TotalScore = SUM(Score)
    FROM Game_Analysis.dbo.level_details2
    WHERE P_ID = @PlayerID;

    RETURN @TotalScore;
END;
GO	