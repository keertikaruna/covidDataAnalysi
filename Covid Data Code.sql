-- CHANGES IN DATA BASE TO GET CORRECT DATA TYPES

UPDATE coviddeaths
SET continent = NULL
WHERE continent = ' ';

UPDATE covidvaccination
SET continent = NULL
WHERE continent = ' ';

UPDATE coviddeaths
SET date =  (SELECT STR_TO_DATE(date, "%Y-%m-%d"));

UPDATE covidvaccination
SET date =  (SELECT STR_TO_DATE(date, "%Y-%m-%d"));

UPDATE coviddeaths
SET total_deaths = NULL
WHERE total_deaths = ' ';

UPDATE coviddeaths
SET new_cases = NULL
WHERE new_cases = 0;

UPDATE coviddeaths
SET new_cases = -1*new_cases
WHERE new_cases < 0;

UPDATE coviddeaths
SET new_deaths = NULL
WHERE new_deaths = '';

UPDATE covidvaccination
SET new_vaccination = NULL
WHERE new_vaccination = ' ';



-- -----------------------------------------------------------------------------------------------------------------------------------------------------------

Select *
From coviddeaths
Where continent IS NOT NULL 
order by 3,4;


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
-- Where location like '%states%'
-- and continent is not null 
order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
-- Where location like '%states%'
order by 1,2;


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max(CAST((total_cases/population)*100 as DECIMAL(9,7))) as PercentPopulationInfected
From CovidDeaths
-- Where location like '%states%'
Where continent is not null
Group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population

Select Location, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths
-- Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc;



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, SUM(DISTINCT total_deaths) AS SumDeathCount
From CovidDeaths
-- Where location like '%states%'
Where continent is not null AND total_deaths IN (SELECT MAX(total_deaths) FROM coviddeaths WHERE continent IS NOT NULL GROUP BY location) 
Group by continent
order by SumDeathCount desc;


-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
-- Where location like '%states%'
where continent is not null 
-- Group By date
order by 1,2;



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths AS dea
Join CovidVaccination AS vac On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
order by 2,3;


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths AS dea
Join CovidVaccination AS vac On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
-- order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as Percentage_PeopleVaccinated
From PopvsVac;






-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths AS dea
Join CovidVaccination AS vac On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
-- order by 2,3;
