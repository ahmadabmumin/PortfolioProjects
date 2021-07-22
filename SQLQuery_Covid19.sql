SELECT location, date, total_cases, new_cases, total_deaths, populatioFROM COVID19..covid_deaths
ORDER BY 1,2

-- Looking at Total Case vs Total Deaths in Malaysia
--Showing the likelihood of a Death in Covid cases

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100 AS DeathPercentage
FROM COVID19..covid_deaths
WHERE location like 'Malaysia'
ORDER BY 1,2

-- Looking at Total Case vs Population in Malaysia
-- Showing the Percentage of Population Infected by Covid

SELECT location, date, Population, total_cases, (total_cases/Population)*100 AS InfectionPercentage
FROM covid19..covid_deaths
WHERE location like 'Malaysia'
ORDER BY 1,2

-- Loking at Countries with Highest Infection Percentage compared to Population

SELECT location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population)*100) AS HighestInfectionPRecentage
FROM covid19..covid_deaths
GROUP BY location, Population
ORDER BY 4 DESC

-- Total Death Count by Continent

SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM covid19..covid_deaths
WHERE continent is null
GROUP BY location
ORDER BY 2 DESC


-- Global Numbers

SELECT date, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths AS int)) as TotalDeaths
FROM covid19..covid_deaths
WHERE location like 'World'
GROUP BY date
ORDER BY 1

SELECT *
FROM covid19..covid_vax



SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CAST(vax.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaxCount
FROM covid19..covid_deaths dea 
JOIN covid19..covid_vax vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null AND dea.location like 'Malaysia'
ORDER BY 2,3




-- Use Common Table Expression (CTE)

WITH PopVsVax (continent, location, date, Population, new_vaccincations, CumulativeVaxCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CAST(vax.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaxCount
FROM covid19..covid_deaths dea 
JOIN covid19..covid_vax vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null AND dea.location like 'Malaysia'
)
SELECT *, (CumulativeVaxCount/Population)*100 AS VaxPercentage
FROM PopVsVax
ORDER BY 2,3




-- Use Temp Table
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
CumulativeVaxCount numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CAST(vax.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaxCount
FROM covid19..covid_deaths dea 
JOIN covid19..covid_vax vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null 

SELECT *, (CumulativeVaxCount/population)*100 AS VaxPercentage
FROM #PercentPopulationVaccinated


CREATE VIEW PercentPopulatedVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CAST(vax.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaxCount
FROM covid19..covid_deaths dea 
JOIN covid19..covid_vax vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null 