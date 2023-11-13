/* 
Queries used for Tableau Visualisations
*/

-- 1. Showing global cases and death rate if you were to contract COVID

CREATE VIEW GlobalDeathPercent AS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
From CovidProject..CovidDeaths
where continent is not null 
--order by 1,2

-- 2. Showing correlation between infections, deaths and vaccinations

CREATE VIEW VaccineEffect AS
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
--ORDER BY dea.date

-- 3. Showing continental cases and deaths per year

CREATE VIEW ContinentCases AS
SELECT location, 
	population,
	SUM(CASE WHEN YEAR(date) = 2020 THEN new_cases END) AS '2020_total_cases',
	SUM(CASE WHEN YEAR(date) = 2020 THEN new_deaths END) AS '2020_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2021 THEN new_cases END) AS '2021_total_cases',
	SUM(CASE WHEN YEAR(date) = 2021 THEN new_deaths END) AS '2021_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2022 THEN new_cases END) AS '2022_total_cases',
	SUM(CASE WHEN YEAR(date) = 2022 THEN new_deaths END) AS '2022_total_deaths',
	SUM(CASE WHEN YEAR(date) = 2023 THEN new_cases END) AS '2023_total_cases',
	SUM(CASE WHEN YEAR(date) = 2023 THEN new_deaths END) AS '2023_total_deaths',
	MAX(total_cases) AS total_cases,
	MAX(total_deaths) AS total_deaths
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('World', 'European Union')
	AND location NOT LIKE '%income'
GROUP BY location, population

-- 4. Showing percentage of population infected for global map

CREATE VIEW GlobalInfection AS
SELECT location, 
	population, 
	date, 
	MAX(total_cases) AS HighestInfectionCount,  
	MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
GROUP BY location, population, date
--ORDER BY PercentPopulationInfected DESC
