/* Aggregation */
/* Query 1 */
/* Country with the highest debt */

/* Country with the highest debt without sampling*/
SELECT 
    Country, SUM(DebtAmount) AS Debt
FROM WORLDDEBT
GROUP BY Country
ORDER BY Debt DESC
LIMIT 1;

/* Country with the highest debt with simple random sampling */
SELECT 
    Country, SUM(DebtAmount) AS Debt
FROM (
    SELECT 
        Country, DebtAmount
    FROM 
        WORLDDEBT
    ORDER BY RANDOM() 
    LIMIT 39290 
) AS SampledData
GROUP BY 
    Country
ORDER BY 
    Debt DESC
LIMIT 1;

/* Country with the highest debt with Stratified Sampling */
WITH RankedCountries AS (
    SELECT 
        CountryName,
        Continent,
        SUM(DebtAmount) AS TotalDebt,
        ROW_NUMBER() OVER(PARTITION BY Continent ORDER BY SUM(DebtAmount) DESC) AS RowNum
    FROM WORLDDEBT
    GROUP BY CountryName, Continent
)
SELECT 
    CountryName,
    TotalDebt AS Debt,
    Continent
FROM RankedCountries
WHERE RowNum = 1;

/* Country with the highest debt with Systematic Sampling */
WITH RankedDebts AS (
    SELECT 
        Country,
        SUM(DebtAmount) AS Debt,
        ROW_NUMBER() OVER (ORDER BY SUM(DebtAmount) DESC) AS RowNum
    FROM WORLDDEBT
    GROUP BY Country
)

SELECT 
    Country,
    Debt
FROM RankedDebts
WHERE RowNum % 393 = 0; 

/* Query 2 */
/* Average amount of debt across indicators without sampling*/
SELECT 
    IndicatorCode,
    IndicatorName,
    AVG(DebtAmount) AS AverageDebt
FROM WORLDDEBT
GROUP BY IndicatorCode, IndicatorName
ORDER BY AverageDebt DESC
LIMIT 10;

/* Average amount of debt across indicators with Simple Random Sampling */
SELECT 
    IndicatorCode,
    IndicatorName,
    AVG(DebtAmount) AS AverageDebt
FROM WORLDDEBT
GROUP BY IndicatorCode, IndicatorName
ORDER BY RANDOM()
LIMIT 10;

/* Average amount of debt across indicators with Stratified Sampling */
WITH StratifiedSample AS (
    SELECT 
        CountryName,
        DebtAmount,
        Continent,
        AVG(DebtAmount) OVER(PARTITION BY Continent) AS AverageDebt,
        ROW_NUMBER() OVER(PARTITION BY Continent ORDER BY RANDOM()) AS RowNum
    FROM CONTINENTDEBT
)

SELECT 
    CountryName,
    DebtAmount,
    Continent,
    AverageDebt
FROM StratifiedSample
WHERE RowNum = 1;

/* Average amount of debt across indicators with Systematic Sampling */
WITH SampledData AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY IndicatorCode, IndicatorName) AS RowNum
    FROM WORLDDEBT
)

SELECT 
    IndicatorCode,
    IndicatorName,
    AVG(DebtAmount) AS AverageDebt
FROM SampledData
WHERE MOD(RowNum - 1, 393) = 0
GROUP BY IndicatorCode, IndicatorName
ORDER BY IndicatorCode, IndicatorName;

/* Query 3 */
/* The most common debt indicator */
/* The most common debt indicator without sampling */
SELECT 
    IndicatorName, 
    COUNT(*) AS IndicatorCount
FROM 
    WORLDDEBT
GROUP BY 
    IndicatorName
ORDER BY 
    IndicatorCount DESC
LIMIT 1;

/* The most common debt indicator with Simple Random Sampling */
SELECT 
    IndicatorName, 
    COUNT(*) AS IndicatorCount
FROM 
    WORLDDEBT
GROUP BY 
    IndicatorName
ORDER BY 
    RANDOM()
LIMIT 1;

/* The most common debt indicator with Stratified Sampling */
WITH IndicatorCounts AS (
    SELECT 
        IndicatorName,
        Continent,
        COUNT(*) AS IndicatorCount
    FROM CONTINENTDEBT
    GROUP BY IndicatorName, Continent
)

SELECT 
    IndicatorName,
    Continent,
    IndicatorCount
FROM (
    SELECT 
        IndicatorName,
        Continent,
        IndicatorCount,
        ROW_NUMBER() OVER(PARTITION BY Continent ORDER BY IndicatorCount DESC) AS RowNum
    FROM IndicatorCounts
)
WHERE RowNum = 1;

/* The most common debt indicator with Systematic Sampling */
WITH SampledData AS (
    SELECT 
        IndicatorName, 
        COUNT(*) AS IndicatorCount,
        ROW_NUMBER() OVER (ORDER BY IndicatorName) AS RowNum
    FROM WORLDDEBT
    GROUP BY IndicatorName
)

SELECT 
    IndicatorName, 
    IndicatorCount
FROM SampledData
WHERE MOD(RowNum - 1, 393) = 0; 


/* Joins */
/* Query 1*/
/* Which currency unit has the highest debt? */

/* Currency with the highest debt without sampling without sampling */
SELECT CD.CURRENCYUNIT, SUM(WD.DEBTAMOUNT) AS TotalDebt
FROM CURRENCYDATA CD
JOIN WORLDDEBT WD ON CD.COUNTRYCODE = WD.COUNTRYCODE
GROUP BY CD.CURRENCYUNIT
ORDER BY TotalDebt DESC
LIMIT 1;

/* Currency with the highest debt with Simple Random Sampling */
SELECT CD.CURRENCYUNIT, SUM(WD.DEBTAMOUNT) AS TotalDebt
FROM CURRENCYDATA CD
JOIN (SELECT * FROM WORLDDEBT TABLESAMPLE SYSTEM (10)) WD 
ON CD.COUNTRYCODE = WD.COUNTRYCODE
GROUP BY CD.CURRENCYUNIT
ORDER BY TotalDebt DESC
LIMIT 1;

/* Currency with the highest debt with Stratified Sampling */
WITH HighestDebtCountryCodes AS (
  SELECT CD.COUNTRYCODE
  FROM CURRENCYDATA CD
  JOIN WORLDDEBT WD ON CD.COUNTRYCODE = WD.COUNTRYCODE
  GROUP BY CD.COUNTRYCODE
  ORDER BY SUM(WD.DEBTAMOUNT) DESC
  LIMIT 1
),
StratifiedSample AS (
  SELECT CD.COUNTRYCODE, CD.COUNTRYNAME, CD.INDICATORCODE, CD.INDICATORNAME, CD.DEBTAMOUNT, CD.CONTINENT,
         ROW_NUMBER() OVER (PARTITION BY CD.CONTINENT ORDER BY RANDOM()) AS row_num
  FROM CONTINENTDEBT CD
  JOIN HighestDebtCountryCodes HDC ON CD.COUNTRYCODE = HDC.COUNTRYCODE
)
SELECT *
FROM StratifiedSample
WHERE row_num <= 10; 

Query time on Computer 1: 467ms
Query time on Computer 2: 401 ms


/* Currency with the highest debt with Systematic Sampling */
WITH systematic_sample AS (
  SELECT 
    CD.CURRENCYUNIT, 
    SUM(WD.DEBTAMOUNT) AS TotalDebt,
    NTILE(10) OVER (ORDER BY CD.CURRENCYUNIT) AS tile
  FROM 
    CURRENCYDATA CD
  JOIN 
   WORLDDEBT WD ON CD.COUNTRYCODE = WD.COUNTRYCODE
  GROUP BY 
    CD.CURRENCYUNIT
)
SELECT *
FROM systematic_sample
WHERE tile = 1; 

/* When has the most data been collected */
When has the most data been collected without Sampling
WITH JoinedData AS (
    SELECT WD.COUNTRYCODE, CD.LATESTTRADEDATA
    FROM WORLDDEBT WD
    JOIN CENSUSDATA CD ON WD.COUNTRYCODE = CD.COUNTRYCODE
)
SELECT LATESTTRADEDATA, COUNT(*) AS Frequency
FROM JoinedData
GROUP BY LATESTTRADEDATA
ORDER BY Frequency DESC
LIMIT 1;

/* When has the most data been collected with Simple Random Sampling */
WITH SampledWorldDebt AS (
    SELECT *
    FROM WORLDDEBT
    SAMPLE (10) 
),
SampledCensusData AS (
    SELECT *
    FROM CENSUSDATA
    SAMPLE (10) 
),
JoinedData AS (
    SELECT WD.COUNTRYCODE, CD.LATESTTRADEDATA
    FROM SampledWorldDebt WD
    JOIN SampledCensusData CD ON WD.COUNTRYCODE = CD.COUNTRYCODE
)
SELECT LATESTTRADEDATA, COUNT(*) AS Frequency
FROM JoinedData
GROUP BY LATESTTRADEDATA
ORDER BY Frequency DESC
LIMIT 1;


/* When has the most data been collected with Stratified Sampling */
WITH JoinedData AS (
    SELECT WD.COUNTRYCODE, CD.LATESTTRADEDATA, CD.COUNTRYCODE AS ContinentCode
    FROM WORLDDEBT WD
    JOIN CENSUSDATA CD ON WD.COUNTRYCODE = CD.COUNTRYCODE
),
StratifiedSample AS (
    SELECT JD.*, CD.CURRENCYUNIT,
           ROW_NUMBER() OVER(PARTITION BY JD.ContinentCode ORDER BY RANDOM()) AS RowNum
    FROM JoinedData JD
    JOIN CURRENCYDATA CD ON JD.ContinentCode = CD.COUNTRYCODE
)
SELECT CURRENCYUNIT, LATESTTRADEDATA, COUNT(*) AS Frequency
FROM StratifiedSample
WHERE RowNum <= 10 
GROUP BY CURRENCYUNIT, LATESTTRADEDATA
QUALIFY ROW_NUMBER() OVER(PARTITION BY CURRENCYUNIT ORDER BY COUNT(*) DESC) = 1;

/* When has the most  data been collected with Systematic Sampling */
WITH RankedData AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY WD.COUNTRYCODE ORDER BY WD.COUNTRYCODE) AS RowNum
    FROM WORLDDEBT WD
    JOIN CENSUSDATA CD ON WD.COUNTRYCODE = CD.COUNTRYCODE
)
SELECT LATESTTRADEDATA, COUNT(*) AS Frequency
FROM RankedData
WHERE MOD(RowNum, 10) = 0 
GROUP BY LATESTTRADEDATA
ORDER BY Frequency DESC
LIMIT 1;

/* Find the Countries that use the Euro */

/* Find the Countries that use the Euro without sampling */
WITH EuroCountries AS (
    SELECT CD.COUNTRYCODE
    FROM CURRENCYDATA CD
    JOIN CURRENCYDATA CD2 ON CD.COUNTRYCODE = CD2.COUNTRYCODE
    WHERE CD.CURRENCYUNIT = 'Euro'
)
SELECT DISTINCT EC.COUNTRYCODE
FROM EuroCountries EC;

/* Find the Countries that use the Euro with Simple Random Sampling */
WITH EuroSubset AS (
    SELECT COUNTRYCODE
    FROM CURRENCYDATA
    WHERE CURRENCYUNIT = 'Euro'
)
SELECT DISTINCT EC.COUNTRYCODE
FROM (
    SELECT COUNTRYCODE
    FROM EuroSubset
    SAMPLE (10) 
) EC
JOIN CURRENCYDATA EC2 ON EC.COUNTRYCODE = EC2.COUNTRYCODE;

/* Find the Countries that use the Euro with Stratified Sampling */

CREATE TABLE EuroCountriesByContinent AS
SELECT CN.COUNTRYCODE, CN.CONTINENT
FROM CURRENCYDATA CD
JOIN CONTINENTDEBT CN ON CN.COUNTRYCODE = CN.COUNTRYCODE
WHERE CD.CURRENCYUNIT = 'Euro';

CREATE TABLE StratifiedSample AS
SELECT DISTINCT EC.COUNTRYCODE, EC.CONTINENT
FROM EuroCountriesByContinent EC
JOIN (
    SELECT EC2.CONTINENT, EC2.COUNTRYCODE,
           ROW_NUMBER() OVER (PARTITION BY EC2.CONTINENT ORDER BY RANDOM()) AS RowNum
    FROM EuroCountriesByContinent EC2
) AS GroupedEuroCountries
ON EC.CONTINENT = GroupedEuroCountries.CONTINENT
WHERE GroupedEuroCountries.RowNum <= 10;

SELECT * FROM StratifiedSample;

/* Find the Countries that use the Euro with Systematic Sampling */
WITH IndexedEuroCountries AS (
    SELECT COUNTRYCODE, ROW_NUMBER() OVER (ORDER BY COUNTRYCODE) AS RowNum
    FROM CURRENCYDATA
    WHERE CURRENCYUNIT = 'Euro'
)
SELECT DISTINCT EC.COUNTRYCODE
FROM IndexedEuroCountries EC
JOIN IndexedEuroCountries EC2 ON EC.RowNum = EC2.RowNum * 10  
