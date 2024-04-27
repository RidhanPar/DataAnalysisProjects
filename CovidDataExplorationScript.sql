/*
Covid Data Exploration Project

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
from PortfolioProject.dbo.CovidDeaths
where continent is not null
order by 3,4


--Selecting data to work with
Select location,date,total_cases,new_cases,total_deaths,population
from PortfolioProject.dbo.CovidDeaths
where continent is not null
order by 1,2

--Data type Conversion
ALTER TABLE dbo.CovidDeaths
ALTER COLUMN total_deaths int;
ALTER TABLE dbo.CovidDeaths
ALTER COLUMN total_cases int;

--Comparing Total Cases vs Total Deaths
-- Shows likehood of dying if getting covid in a mentioned country
Select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
where location like '%latvia%'
order by 1,2

--Comparing Total Cases vs Population
--Shows Percentage of Polulation got Covid
Select location,date,population,total_cases,(total_cases/population)*100 as InfectedPercentage
from PortfolioProject.dbo.CovidDeaths
where location like '%latvia%'
and continent is not null
order by 1,2

-- Querying Countries with Highest Inection Rate compared to Population

Select location,population,Max(total_cases) as HighestInfectionCount,Max((total_cases/population)*100) as InfectedPercentage
from PortfolioProject.dbo.CovidDeaths
group by location,population
order by InfectedPercentage desc


--Querying the Countries with Highest death count per Polulation

Select location,Max(total_deaths) as HigestDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by location
order by HigestDeathCount desc

-- BREAKING DOWN BY CONTINENT

-- Querying the Continents with Highest death count per Polulation
Select continent,Max(total_deaths) as HigestDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by continent
order by HigestDeathCount desc

-- GLOBAL NUMBERS
-- Querying the death percentage across the world
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

-- Comparing Total Population vs Vaccinaitons
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100 as VaccinatedPercentage
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select*
from PercentPopulationVaccinated
