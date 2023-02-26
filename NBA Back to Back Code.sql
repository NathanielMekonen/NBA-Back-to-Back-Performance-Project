-- QUESTION: WHAT EFFECTS TO BACK TO BACK GAMES HAVE ON TEAM PERFORMANCE?

-- Create a new table that combines each individual season's box score data from 2010 to 2020
-- Only show applicable fields

CREATE TABLE allboxscores (
    Team NVARCHAR(50),
    Match_Up NVARCHAR(50),
    Game_Date DATE,
    W_L NVARCHAR(50),
    PTS TINYINT,
    FGM TINYINT,
    FGA TINYINT,
    FG_Percent FLOAT,
    _3PM TINYINT,
    _3PA TINYINT,
    _3P_Percent FLOAT,
    FTM TINYINT,
    FTA TINYINT,
    FT_Percent FLOAT, 
    REB TINYINT,
    AST TINYINT,
    STL TINYINT,
    BLK TINYINT,
    TOV TINYINT
)

INSERT INTO allboxscores
SELECT Team, Match_Up, Game_Date, W_L, PTS, FGM, FGA, FG, _3PM, _3PA, _3P, FTM, FTA, FT, REB, AST, STL, BLK, TOV
FROM (SELECT * FROM dbo.[2010-11_Regular_box_scores] UNION
      SELECT * FROM dbo.[2011-12_Regular_box_scores] UNION
      SELECT * FROM dbo.[2012-13_Regular_box_scores] UNION
      SELECT * FROM dbo.[2013-14_Regular_box_scores] UNION
      SELECT * FROM dbo.[2014-15_Regular_box_scores] UNION
      SELECT * FROM dbo.[2015-16_Regular_box_scores] UNION
      SELECT * FROM dbo.[2016-17_Regular_box_scores] UNION
      SELECT * FROM dbo.[2017-18_Regular_box_scores] UNION
      SELECT * FROM dbo.[2018-19_Regular_box_scores] UNION
      SELECT * FROM dbo.[2019-20_Regular_box_scores]) as subt

-- Want to add columns in our table to show the home team, away team, and the season
ALTER TABLE allboxscores
ADD Home_Team VARCHAR(50), Away_Team VARCHAR(50), Season VARCHAR(50)

-- Insert data into the three columns created
-- Extract home team from Match Up columns
UPDATE allboxscores SET Home_Team = 
    (CASE WHEN Match_Up LIKE '%vs.%' THEN SUBSTRING(Match_Up, 0, CHARINDEX(' vs.', Match_Up, 0)) ELSE SUBSTRING(Match_Up, CHARINDEX('@ ', Match_Up,0) + 2, LEN(Match_Up)) END)

-- Extract away team from Match Up columns
UPDATE allboxscores SET Away_Team = 
(CASE WHEN Match_Up LIKE '%@%' THEN SUBSTRING(Match_Up, 0, CHARINDEX(' @', Match_Up, 0)) ELSE SUBSTRING(Match_Up, CHARINDEX('vs. ', Match_Up,0) + 4, LEN(Match_Up)) END)

-- Find the season that the game was played
UPDATE allboxscores SET Season =
(CASE WHEN Game_Date BETWEEN '2010-10-01' AND '2011-06-30' THEN '2010/2011'
      WHEN Game_Date BETWEEN '2011-10-01' AND '2012-06-30' THEN '2011/2012'
      WHEN Game_Date BETWEEN '2012-10-01' AND '2013-06-30' THEN '2012/2013'
      WHEN Game_Date BETWEEN '2013-10-01' AND '2014-06-30' THEN '2013/2014'
      WHEN Game_Date BETWEEN '2014-10-01' AND '2015-06-30' THEN '2014/2015'
      WHEN Game_Date BETWEEN '2015-10-01' AND '2016-06-30' THEN '2015/2016'
      WHEN Game_Date BETWEEN '2016-10-01' AND '2017-06-30' THEN '2016/2017'
      WHEN Game_Date BETWEEN '2017-10-01' AND '2018-06-30' THEN '2017/2018'
      WHEN Game_Date BETWEEN '2018-10-01' AND '2019-06-30' THEN '2018/2019'
      WHEN Game_Date BETWEEN '2019-10-01' AND '2020-08-31' THEN '2019/2020' END) 

-- Replace the New Jersey Nets and New Orleans Hornets with the Brooklyn Nets and New Orleans Pelicans, respectively
UPDATE allboxscores
SET Team = REPLACE(REPLACE(Team, 'NJN', 'BKN'), 'NOH', 'NOP'),
    Match_Up = REPLACE(REPLACE(Match_Up, 'NJN', 'BKN'), 'NOH', 'NOP'),
    Home_Team = REPLACE(REPLACE(Home_Team, 'NJN', 'BKN'), 'NOH', 'NOP'),
    Away_Team = REPLACE(REPLACE(Away_Team, 'NJN', 'BKN'), 'NOH', 'NOP')



-- QUERIES


-- Query including all home and away data
SELECT *
FROM allboxscores
ORDER BY Game_Date



-- Query showing teams on the second night of a back-to-back
WITH prevgames as (
    SELECT 
        allboxscores.*,
        LAG(Game_Date,1) OVER(PARTITION BY Team ORDER BY Game_Date) as Previous_Game
    FROM allboxscores)

SELECT *
FROM prevgames
WHERE Game_Date = DATEADD(day, 1, Previous_Game)
ORDER BY Game_Date



-- Query showing difference between B2B and non B2B stats
-- Back to Back games CTE
WITH 
b2b as (
    SELECT
        Season, Team, AVG(CAST(PTS AS DECIMAL)) as B2B_PPG, AVG(FG_Percent) as B2B_FG_Percent, AVG(_3P_Percent) as B2B_3p_Percent, AVG(FT_Percent) as B2B_FT_Percent, AVG(CAST(REB AS DECIMAL)) as B2B_RPG, 
        AVG(CAST(AST AS DECIMAL)) as B2B_APG, AVG(CAST(STL AS DECIMAL)) as B2B_SPG, AVG(CAST(BLK AS DECIMAL)) as B2B_BPG, AVG(CAST(TOV AS DECIMAL)) as B2B_TPG, COUNT(Game_Date) as B2B_Games
    FROM (
         SELECT allboxscores.*, LAG(Game_Date,1) OVER(PARTITION BY Team ORDER BY Game_Date) as Previous_Game
         FROM allboxscores) as subq
    WHERE Game_Date = DATEADD(day, 1, Previous_Game)
    GROUP BY Season, Team),
-- Non Back to Back games CTE
rest as (
    SELECT 
        Season, Team, AVG(CAST(PTS AS DECIMAL)) as Rest_PPG, AVG(FG_Percent) as Rest_FG_Percent, AVG(_3P_Percent) as Rest_3p_Percent, AVG(FT_Percent) as Rest_FT_Percent, AVG(CAST(REB AS DECIMAL)) as Rest_RPG, 
        AVG(CAST(AST AS DECIMAL)) as Rest_APG, AVG(CAST(STL AS DECIMAL)) as Rest_SPG, AVG(CAST(BLK AS DECIMAL)) as Rest_BPG, AVG(CAST(TOV AS DECIMAL)) as Rest_TPG, COUNT(Game_Date) as Rest_Games
    FROM (
         SELECT allboxscores.*, LAG(Game_Date,1) OVER(PARTITION BY Team ORDER BY Game_Date) as Previous_Game
         FROM allboxscores) as subq
    WHERE Game_Date <> DATEADD(day, 1, Previous_Game) OR Previous_Game IS NULL
    GROUP BY Season, Team)

SELECT season, team, Rest_Games, B2B_Games,
                    Rest_PPG, B2B_PPG, B2B_PPG - Rest_PPG as Point_Total_Diff, ((B2B_PPG - Rest_PPG)/Rest_PPG * 100) as Point_Percent_Diff,
                     Rest_FG_Percent, B2B_FG_Percent, ((B2B_FG_Percent - Rest_FG_Percent)/Rest_FG_Percent * 100) as FG_Percent_Diff,
                     Rest_3P_Percent, B2B_3P_Percent, ((B2B_3P_Percent - Rest_3P_Percent)/Rest_3P_Percent * 100) as _3P_Percent_Diff,
                     Rest_FT_Percent, B2B_FT_Percent, ((B2B_FT_Percent - Rest_FT_Percent)/Rest_FT_Percent * 100) as FT_Percent_Diff,
                     Rest_RPG, B2B_RPG, B2B_RPG - Rest_RPG as Reb_Total_Diff, ((B2B_RPG - Rest_RPG)/Rest_RPG * 100) as Reb_Percent_Diff,
                     Rest_APG, B2B_APG, B2B_APG - Rest_APG as Ast_Total_Diff, ((B2B_APG - Rest_APG)/Rest_APG * 100) as Ast_Percent_Diff,
                     Rest_SPG, B2B_SPG, B2B_SPG - Rest_SPG as Stl_Total_Diff, ((B2B_SPG - Rest_SPG)/Rest_SPG * 100) as Stl_Percent_Diff,
                     Rest_BPG, B2B_BPG, B2B_BPG - Rest_BPG as Blk_Total_Diff, ((B2B_BPG - Rest_BPG)/Rest_BPG * 100) as Blk_Percent_Diff,
                     Rest_TPG, B2B_TPG, B2B_TPG - Rest_TPG as Tov_Total_Diff, ((B2B_TPG - Rest_TPG)/Rest_TPG * 100) as Tov_Percent_Diff       
FROM (
    SELECT 
        rest.season, rest.team, Rest_PPG, Rest_FG_Percent, Rest_3p_Percent, Rest_FT_Percent, Rest_RPG, Rest_APG, Rest_SPG, Rest_BPG, Rest_TPG, Rest_Games,
        B2B_PPG, B2B_FG_Percent, B2B_3p_Percent, B2B_FT_Percent, B2B_RPG, B2B_APG, B2B_SPG, B2B_BPG, B2B_TPG, B2B_Games
    FROM rest
    LEFT JOIN b2b
    ON rest.season = b2b.season AND rest.Team = b2b.Team) as mainq



-- Query showing win/loss record, B2Bs, and Non B2Bs
WITH 
wins AS 
    (SELECT Team, Season, COUNT(W_L) as Wins
    FROM allboxscores
    WHERE W_L = 'W'
    GROUP BY Team, Season),
losses AS 
    (SELECT Team, Season, COUNT(W_L) as Losses
    FROM allboxscores
    WHERE W_L = 'L'
    GROUP BY Team, Season),
b2bs AS 
    (SELECT
        subq.team, subq.season, COUNT(Game_Date) as B2B_Games
    FROM (
         SELECT allboxscores.*, LAG(Game_Date,1) OVER(PARTITION BY Team ORDER BY Game_Date) as Previous_Game
         FROM allboxscores) as subq
    WHERE Game_Date = DATEADD(day, 1, Previous_Game)
    GROUP BY Team, Season),
b2bwins AS
    (SELECT
        subq.team, subq.season, COUNT(W_L) as B2B_Wins
    FROM (
         SELECT allboxscores.*, LAG(Game_Date,1) OVER(PARTITION BY Team ORDER BY Game_Date) as Previous_Game
         FROM allboxscores) as subq
    WHERE Game_Date = DATEADD(day, 1, Previous_Game) AND W_L = 'W'
    GROUP BY Team, Season)

SELECT
    wins.Team, wins.Season, Wins, Losses, b2bs.B2B_Games, (Wins + Losses) - b2bs.B2B_Games AS Rest_Games, B2B_Wins, (Wins - B2B_Wins) AS Rest_Wins
FROM wins
LEFT JOIN losses
ON wins.Team = losses.Team AND wins.Season = losses.Season
LEFT JOIN b2bs
ON wins.Team = b2bs.Team AND wins.Season = b2bs.Season
LEFT JOIN b2bwins
ON wins.Team = b2bwins.Team AND wins.Season = b2bwins.Season
ORDER BY wins.Team, wins.Season



-- Query showing number of missed games due to injury by team by season vs number of B2Bs
WITH injuries AS (
    Select 
        (CASE WHEN date BETWEEN '2010-10-01' AND '2011-06-30' THEN '2010/2011'
            WHEN date BETWEEN '2011-10-01' AND '2012-06-30' THEN '2011/2012'
            WHEN date BETWEEN '2012-10-01' AND '2013-06-30' THEN '2012/2013'
            WHEN date BETWEEN '2013-10-01' AND '2014-06-30' THEN '2013/2014'
            WHEN date BETWEEN '2014-10-01' AND '2015-06-30' THEN '2014/2015'
            WHEN date BETWEEN '2015-10-01' AND '2016-06-30' THEN '2015/2016'
            WHEN date BETWEEN '2016-10-01' AND '2017-06-30' THEN '2016/2017'
            WHEN date BETWEEN '2017-10-01' AND '2018-06-30' THEN '2017/2018'
            WHEN date BETWEEN '2018-10-01' AND '2019-06-30' THEN '2018/2019'
            WHEN date BETWEEN '2019-10-01' AND '2020-08-31' THEN '2019/2020' END) as Season,
        (CASE WHEN Team = '76ers' THEN 'PHI'
            WHEN Team = 'Blazers' THEN 'POR'
            WHEN Team = 'Bobcats' THEN 'CHA'
            WHEN Team = 'Bucks' THEN 'MIL'
            WHEN Team = 'Bullets' THEN 'WAS'
            WHEN Team = 'Bulls' THEN 'CHI'
            WHEN Team = 'Cavaliers' THEN 'CLE'
            WHEN Team = 'Celtics' THEN 'BOS'
            WHEN Team = 'Clippers' THEN 'LAC'
            WHEN Team = 'Grizzlies' THEN 'MEM'
            WHEN Team = 'Hawks' THEN 'ATL'
            WHEN Team = 'Heat' THEN 'MIA'
            WHEN Team = 'Hornets' THEN 'CHA'
            WHEN Team = 'Jazz' THEN 'UTA'
            WHEN Team = 'Kings' THEN 'SAC'
            WHEN Team = 'Knicks' THEN 'NYK'
            WHEN Team = 'Lakers' THEN 'LAL'
            WHEN Team = 'Magic' THEN 'ORL'
            WHEN Team = 'Mavericks' THEN 'DAL'
            WHEN Team = 'Nets' THEN 'BKN'
            WHEN Team = 'Nuggets' THEN 'DEN'
            WHEN Team = 'Pacers' THEN 'IND'
            WHEN Team = 'Pelicans' THEN 'NOP'
            WHEN Team = 'Pistons' THEN 'DET'
            WHEN Team = 'Raptors' THEN 'TOR'
            WHEN Team = 'Rockets' THEN 'HOU'
            WHEN Team = 'Spurs' THEN 'SAS'
            WHEN Team = 'Suns' THEN 'PHX'
            WHEN Team = 'Thunder' THEN 'OKC'
            WHEN Team = 'Timberwolves' THEN 'MIN'
            WHEN Team = 'Warriors' THEN 'GSW'
            WHEN Team = 'Wizards' THEN 'WAS' END) AS Team_Name,
        Relinquished
From dbo.[injuries_2010-2020]
WHERE Team IS NOT NULL AND Relinquished IS NOT NULL),
b2bs AS 
    (SELECT
        subq.team, subq.season, COUNT(Game_Date) as B2B_Games
    FROM (
         SELECT allboxscores.*, LAG(Game_Date,1) OVER(PARTITION BY Team ORDER BY Game_Date) as Previous_Game
         FROM allboxscores) as subq
    WHERE Game_Date = DATEADD(day, 1, Previous_Game)
    GROUP BY Team, Season)

SELECT
    injuries.Season, Team_Name, Count(Relinquished) as Num_Injured, B2B_Games
FROM injuries
LEFT JOIN b2bs
ON injuries.season = b2bs.Season AND injuries.team_name = b2bs.team
WHERE injuries.Season IS NOT NULL
GROUP BY injuries.season, Team_Name, B2B_Games
ORDER BY Season, Team_Name








