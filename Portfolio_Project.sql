alter table coviddeaths1 alter column new_cases_smoothed type varchar(255);
alter table coviddeaths1 alter column new_deaths_smoothed type varchar(255);
alter table coviddeaths1 alter column population type bigint;
alter table coviddeaths1 alter column new_deaths_smoothed_per_million type varchar(255);
copy coviddeaths1 from 'C:\Program Files\PostgreSQL\14\data\Data\CovidDeaths.csv' delimiter ',' csv header;

drop table covidvaccinations1;

select *
from "COVID_Analysis".public.coviddeaths1
where continent is not null
order by 3,4;

/*select *
from "COVID_Analysis".public.covidvaccinations1
order by 3,4;*/

--Select data that we are going to be using

alter table coviddeaths1 alter column date type date using to_date(date, 'DD-MM-YYYY');

select location ,date ,total_cases ,new_cases,total_deaths ,population 
from "COVID_Analysis".public.coviddeaths1
order by 1,2;

--Looking at total cases vs total deaths
--Shows the likelihood of dying when people attracted covid
select location ,date ,total_cases ,total_deaths,  (total_deaths::numeric /total_cases)*100 as Deaths_Percentage_cases
from "COVID_Analysis".public.coviddeaths1
where location like '%India%'
order by 1,2;

--Looking at total cases vs population

select location ,date ,total_cases ,population,  (total_cases::numeric /population)*100 as Contraction_percentage
from "COVID_Analysis".public.coviddeaths1
--where location like '%India%'
order by 1,2;


--Looking at countries with highest infection rate compared to population

select location ,population, max(total_cases ) as HighestInfectionCount , max((total_cases::numeric /population))*100 
as HighestContraction_percentage
from "COVID_Analysis".public.coviddeaths1
--where location like '%India%'
group by location,population 
order by HighestContraction_percentage desc;


--Showing countries with highest death count per population

select location ,
	case when max(total_deaths) is null then 0
	else max(total_deaths)
	end
	as total_death_count
from "COVID_Analysis".public.coviddeaths1
--where location like '%India%'
where continent is not null
--upper condition because we don't want to show continents in the countries section
group by location
order by total_death_count desc;

--Let's see data by continent


select continent,
	case when sum(new_deaths) is null then 0
	else sum(new_deaths)
	end
	as total_death_count
from "COVID_Analysis".public.coviddeaths1
--where location like '%India%'
where continent is not null
--upper condition because we don't want to show continents in the countries section
group by continent 
order by total_death_count desc; 



/* GLOBAL NUMBERS */

select date ,sum(new_cases) as total_case,sum(new_deaths) as total_death,(sum(new_deaths::numeric)/sum(new_cases))*100 as percentagedeath_percase 
from "COVID_Analysis".public.coviddeaths1
--where location like '%India%'
where continent is not null
group by "date" 
order by 1,2;

--Looking at total population vs vaccination

select a.continent ,a.location, a.date, a.population, b.new_vaccinations
	,sum(cast(nullif(b.new_vaccinations,'') as integer)) 
	over (partition by a.location order by a.location,a.date)
	as total_vaccinations_tilldate
from coviddeaths1 as a
join "COVID_Analysis".public.covidvaccinations1 as b
 on a.location=b.location
 and a.date=b.date
where a.continent is not null
order by 2,3;

--USE CTE to find percentage of population who have vaccinated of a particular country

with popvsvac(Continent , location, Date, Population, New_vaccination, RollingPeopleVaccinated)
as(
select a.continent ,a.location, a.date, a.population, b.new_vaccinations
	,sum(cast(nullif(b.new_vaccinations,'') as integer)) 
	over (partition by a.location order by a.location,a.date)
	as total_vaccinations_tilldate
from coviddeaths1 as a
join "COVID_Analysis".public.covidvaccinations1 as b
 on a.location=b.location
 and a.date=b.date
where a.continent is not null
--order by 2,3;
)
select *,(RollingPeopleVaccinated::numeric/population )*100 as percentage_vaccinated from popvsvac;



--TEMP TABLE
drop table if exists PercentPopulationVaccinated
create table PercentPopulationVaccinated
(
continent varchar(255),
location varchar(255),
Date date,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

insert into PercentPopulationVaccinated
select a.continent ,a.location, to_date(a.date,'YYYY-MM-DD'), a.population, nullif(b.new_vaccinations,'')::numeric
	,sum(cast(nullif(b.new_vaccinations,'') as integer)) 
	over (partition by a.location order by a.location,a.date)
	as total_vaccinations_tilldate
from coviddeaths1 as a
join "COVID_Analysis".public.covidvaccinations1 as b
 on a.location=b.location
 and a.date=b.date
--where a.continent is not null
--order by 2,3;
;
select *,(RollingPeopleVaccinated::numeric/population )*100 
as percentage_vaccinated from PercentPopulationVaccinated;



--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION
drop view Percent_Population_Vaccinated;
create view Percent_Population_Vaccinated as
select a.continent ,a.location, to_date(a.date,'YYYY-MM-DD') as date, a.population, nullif(b.new_vaccinations,'')::numeric
	,sum(cast(nullif(b.new_vaccinations,'') as integer)) 
	over (partition by a.location order by a.location,a.date)
	as total_vaccinations_tilldate
from coviddeaths1 as a
join "COVID_Analysis".public.covidvaccinations1 as b
 on a.location=b.location
 and a.date=b.date
where a.continent is not null;
--order by 2,3;

select *
from percent_population_vaccinated