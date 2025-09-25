/* Starting EDA, looking at the entire dataset, then will run some basic queries to get an idea of the data. */

SELECT*
FROM hate_crime;

---------------------------------------------------------------------------------------------------------------


SELECT
	incident_id
FROM hate_crime
ORDER BY
	incident_id DESC;


-- Incident ID 1,522,894 is the last, and Incident ID 2 is the first, but are there that many records?

SELECT 
	COUNT(incident_id) AS incidents
FROM hate_crime;

-- Counting the Incident IDs returns 253,776, not the 1.5 million the Incident ID indicates.




-- CONTEXT:

-- The FBI dataset used in this analysis spans 1991 - 2023, or 33 years, and contains almost 254,000 records.
-- It is estimated that 40% - 50% of all hate crimes are not reported to law enforcement, so the number of incidents in this dataset could represent only half the actual number of crimes.
-- According to USAFacts.org, between 2010 and 2019, an estimated 56% of hate crimes were not reported.
-- Other research suggests the number of hate crimes could be as high as 300,000 per year, which, if true, would dwarf the number reported in this dataset.
-- Just to note, 33 x 300,000 = 9.9 million.
-- However, this sample size is still significant, and can provide key insights.

-- The discrepancy in reported crimes can be due to many factors, including:
	-- Victims may not recognize the crime as a hate crime
	-- Victims are reluctant to report crimes
	-- Disagreement among law enforcement about what constitutes a hate crime
	-- Fear of further harassment or discrimination




-- TIME-BASED QUERIES


-- To make aggregating by dates easier, the first step is to take the incident_date and create new columns for year, month, day, and day of the week.
-- This can be edited and used as a CTE to search against the new columns.

SELECT
    incident_date,
    STRFTIME('%Y', incident_date) AS year,
    STRFTIME('%m', incident_date) AS month,
    STRFTIME('%d', incident_date) AS day,
    STRFTIME('%w', incident_date) AS day_of_week_num,
    CASE STRFTIME('%w', incident_date)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END AS day_of_week_name
FROM
    hate_crime;



-- How many incidents were there each year? What pattern emerges?

SELECT
	STRFTIME('%Y', incident_date) AS year,
	COUNT(incident_id) AS incidents
FROM hate_crime
GROUP BY year
ORDER BY incidents DESC;

-- According to the data, the only 4 years with over 10,000 incidents per year are also the most recent: 2020, 2021, 2022, and 2023.


-- How many incidents were there each month? What pattern emerges?

SELECT
	STRFTIME('%m', incident_date) AS month,
	COUNT(incident_id) AS incidents
FROM hate_crime
GROUP BY month
ORDER BY month;

-- The coldest months - November, December, January, and February - appear to have a moderate lull in activity. This could be due to the holiday season and/or the weather. February could also be low because it has fewer days than any other month.


-- How many incidents were there each day of the week? What pattern emerges?

SELECT
	STRFTIME('%w', incident_date) AS day_of_week_num,
    CASE STRFTIME('%w', incident_date)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END AS day_of_week_name,
	COUNT(incident_id) AS incidents
FROM hate_crime
GROUP BY day_of_week_name
ORDER BY day_of_week_num;

-- While there are days of the week that are clear max and min cases, the reason for this requires further study.


-- How many incidents were there each date? Order by number of incidents descending.

SELECT
	incident_date,
	COUNT(incident_id) AS incidents
FROM hate_crime
GROUP BY incident_date
ORDER BY incidents DESC;



-- CONTEXT IS KEY. WHAT MAJOR EVENTS HAPPENED ON OR NEAR TO THE DATES WITH THE HIGHEST RATES OF HATE CRIMES?
-- 10 OF THE TOP 12 DATES WERE ON AND IMMEDIATELY FOLLOWING 9/11.
-- OF THE 2 REMAINING DATES, ONE CORRELATES WITH THE RODNEY KING RIOTS AND THE OTHER WITH THE GEORGE FLOYD MURDER.
-- IN FACT, THE TOP 25 MOST ACTIVE DATES ARE RELATED TO THOSE 3 EVENTS.
-- WHAT CHARACTERISTICS TIE THOSE 3 EVENTS TOGETHER THAT MIGHT PROVIDE INSIGHT?




-- LOCATION-MUNICIPALITY QUERIES


-- How many incidents were there in each agency type?

SELECT
	agency_type_name,
	COUNT(incident_id) AS incidents
FROM hate_crime
GROUP BY
	agency_type_name;

-- That city agencies have the lion's share of reported incidents is not surprising, as they are population centers.
-- It is curious that Universiy or College is separated. Those cases could also be grouped with City or County or State Police.


-- How many incidents were there in each state?

SELECT
	state_abbr,
	state_name,
	COUNT(incident_id) AS incidents,
	COUNT(incident_id) / 33 AS incidents_per_yr_avg
FROM hate_crime
GROUP BY
	state_abbr,
	state_name
ORDER BY incidents DESC;

-- Similar to the agency type, it is not surprising that the states with the highest incidence rates are the some of the most populous, like CA, NJ, and NY.
-- However, those 3 states are approximately 10,000-30,000 incidents higher than the state ranked 4th. Is this only due to population density?


-- How many incidents were there per population group?

SELECT
	population_group_description,
	population_group_code,
	COUNT(incident_id) AS incidents,
	COUNT(incident_id) / 33 AS incidents_per_yr_avg
FROM hate_crime
GROUP BY
	population_group_description,
	population_group_code
ORDER BY population_group_code;

-- Contrary to conventional wisdom, the size of the municipality does not appear to correlate with higher incidence rates, with the exception of cities over 1 million in population.

-- What are the top 20 agencies by incident count all time?

SELECT
	pub_agency_name,
	COUNT(incident_id) AS incidents
FROM hate_crime
GROUP BY pub_agency_name
ORDER BY incidents DESC
LIMIT 20;

-- What are the top 5 agencies by incident count per year?

WITH ranked_agencies AS (
	SELECT
		STRFTIME('%Y', incident_date) AS year,
		pub_agency_name,
		COUNT(incident_id) AS incidents,
		RANK() OVER (PARTITION BY STRFTIME('%Y', incident_date) ORDER BY COUNT(incident_id) DESC) AS rank
	FROM hate_crime
	GROUP BY year, pub_agency_name
)
SELECT
	year,
	pub_agency_name,
	incidents
FROM ranked_agencies
WHERE rank <= 5
ORDER BY year DESC, rank ASC;





-- INCIDENT-VICTIM-OFFENDER QUERIES


-- How many incidents/victims/offenders per year?

SELECT
	STRFTIME('%Y', incident_date) AS year,
	COUNT(incident_id) AS incidents,
	SUM(total_individual_victims) AS victims,
	SUM(total_offender_count) AS offenders
FROM hate_crime
GROUP BY year;


-- How many incidents/victims/offenders per date?

SELECT
	incident_date,
	COUNT(incident_id) AS incidents,
	SUM(total_individual_victims) AS victims,
	SUM(total_offender_count) AS offenders
FROM hate_crime
GROUP BY incident_date
ORDER BY incidents DESC;


-- How many incidents/victims/offenders per state?

SELECT
	state_name,
	COUNT(incident_id) AS incidents,
	SUM(total_individual_victims) AS victims,
	SUM(total_offender_count) AS offenders
FROM hate_crime
GROUP BY
	state_name;


-- How many incidents/victims/offenders per state per year?

SELECT
	state_name,
	STRFTIME('%Y', incident_date) AS year,
	COUNT(incident_id) AS incidents,
	SUM(total_individual_victims) AS victims,
	SUM(total_offender_count) AS offenders
FROM hate_crime
GROUP BY
	state_name,
	year;

-- These queries show the difference between number of incidents, victims, and offenders is unpredictable. More often, it appears more people are involved than there are incidents.




-- THE FOLLOWING COLUMNS HAVE ROWS WITH VALUES STRUNG TOGETHER WITH ; AS A DELIMETER:
	-- OFFENSE_NAME, VICTIM_TYPES, AND BIAS_DESC COLUMNS COMBINE MULTIPLE VALUES WITH A ; AS A DELIMITER, MAKING IT HARD TO AGGREGATE EACH INDIVIDUAL VALUE.



-- If only searching for one offense_name value, use a LIKE % query:

-- Looking at aggravated assault as an example:

SELECT
	offense_name,
	COUNT(offense_name) AS count
FROM hate_crime
WHERE offense_name LIKE '%Aggravated Assault%';

-- Searching for each offense name individually is tedious, and not practical, as it does not allow for direct comparison.


               
-- Breaking apart these columns into multiple columns in order to calculate aggregates is unweildy.
-- Instead, a CTE can be used to count each individual value.


-- How many incidents of each offense name were there?

WITH RECURSIVE SplitValues AS (
	SELECT
        incident_id,
        offense_name || ';' AS remaining_string,
        '' AS offense,
        1 AS part_number
	FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1),
        part_number + 1
    FROM SplitValues
    WHERE INSTR(remaining_string, ';') > 0
)
SELECT
    TRIM(individual_value) AS offense,
    COUNT(*) AS count
FROM (
    SELECT
        TRIM(offense) AS individual_value
    FROM SplitValues
    WHERE TRIM(offense) <> ''
)
GROUP BY TRIM(individual_value)
ORDER BY count DESC;  


-- How many incidents of each bias description were there?

WITH RECURSIVE SplitValues AS (
	SELECT
        incident_id,
        bias_desc || ';' AS remaining_string,
        '' AS bias,
        1 AS part_number
	FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1),
        part_number + 1
    FROM SplitValues
    WHERE INSTR(remaining_string, ';') > 0
)
SELECT
    TRIM(individual_value) AS bias,
    COUNT(*) AS count
FROM (
    SELECT
        TRIM(bias) AS individual_value
    FROM SplitValues
    WHERE TRIM(bias) <> ''
)
GROUP BY TRIM(individual_value)
ORDER BY count DESC;   

-- It is interesting that anti-Islamic crimes are so low despite 9/11 being a major trigger point for hate crimes.
-- Were there many anti-Islamic crimes before 9/11?
-- Anti-Black and anti-Jewish crimes are the most common. Is that true historically?
       

-- How many incidents by each victim type were there?

WITH RECURSIVE SplitValues AS (
	SELECT
        incident_id,
        victim_types || ';' AS remaining_string,
        '' AS victim,
        1 AS part_number
	FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1),
        part_number + 1
    FROM SplitValues
    WHERE INSTR(remaining_string, ';') > 0
)
SELECT
    TRIM(individual_value) AS victim,
    COUNT(*) AS count
FROM (
    SELECT
        TRIM(victim) AS individual_value
    FROM SplitValues
    WHERE TRIM(victim) <> ''
)
GROUP BY TRIM(individual_value)
ORDER BY count DESC;  


-- How many incidents by each location name were there?

WITH RECURSIVE SplitValues AS (
	SELECT
        incident_id,
        location_name || ';' AS remaining_string,
        '' AS location ,
        1 AS part_number
	FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1),
        part_number + 1
    FROM SplitValues
    WHERE INSTR(remaining_string, ';') > 0
)
SELECT
    TRIM(individual_value) AS location,
    COUNT(*) AS count
FROM (
    SELECT
        TRIM(location) AS individual_value
    FROM SplitValues
    WHERE TRIM(location) <> ''
)
GROUP BY TRIM(individual_value)
ORDER BY count DESC;  










-- What is the percentage of total incidents per offense name? By state, by year?

WITH total_incidents AS (
	SELECT COUNT(incident_id) AS incidents
	FROM hate_crime
	)
SELECT
	hc.offense_name,
	COUNT(hc.incident_id) AS offense_count,
	ROUND((COUNT(hc.incident_id) * 100.0 / ti.incidents), 2) AS pct_of_total
FROM hate_crime hc
CROSS JOIN total_incidents ti
GROUP BY hc.offense_name
ORDER BY pct_of_total DESC;


-- What is the percentage of total incidents per bias? By state, by year?

WITH total_incidents AS (
	SELECT COUNT(incident_id) AS incidents
	FROM hate_crime
	)
SELECT
	hc.bias_desc,
	COUNT(hc.incident_id) AS bias_count,
	ROUND((COUNT(hc.incident_id) * 100.0 / ti.incidents), 2) AS pct_of_total
FROM hate_crime hc
CROSS JOIN total_incidents ti
GROUP BY hc.bias_desc
ORDER BY pct_of_total DESC;











-- What is the frequency of incidents? Per state?
-- Define frequency: Howe often a value appears in the dataset.
-- This includes COUNT, with or without GROUP BY, percentage and proportion, and running total.
-- Note: Dates included in the dataset equal every possible date during this period. There were no days without incident.


-- Nationwide incidents per date average:

SELECT ROUND(AVG(incident_frequency), 0) AS avg_incidents_per_date
FROM
	(
	SELECT
		DATE(incident_date) AS day,
		COUNT(*) AS incident_frequency
	FROM hate_crime
	GROUP BY DATE(incident_date)
	ORDER BY day
) AS incidents_per_date;


-- Average incidents per day (from all days during the studied period) per state:

SELECT
	state_name,
	ROUND(CAST(SUM(incident_frequency) AS REAL) / (JULIANDAY('2023-12-31') - JULIANDAY('1991-01-01') + 1), 4) AS avg_incidents_per_day
FROM
	(
	SELECT
		state_name,
		DATE(incident_date) AS day,
		COUNT(*) AS incident_frequency
	FROM hate_crime
	GROUP BY
		state_name,
		DATE(incident_date)
	ORDER BY day
) AS incidents_per_date
GROUP BY state_name
ORDER BY avg_incidents_per_day DESC;

-- Ordering by average incidents per day shows 5 states with at least 1 incident every day, on average.





-- Are there any dates without incident?
-- Show the start date, end date, total days within the range, and total dates with an incident recorded.
-- The result shows every date within the range has an incident, therefore there were no days without incident.

SELECT
	MIN(incident_date) AS start_date,
	MAX(incident_date) AS end_date,
	CAST((JULIANDAY('2023-12-31') - JULIANDAY('1991-01-01')) AS INTEGER) + 1 AS total_dates,
	COUNT(DISTINCT incident_date) AS dates_w_incidents
FROM hate_crime;




-- What is the percentage of the total number of incident per state?

WITH total_incidents AS (
	SELECT COUNT(incident_id) AS incidents
	FROM hate_crime
	)
SELECT
	hc.state_name,
	COUNT(hc.incident_id) AS offense_count,
	ROUND((COUNT(hc.incident_id) * 100.0 / ti.incidents), 2) AS pct_of_total
FROM hate_crime hc
CROSS JOIN total_incidents ti
GROUP BY hc.state_name
ORDER BY pct_of_total DESC;


-- What percentage of a state's total incidents does each of its cities have?
-- The top 3 states are explored further:

-- Use California as an example.

WITH total_incidents AS (
	SELECT COUNT(incident_id) AS incidents
	FROM hate_crime
	WHERE state_name = 'California'
	)
SELECT
	hc.state_name,
	hc.pub_agency_name,
	COUNT(hc.incident_id) AS offense_count,
	ROUND((COUNT(hc.incident_id) * 100.0 / ti.incidents), 2) AS pct_of_total
FROM hate_crime hc
CROSS JOIN total_incidents ti
GROUP BY
	hc.state_name,
	hc.pub_agency_name
HAVING hc.state_name = 'California'
ORDER BY pct_of_total DESC;


-- Use New Jersey as an example.

WITH total_incidents AS (
	SELECT COUNT(incident_id) AS incidents
	FROM hate_crime
	WHERE state_name = 'New Jersey'
	)
SELECT
	hc.state_name,
	hc.pub_agency_name,
	COUNT(hc.incident_id) AS offense_count,
	ROUND((COUNT(hc.incident_id) * 100.0 / ti.incidents), 2) AS pct_of_total
FROM hate_crime hc
CROSS JOIN total_incidents ti
GROUP BY
	hc.state_name,
	hc.pub_agency_name
HAVING hc.state_name = 'New Jersey'
ORDER BY pct_of_total DESC;


-- Use New York as an example.

WITH total_incidents AS (
	SELECT COUNT(incident_id) AS incidents
	FROM hate_crime
	WHERE state_name = 'New York'
	)
SELECT
	hc.state_name,
	hc.pub_agency_name,
	COUNT(hc.incident_id) AS offense_count,
	ROUND((COUNT(hc.incident_id) * 100.0 / ti.incidents), 2) AS pct_of_total
FROM hate_crime hc
CROSS JOIN total_incidents ti
GROUP BY
	hc.state_name,
	hc.pub_agency_name
HAVING hc.state_name = 'New York'
ORDER BY pct_of_total DESC;









-- GEMINI SUGGESTIONS FOR ANALYSIS



-- Evolution of bias: How has the prevalence of different biases changed over the years?
	-- Best explored visually, but one query to check is:

-- What bias was most prevalent each year?


WITH RECURSIVE SplitValues AS (
    SELECT
        STRFTIME('%Y', incident_date) AS year,
        incident_id,
        bias_desc || ';' AS remaining_string,
        '' AS bias,
        1 AS part_number
    FROM hate_crime
    UNION ALL
    SELECT
        year,
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1),
        part_number + 1
    FROM SplitValues
    WHERE INSTR(remaining_string, ';') > 0
),
YearlyBiasCounts AS (
    SELECT
        year,
        TRIM(bias) AS individual_bias,
        COUNT(*) AS bias_count
    FROM SplitValues
    WHERE TRIM(bias) <> ''
    GROUP BY year, TRIM(bias)
),
RankedBiases AS (
    SELECT
        year,
        individual_bias,
        bias_count,
        RANK() OVER (PARTITION BY year ORDER BY bias_count DESC) AS rank_num
    FROM YearlyBiasCounts
)
SELECT
    year,
    individual_bias AS top_bias,
    bias_count AS top_bias_count
FROM RankedBiases
WHERE rank_num = 1
ORDER BY year DESC;

-- The fact that anti-Black crime was the most prevalent hate crime every year should not be a surprise.



-- Geographic variation in bias: Are certain biases more prevalent in specific states or regions?
	-- Best explored visually, but one query to check is:

-- What bias was most prevalent in each state?


WITH RECURSIVE SplitValues AS (
    SELECT
        state_name,
        incident_id,
        bias_desc || ';' AS remaining_string,
        '' AS bias,
        1 AS part_number
    FROM hate_crime
    UNION ALL
    SELECT
        state_name,
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1),
        part_number + 1
    FROM SplitValues
    WHERE INSTR(remaining_string, ';') > 0
),
StateBiasCounts AS (
    SELECT
        state_name,
        TRIM(bias) AS individual_bias,
        COUNT(*) AS bias_count
    FROM SplitValues
    WHERE TRIM(bias) <> ''
    GROUP BY state_name, TRIM(bias)
),
RankedBiases AS (
    SELECT
        state_name,
        individual_bias,
        bias_count,
        RANK() OVER (PARTITION BY state_name ORDER BY bias_count DESC) AS rank_num
    FROM StateBiasCounts
)
SELECT
    state_name,
    individual_bias AS top_bias,
    bias_count AS top_bias_count
FROM RankedBiases
WHERE rank_num = 1
ORDER BY state_name;




-- Types of offenses: How has the nature of offenses chaned over the years?
	-- Best explored visually, but one query to check is:

-- What offense was most prevalent per bias per year?


WITH RECURSIVE SplitBiases AS (
    SELECT
        STRFTIME('%Y', incident_date) AS year,
        incident_id,
        bias_desc || ';' AS remaining_bias,
        '' AS individual_bias,
        1 AS bias_part_number
    FROM hate_crime
    UNION ALL
    SELECT
        year,
        incident_id,
        SUBSTR(remaining_bias, INSTR(remaining_bias, ';') + 1),
        SUBSTR(remaining_bias, 1, INSTR(remaining_bias, ';') - 1),
        bias_part_number + 1
    FROM SplitBiases
    WHERE INSTR(remaining_bias, ';') > 0
),
SplitOffenses AS (
    SELECT
        STRFTIME('%Y', incident_date) AS year,
        incident_id,
        offense_name || ';' AS remaining_offense,
        '' AS individual_offense,
        1 AS offense_part_number
    FROM hate_crime
    UNION ALL
    SELECT
        year,
        incident_id,
        SUBSTR(remaining_offense, INSTR(remaining_offense, ';') + 1),
        SUBSTR(remaining_offense, 1, INSTR(remaining_offense, ';') - 1),
        offense_part_number + 1
    FROM SplitOffenses
    WHERE INSTR(remaining_offense, ';') > 0
),
YearlyOffenseBiasCounts AS (
    SELECT
        sb.year,
        so.individual_offense,
        sb.individual_bias,
        COUNT(sb.incident_id) AS combination_count
    FROM SplitBiases sb
    JOIN SplitOffenses so ON sb.incident_id = so.incident_id AND sb.year = so.year
    WHERE TRIM(sb.individual_bias) <> '' AND TRIM(so.individual_offense) <> ''
    GROUP BY sb.year, so.individual_offense, sb.individual_bias
),
RankedOffenseBiases AS (
    SELECT
        year,
        individual_offense,
        individual_bias,
        combination_count,
        RANK() OVER (PARTITION BY year ORDER BY combination_count DESC) AS rank_num
    FROM YearlyOffenseBiasCounts
)
SELECT
    year,
    individual_offense AS most_prevalent_offense,
    individual_bias AS corresponding_bias,
    combination_count AS offense_bias_count
FROM RankedOffenseBiases
WHERE rank_num = 1
ORDER BY year DESC;




-- Location of incidents: Where do hate crimes most frequently occur?
	-- While this is straightforward, a more probing query could be:

-- Incident count grouped by bias and by location type. Do certain biases show up more often in certain location types?


WITH RECURSIVE SplitBiases AS (
    SELECT
        STRFTIME('%Y', incident_date) AS year,
        incident_id,
        bias_desc || ';' AS remaining_bias,
        '' AS individual_bias,
        1 AS bias_part_number
    FROM hate_crime
    UNION ALL
    SELECT
        year,
        incident_id,
        SUBSTR(remaining_bias, INSTR(remaining_bias, ';') + 1),
        SUBSTR(remaining_bias, 1, INSTR(remaining_bias, ';') - 1),
        bias_part_number + 1
    FROM SplitBiases
    WHERE INSTR(remaining_bias, ';') > 0
),
SplitLocations AS (
    SELECT
        STRFTIME('%Y', incident_date) AS year,
        incident_id,
        location_name || ';' AS remaining_location,
        '' AS individual_location,
        1 AS location_part_number
    FROM hate_crime
    UNION ALL
    SELECT
        year,
        incident_id,
        SUBSTR(remaining_location, INSTR(remaining_location, ';') + 1),
        SUBSTR(remaining_location, 1, INSTR(remaining_location, ';') - 1),
        location_part_number + 1
    FROM SplitLocations
    WHERE INSTR(remaining_location, ';') > 0
),
YearlyBiasLocationCounts AS (
    SELECT
        sb.year,
        sl.individual_location,
        sb.individual_bias,
        COUNT(sb.incident_id) AS combination_count
    FROM SplitBiases sb
    JOIN SplitLocations sl ON sb.incident_id = sl.incident_id AND sb.year = sl.year
    WHERE TRIM(sb.individual_bias) <> '' AND TRIM(sl.individual_location) <> ''
    GROUP BY sb.year, sl.individual_location, sb.individual_bias
),
RankedBiasLocations AS (
    SELECT
        year,
        individual_location,
        individual_bias,
        combination_count,
        RANK() OVER (PARTITION BY year ORDER BY combination_count DESC) AS rank_num
    FROM YearlyBiasLocationCounts
)
SELECT
    year,
    individual_bias AS most_prevalent_bias,
    individual_location AS corresponding_location,
    combination_count AS bias_location_count
FROM RankedBiasLocations
WHERE rank_num = 1
ORDER BY year DESC;





-- Is there a correlation between offense and victim type?

WITH RECURSIVE OffenseSplit AS (
    SELECT
        incident_id,
        offense_name || ';' AS remaining_string,
        '' AS individual_offense,
        1 AS part_number
    FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        TRIM(SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1)),
        part_number + 1
    FROM OffenseSplit
    WHERE INSTR(remaining_string, ';') > 0
),
VictimSplit AS (
    SELECT
        incident_id,
        victim_types || ';' AS remaining_string,
        '' AS individual_victim,
        1 AS part_number
    FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        TRIM(SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1)),
        part_number + 1
    FROM VictimSplit
    WHERE INSTR(remaining_string, ';') > 0
)
SELECT
    TRIM(os.individual_offense) AS offense,
    TRIM(vs.individual_victim) AS victim_type,
    COUNT(DISTINCT os.incident_id) AS incident_count
FROM OffenseSplit os
JOIN VictimSplit vs
    ON os.incident_id = vs.incident_id
WHERE
    TRIM(os.individual_offense) <> ''
    AND TRIM(vs.individual_victim) <> ''
GROUP BY
    TRIM(os.individual_offense),
    TRIM(vs.individual_victim)
ORDER BY
    incident_count DESC,
    offense,
    victim_type;





-- Is there a correlation between bias and victim type?

WITH RECURSIVE BiasSplit AS (
    SELECT
        incident_id,
        bias_desc || ';' AS remaining_string,
        '' AS individual_bias,
        1 AS part_number
    FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        TRIM(SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1)),
        part_number + 1
    FROM BiasSplit
    WHERE INSTR(remaining_string, ';') > 0
),
VictimSplit AS (
    SELECT
        incident_id,
        victim_types || ';' AS remaining_string,
        '' AS individual_victim,
        1 AS part_number
    FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        TRIM(SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1)),
        part_number + 1
    FROM VictimSplit
    WHERE INSTR(remaining_string, ';') > 0
)
SELECT
    TRIM(bs.individual_bias) AS bias_description,
    TRIM(vs.individual_victim) AS victim_type,
    COUNT(DISTINCT bs.incident_id) AS incident_count
FROM BiasSplit bs
JOIN VictimSplit vs
    ON bs.incident_id = vs.incident_id
WHERE
    TRIM(bs.individual_bias) <> ''
    AND TRIM(vs.individual_victim) <> ''
GROUP BY
    TRIM(bs.individual_bias),
    TRIM(vs.individual_victim)
ORDER BY
    incident_count DESC,
    bias_description,
    victim_type;





-- Is there a correlation between offender race and bias?

WITH RECURSIVE BiasSplit AS (
    SELECT
        incident_id,
        bias_desc || ';' AS remaining_string,
        '' AS individual_bias,
        1 AS part_number
    FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        TRIM(SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1)),
        part_number + 1
    FROM BiasSplit
    WHERE INSTR(remaining_string, ';') > 0
),
OffenderRaceSplit AS (
    SELECT
        incident_id,
        offender_race || ';' AS remaining_string,
        '' AS individual_offender_race,
        1 AS part_number
    FROM hate_crime
    UNION ALL
    SELECT
        incident_id,
        SUBSTR(remaining_string, INSTR(remaining_string, ';') + 1),
        TRIM(SUBSTR(remaining_string, 1, INSTR(remaining_string, ';') - 1)),
        part_number + 1
    FROM OffenderRaceSplit
    WHERE INSTR(remaining_string, ';') > 0
)
SELECT
    TRIM(bs.individual_bias) AS bias_description,
    TRIM(ors.individual_offender_race) AS offender_race,
    COUNT(DISTINCT bs.incident_id) AS incident_count
FROM BiasSplit bs
JOIN OffenderRaceSplit ors
    ON bs.incident_id = ors.incident_id
WHERE
    TRIM(bs.individual_bias) <> ''
    AND TRIM(ors.individual_offender_race) <> ''
GROUP BY
    TRIM(bs.individual_bias),
    TRIM(ors.individual_offender_race)
ORDER BY
    incident_count DESC,
    bias_description,
    offender_race;

