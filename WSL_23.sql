-- Create table for import

CREATE TABLE opening_round_results (
    surfer_short_name VARCHAR(50),
    surfer_full_name VARCHAR(100),
    total_score DECIMAL(4,2),
    advancement VARCHAR(100),
    wave_count VARCHAR(20),
    wave_scores_raw VARCHAR(200),
    heat_label INT,
    event_id INT,
    event_name VARCHAR(100),
    season INT,
    gender VARCHAR(10)
);

-- Combine all tables into one for import
INSERT INTO opening_round_results
SELECT * FROM [WSL_23].[dbo].['Round 1 M$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 1 W$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 2 M$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 2 W$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 3 M$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 3 W$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 4 M$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 4 W$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 5 M$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 5 W$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 7 M$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 7 W$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 8 M$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 8 W$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 9 M$']
UNION ALL
SELECT * FROM [WSL_23].[dbo].['Round 9 W$']

-- Check table
SELECT * FROM opening_round_results;

SELECT DISTINCT surfer_full_name
FROM opening_round_results

SELECT DISTINCT event_name
FROM opening_round_results

-- Change the wave_scores_raw column to a more readable format by splitting the scores into separate columns
ALTER TABLE opening_round_results
ADD high_wave DECIMAL(4,2),
    low_wave DECIMAL(4,2);

UPDATE opening_round_results
SET high_wave =
    CASE 
        WHEN CHARINDEX('+', wave_scores_raw) > 0
        THEN TRY_CAST(
                LEFT(wave_scores_raw, CHARINDEX('+', wave_scores_raw) - 1)
             AS DECIMAL(4,2))
        ELSE NULL
    END;

UPDATE opening_round_results
SET low_wave = TRY_CAST(
        LTRIM(RIGHT(wave_scores_raw, LEN(wave_scores_raw) - CHARINDEX('+', wave_scores_raw)))
    AS DECIMAL(4,2));


-- Which surfers had the highest total wave score in the opening rounds of the 2023 season?
SELECT TOP 10 surfer_full_name, total_score, event_name
FROM opening_round_results
WHERE season = 2023
ORDER BY total_score DESC;

-- Which surfers were the most consistent in their wave scores during the opening rounds of the 2023 season?
SELECT TOP 20 surfer_full_name, AVG(ABS(high_wave - low_wave)) AS avg_consistency_gap 
FROM opening_round_results 
WHERE season = 2023 AND high_wave IS NOT NULL 
GROUP BY surfer_full_name 
ORDER BY avg_consistency_gap ASC;

-- Which events are the most difficult for surfers in the opening rounds of the 2023 season, based on the average total scores?
SELECT event_name, AVG(total_score) AS average_total_score
FROM opening_round_results
WHERE season = 2023
GROUP BY event_name
ORDER BY average_total_score ASC;

-- Relationship between wave count and total score in the opening rounds of the 2023 season
SELECT wave_count, AVG(total_score) AS average_total_score
FROM opening_round_results
WHERE season = 2023
GROUP BY wave_count
ORDER BY average_total_score DESC;

-- Big wave surfers vs consistent surfers
SELECT surfer_full_name,
       AVG(high_wave) AS avg_high_wave,
       AVG(low_wave) AS avg_low_wave,
       AVG(total_score) AS avg_total_score
FROM opening_round_results
WHERE season = 2023 AND high_wave IS NOT NULL
GROUP BY surfer_full_name
ORDER BY avg_high_wave DESC;

-- Surfers who were sent to the elimination round in the opening rounds of the 2023 season the most often
SELECT TOP 15 surfer_full_name,
       COUNT(*) AS times_sent_to_elimination_round
FROM opening_round_results
WHERE season = 2023
  AND advancement LIKE '%ER%'
GROUP BY surfer_full_name
ORDER BY times_sent_to_elimination_round DESC;

-- Surfers who advanced directly to the next round the most often in the opening rounds of the 2023 season
SELECT TOP 15 surfer_full_name,
COUNT(*) AS times_advanced_directly
FROM opening_round_results
WHERE season = 2023 AND (advancement LIKE '%R/32%' OR advancement LIKE '%R/16%')
GROUP BY surfer_full_name
ORDER BY times_advanced_directly DESC;

