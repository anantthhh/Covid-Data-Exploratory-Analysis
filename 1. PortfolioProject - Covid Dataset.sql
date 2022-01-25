show databases;

CREATE SCHEMA PortfolioProject;
USE PortfolioProject;

CREATE TABLE covid_deaths
 (
ISO_CODE varchar(10),
CONTINENT varchar(30),
LOCATION varchar(40),
Date_	 date,
POPULATION int,
TOTAL_CASES int,
new_cases int,
new_cases_smoothed decimal(10,4),
total_deaths int,
new_deaths int,
new_deaths_smoothed decimal(10,4),
total_cases_per_million decimal(10,4),
new_cases_per_million decimal(10,4),
new_cases_smoothed_per_million decimal(10,4),
total_deaths_per_million decimal(10,4),
new_deaths_per_million decimal(10,4),
new_deaths_smoothed_per_million decimal(10,4),
reproduction_rate decimal(5,3),
icu_patients int,
icu_patients_per_million decimal (7,3),
hosp_patients int,
hosp_patients_per_million decimal(10,4),
weekly_icu_admissions int,
weekly_icu_admissions_per_million decimal(8,3),
weekly_hosp_admissions int,
weekly_hosp_admissions_per_million decimal(8,3)
);


CREATE TABLE covid_vaccines
(
ISO_CODE varchar(10),
CONTINENT varchar(30),
LOCATION varchar(40),
Date_	 date,
new_tests int,
total_tests int,
total_tests_per_thousand decimal(10,3),
new_tests_per_thousand decimal(7.3),
new_tests_smoothed int,
new_tests_smoothed_per_thousand decimal(7,3),
positive_rate decimal(7,5),
tests_per_case decimal(8,3),
tests_units varchar(30),
total_vaccinations int,
people_vaccinated int,
people_fully_vaccinated int,
total_boosters int,
new_vaccinations int,
new_vaccinations_smoothed int,
total_vaccinations_per_hundred decimal(6,3),
people_vaccinated_per_hundred decimal(6,3),
people_fully_vaccinated_per_hundred decimal(6,3),
total_boosters_per_hundred decimal(5,3),
new_vaccinations_smoothed_per_million int,
new_people_vaccinated_smoothed int,
new_people_vaccinated_smoothed_per_hundred decimal(6,3),
stringency_index decimal(7,3),
population_density decimal(10,4),
median_age decimal(5,3),
aged_65_older decimal(6,3),
aged_70_older decimal(6,3),
gdp_per_capita decimal(11,3),
extreme_poverty decimal(5,3),
cardiovasc_death_rate decimal(7,3),
diabetes_prevalence decimal(5,3),
female_smokers decimal(5,3),
male_smokers decimal(5,3),
handwashing_facilities decimal(6,3),
hospital_beds_per_thousand decimal(5,3),
life_expectancy decimal(5,3),
human_development_index decimal(4,3),
excess_mortality_cumulative_absolute decimal(11,3),
excess_mortality_cumulative decimal(6,3),
excess_mortality decimal(6,3),
excess_mortality_cumulative_per_million decimal (8,4)
); 

SELECT * FROM covid_deaths

order by 3,4;

SELECT * FROM covid_vaccines
WHERE continent is not null
order by 3,4;


-- SELECTING THE DATA WE WILL BE USING
SELECT location, date_, total_cases, new_cases, total_deaths, population
FROM covid_deaths
order by 1,2;


-- TOTAL CASES VS TOTAL DEATHS
SELECT location, date_, total_cases, total_deaths, ((total_deaths/total_cases)*100)	
FROM covid_deaths
order by 1,2;



-- TOTAL CASES VS TOTAL DEATHS IN INDIA
-- SHOWS LIKELIHOOD OF DYING IN INDIA IF YOU CONTRACT THE VIRUS
SELECT location, date_, total_cases, total_deaths, ((total_deaths/total_cases)*100)	AS Death_Percentage
FROM covid_deaths
WHERE location = 'India'
order by 1,2;



-- LOOKING AT TOTAL CASES VS POPULATION IN INDIA
-- SHOWS WHAT PERCENTAGE OF THE POPULATION HAS CONTRACTED THE VIRUS IN INDIA
SELECT location, date_, total_cases, population, ((total_cases/population)*100) AS Percent_Population_Infected
FROM covid_deaths
WHERE location= 'INDIA'
ORDER BY 1,2;


-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATES WITH RESPECT TO POPULATION
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count,  MAX(((total_cases/population)*100)) AS Percent_Population_Infected
FROM covid_deaths
GROUP BY location
order by 4 DESC;


-- LOOKING AT COUNTRIES WITH HIGHEST NUMBER OF DEATHS
SELECT location, population, MAX(total_deaths) AS Highest_Death_Count
FROM covid_deaths
WHERE continent != ''
GROUP BY location
order by 3 DESC;


-- LOOKING AT CONTINENTS WITH HIGHEST NUMBER OF DEATHS
SELECT Location, population, MAX(total_deaths) AS Highest_Death_Count
FROM covid_deaths
WHERE continent = '' and location not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low Income')
GROUP BY LOCATION
order by 3 DESC; 


-- GLOBAL NUMBERS GROUPED BY DATE
SELECT date_, SUM(new_cases) AS cases_per_day, SUM(new_deaths) AS deaths_per_day, (sum(new_deaths)/sum(new_cases))*100 AS death_per_cases
FROM covid_deaths
WHERE continent != ''
GROUP BY date_
ORDER BY 1;

SELECT SUM(new_cases) AS cases_per_day, SUM(new_deaths) AS deaths_per_day, (sum(new_deaths)/sum(new_cases))*100 AS death_per_cases
FROM covid_deaths
WHERE continent != ''
ORDER BY 1;


-- JOGGING OUR MEMORY ON THE SECOND TABLE WITH VACCINATION DATA
SELECT * FROM covid_vaccines;


-- MERGING THE TWO TABLES
SELECT * FROM covid_deaths AS dea
INNER JOIN covid_vaccines AS vac
ON dea.location = vac.location
AND dea.date_ = vac.date_;

-- LOOKING AT TOTAL POPULATION  VS VACCINATION
SELECT dea.continent, dea.location, dea.date_,  dea.population, vac.new_vaccinations
FROM covid_deaths AS dea
INNER JOIN covid_vaccines AS vac
	ON dea.location = vac.location
	AND dea.date_ = vac.date_
WHERE dea.continent != ''
ORDER BY 2,3;


SELECT dea.continent, dea.location, dea.date_, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_) as rolling_total_vaccinations
FROM covid_deaths AS dea
INNER JOIN covid_vaccines AS vac
	ON dea.location = vac.location
	AND dea.date_ = vac.date_
WHERE dea.continent != ''
ORDER BY 2,3;


-- USING CTE
WITH Pop_vs_Vac (Continent, Location, Date_, Population, New_vaccinations, Rolling_Total_Vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date_, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_) as rolling_total_vaccinations
FROM covid_deaths AS dea
INNER JOIN covid_vaccines AS vac
	ON dea.location = vac.location
	AND dea.date_ = vac.date_
WHERE dea.continent != ''
)
SELECT *, (rolling_total_vaccinations/ population)*100
FROM pop_vs_vac;


-- USING TEMP TABLE
Create temporary table PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date_ date, 
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);


DROP TABLE IF EXISTS PercentPopulationVaccinated;
INSERT INTO PercentPopulationVaccinated
(
SELECT dea.continent, dea.location, dea.date_, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_) as rolling_total_vaccinations
FROM covid_deaths AS dea
INNER JOIN covid_vaccines AS vac
	ON dea.location = vac.location
	AND dea.date_ = vac.date_
WHERE dea.continent != ''
);

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PercentPopulationVaccinated;



-- CREATING VIEW FOR DATA VISUALIZATION LATER
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date_, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_) as rolling_total_vaccinations
FROM covid_deaths AS dea
INNER JOIN covid_vaccines AS vac
	ON dea.location = vac.location
	AND dea.date_ = vac.date_
WHERE dea.continent != '';