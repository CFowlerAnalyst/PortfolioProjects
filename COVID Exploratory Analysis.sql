/*
COVID-19 Exploratory Data Analysis
*/

-- Check to make sure data had been imported correctly

SELECT * 
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

SELECT * 
FROM CovidProject..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY location, date


-- Looking at dataset I will be working with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


-- Correcting data types of the columns in the covid deaths table

ALTER TABLE CovidProject..CovidDeaths ALTER COLUMN total_deaths float NULL
ALTER TABLE CovidProject..CovidDeaths ALTER COLUMN total_cases float NULL
ALTER TABLE CovidProject..CovidDeaths ALTER COLUMN new_cases float NULL


-- Analysing total cases vs total deaths with a percentage to show likelihood of dying if you contract COVID for the UK

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE location = 'United Kingdom'
AND continent IS NOT NULL
ORDER BY location, date


-- Looking at total cases vs population with a percentage of population infected for the UK

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentagePopulationInfected
FROM CovidProject..CovidDeaths
WHERE location = 'United Kingdom'
AND continent IS NOT NULL
ORDER BY location, date


-- Countries that have the highest infection rates compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentagePopulationInfected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC


-- Looking at Countries with the highest death count

SELECT location, MAX(total_deaths) AS TotalDeathCount, MAX(total_deaths/population)*100 AS PercentagePopulationDied
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Looking at continents with the highest death count

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NULL 
AND location NOT LIKE '%income'
AND location NOT LIKE '%Union%'
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Looking at global numbers

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL


-- Looking at Global numbers per day

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, TotalCases


-- Looking at the total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location
, dea.date) AS RollingVaccinationCount
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY location, date


-- Using CTE to perform calculations using 'RollingVaccinationCount' from above partition by

WITH PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingVaccinationCount) AS
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location
	, dea.date) AS RollingVaccinationCount
	FROM CovidProject..CovidDeaths dea
	JOIN CovidProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	)

SELECT *, (RollingVaccinationCount/Population)*100 AS PercentageVaccinated
FROM PopvsVac


-- Using Temp Table for the same purpose

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating a view to store data to visualise later

CREATE VIEW PercentPopVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingVaccinationCount
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


-- Showing infection, death, and vaccine count

SELECT dea.location,
	dea.population,
	dea.date,
	MAX(dea.total_cases) AS HighestInfectionCount,
	MAX(dea.total_deaths) AS HighestDeathCount,
	MAX(vac.people_fully_vaccinated) AS FullVaccineCount
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.location = 'United Kingdom'
GROUP BY dea.location, dea.population, dea.date
ORDER BY dea.date


-- Yearly cases per country 

SELECT continent, location,
	SUM(CASE WHEN YEAR(date) = 2020 THEN new_cases END) AS '2020_total_cases',
	SUM(CASE WHEN YEAR(date) = 2021 THEN new_cases END) AS '2021_total_cases',
	SUM(CASE WHEN YEAR(date) = 2022 THEN new_cases END) AS '2022_total_cases',
	SUM(CASE WHEN YEAR(date) = 2023 THEN new_cases END) AS '2023_total_cases',
	MAX(total_cases) AS total_cases
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY 1,2


-- Yearly Deaths per country

SELECT continent, location,
	SUM(CASE WHEN YEAR(date) = 2020 THEN new_deaths END) AS '2020_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2021 THEN new_deaths END) AS '2021_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2022 THEN new_deaths END) AS '2022_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2023 THEN new_deaths END) AS '2023_total_deaths',
	MAX(total_deaths) AS total_deaths
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY 1,2


-- Yearly cases per continent

SELECT location, 
	SUM(CASE WHEN YEAR(date) = 2020 THEN new_cases END) AS '2020_total_cases',
	SUM(CASE WHEN YEAR(date) = 2021 THEN new_cases END) AS '2021_total_cases',
	SUM(CASE WHEN YEAR(date) = 2022 THEN new_cases END) AS '2022_total_cases',
	SUM(CASE WHEN YEAR(date) = 2023 THEN new_cases END) AS '2023_total_cases',
	MAX(total_cases) AS total_cases
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('World', 'European Union')
	AND location NOT LIKE '%income'
GROUP BY location
ORDER BY 1


-- Yearly Deaths per continent

SELECT location, 
	SUM(CASE WHEN YEAR(date) = 2020 THEN new_deaths END) AS '2020_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2021 THEN new_deaths END) AS '2021_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2022 THEN new_deaths END) AS '2022_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2023 THEN new_deaths END) AS '2023_total_deaths',
	MAX(total_deaths) AS total_deaths
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('World', 'European Union')
	AND location NOT LIKE '%income'
GROUP BY location
ORDER BY 1


-- Creating temp table for yearly continent cases 

DROP TABLE IF EXISTS #YearlyContinentCases
CREATE TABLE #YearlyContinentCases 
(
location nvarchar(255),
population numeric,
cases_2020 numeric,
cases_2021 numeric,
cases_2022 numeric,
cases_2023 numeric,
total_cases numeric
)

INSERT INTO #YearlyContinentCases
SELECT location,
	population,
	SUM(CASE WHEN YEAR(date) = 2020 THEN new_cases END) AS '2020_total_cases',
	SUM(CASE WHEN YEAR(date) = 2021 THEN new_cases END) AS '2021_total_cases',
	SUM(CASE WHEN YEAR(date) = 2022 THEN new_cases END) AS '2022_total_cases',
	SUM(CASE WHEN YEAR(date) = 2023 THEN new_cases END) AS '2023_total_cases',
	MAX(total_cases) AS total_cases
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('World', 'European Union')
	AND location NOT LIKE '%income'
GROUP BY location, population


-- Creating Temp table for yearly continent deaths

DROP TABLE IF EXISTS #YearlyContinentDeaths
CREATE TABLE #YearlyContinentDeaths 
(
location nvarchar(255),
population numeric,
deaths_2020 numeric,
deaths_2021 numeric,
deaths_2022 numeric,
deaths_2023 numeric,
total_deaths numeric
)

INSERT INTO #YearlyContinentDeaths
SELECT location, 
	population,
	SUM(CASE WHEN YEAR(date) = 2020 THEN new_deaths END) AS '2020_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2021 THEN new_deaths END) AS '2021_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2022 THEN new_deaths END) AS '2022_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2023 THEN new_deaths END) AS '2023_total_deaths',
	MAX(total_deaths) AS total_deaths
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('World', 'European Union')
	AND location NOT LIKE '%income'
GROUP BY location, population


-- Joining tables for yearly continent cases and deaths

SELECT cas.location,
	cases_2020,
	deaths_2020,
	cases_2021,
	deaths_2021,
	cases_2022,
	deaths_2022,
	cases_2023,
	deaths_2023
FROM #YearlyContinentCases cas
JOIN #YearlyContinentDeaths dea
	ON cas.location = dea.location
	AND cas.population = dea.population
ORDER BY cas.location