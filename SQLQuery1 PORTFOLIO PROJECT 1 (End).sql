Select *
From Progetti_Portfolio.DBO.Covid_Morti
order by population desc
--WHERE CONTINENT IS NOT NULL

------------------------------------------------

--Select *
--From Progetti_Portfolio..Vaccinazioni
--order by 3,4

------------------------------------------------

Select location, date, total_cases, new_cases, total_deaths, population
From Progetti_Portfolio..Covid_Morti
order by 1,2


------------------ casi totali contro morti totali ----------------------------------
---- Questa query mi mostra la Probabilità di morire in Italia

Select location, date ,total_cases,total_deaths,(total_deaths/total_cases)*100 AS PercentualeMorte
From Progetti_Portfolio..Covid_Morti 
where location Like 'Italy'
order by date desc, PercentualeMorte desc

----------------------------------------------------------------------------------------------------
---------------------- casi totali contro popolazione ----------------------------------------------

---- Questa query mi mostra la Percentuale di persone che hanno tratto il Covid

SELECT Location, total_cases, population, (total_cases/population)*100 AS PP
FROM Progetti_Portfolio.dbo.Covid_Morti
Order by total_cases DESC,PP DESC



----------------------------------------------------------------------------------------------------
---- Paesi con il maggior numero di infetti 

SELECT Location, population, max(total_cases) as Max_casi, max((total_cases/population))*100 AS Perc_popolazione_infetta
FROM Progetti_Portfolio.dbo.Covid_Morti
group by location, population
order by Perc_popolazione_infetta DESC



----------------------------------------------------------------------------------------------------
---- Paesi con il maggior numero di morti

Select location, Max(cast(total_deaths as int)) AS Max_Morti_x_day
FROM Progetti_Portfolio.dbo.Covid_Morti
WHERE CONTINENT IS NOT NULL
group by location
order by Max_Morti_x_day desc



----------------------------------------------------------------------------------------------------
---- CONTINENTI con il maggior numero di morti

Select location, Max(cast(total_deaths as int)) AS MaxMortixday 
FROM Progetti_Portfolio.dbo.Covid_Morti
WHERE continent IS NULL AND Location NOT LIKE '%World%' AND location NOT LIKE '%International%'
group by location
order by MaxMortixday desc


----------------------------------------------------------------------------------------------------
---- Giorno con il maggior numero di morti nel MONDO

Select location,date, max(cast(total_deaths as int)) as MaxMortinelMondo
FROM Progetti_Portfolio.dbo.Covid_Morti
where location = 'World'
group by location, date
order by MaxMortinelMondo desc


--------------------------------------------------------------------------------------------------------------------
---- Ma andiamo a indagare sul giorno '04-30-21' per capire dove vi sono stati il maggior numero di Morti e di Casi

Select location,total_cases as Casi_30_04_21, cast(total_deaths as int) as Morti_30_04_21
FROM Progetti_Portfolio.dbo.Covid_Morti
where date = '2021-04-30T00:00:00.000' AND Continent is not Null
order by cast(total_deaths as int) desc


----------------------------------------------------------------------------------------------------
---- Percentuale di persone che sono morte causa Covid rispetto alla popolazione totale

SELECT Location, population, max(cast(total_deaths as int)) as Max_casi, max((total_deaths/population))*100 AS Perc_popolazione_morta
FROM Progetti_Portfolio.dbo.Covid_Morti
WHERE CONTINENT IS NOT NULL
group by location, population
order by Perc_popolazione_morta DESC


------------------------------------------------------------------------------------------------------------------------------
--------------------------------- Numeri Globali ------------------------------------------------------------ 

--- Tutte le tabelle con dei valori (eccetto 'date')
Select location,population, total_cases,new_cases,new_cases_smoothed, total_deaths, new_deaths_smoothed, total_cases_per_million, 
new_cases_per_million, new_cases_smoothed_per_million, total_deaths_per_million, new_deaths_per_million, new_deaths_smoothed_per_million, reproduction_rate
from Progetti_Portfolio.dbo.Covid_Morti
Where Location lIKE 'World'

-- MODO 1.0 (errore divisone per 0)
Select date, SUM(new_cases) as Nuovi_casi, SUM(CAST(new_deaths AS float))AS Nuovi_morti, SUM(CAST(new_deaths AS float))/SUM(new_cases)*100  Perc_Morte
from Progetti_Portfolio.dbo.Covid_Morti
Where Location lIKE 'World' 
group by date
order by 1

-- MODO 1.1 ci fornisce tutti i dati 
SELECT date, SUM(new_cases) AS Nuovi_casi, SUM(CAST(new_deaths AS float)) AS Nuovi_morti, 
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0 
        ELSE SUM(CAST(new_deaths AS float)) / SUM(new_cases) * 100 
    END AS Perc_Morte
FROM Progetti_Portfolio.dbo.Covid_Morti
WHERE Location LIKE 'World'
GROUP BY date
ORDER BY date DESC

-- MODO 2 -- ci da solamente 1 dato sulla percentuale di Morte maggiore mai avvenuta in 1 giorno (2.112%)
SELECT SUM(new_cases) AS Nuovi_casi, SUM(CAST(new_deaths AS float)) AS Nuovi_morti, 
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0 
        ELSE SUM(CAST(new_deaths AS float)) / SUM(new_cases) * 100 
    END AS Perc_Morte
FROM Progetti_Portfolio.dbo.Covid_Morti
WHERE Location LIKE 'World'
ORDER BY 1 DESC
--------------------------------------------------------------------------------------------------------------
------------------------------------------- dbo.Vaccinazioni -------------------------------------------------
--------------------------------------------------------------------------------------------------------------
Select *
from Progetti_Portfolio.dbo.Covid_Morti as CM
Join Progetti_Portfolio.dbo.Vaccinazioni as VA
	ON CM.location = VA.location
	AND CM.date = VA.date

-- POPOLAZIONE CONTRO VACCINAZIONI

Select CM.continent, CM.location, CM.date , CM.population , VA.new_vaccinations 
from Progetti_Portfolio.dbo.Covid_Morti as CM
Join Progetti_Portfolio.dbo.Vaccinazioni as VA
	ON CM.location = VA.location
	AND CM.date = VA.date
where CM.continent is NOT NULL AND new_vaccinations IS NOT NULL	
ORDER BY 2,3

-------- Contatore di Vaccinazioni

Select CM.continent, CM.location, CM.date , CM.population , VA.new_vaccinations,
SUM(CONVERT(int,VA.new_vaccinations)) OVER (PARTITION BY CM.Location ORDER BY CM.Location, CM.date)
AS CONTA_Vaccinazioni, --qui uso CONVERT, simile a CAST
      -- in tal modo il contantore non continua a sommare in contunuo ma si ferma qunando cambia Paese (Location)
from Progetti_Portfolio.dbo.Covid_Morti as CM
Join Progetti_Portfolio.dbo.Vaccinazioni as VA
	ON CM.location = VA.location
	AND CM.date = VA.date
where CM.continent is NOT NULL	
ORDER BY 2,3

-------- Percentuale rispetto al contatore di vaccinazioni giorno x giorno

Select CM.continent, CM.location, CM.date , CM.population , VA.new_vaccinations,
SUM(CONVERT(int,VA.new_vaccinations)) OVER (PARTITION BY CM.Location ORDER BY CM.Location, CM.date)
AS CONTA_Vaccinazioni, (CONTA_Vaccinazioni/population)*100 --Voglio fare ciò ma non mi lascia
-- Infatti, non si può utilizzare una colonna che è stata appena creata
from Progetti_Portfolio.dbo.Covid_Morti as CM
Join Progetti_Portfolio.dbo.Vaccinazioni as VA
	ON CM.location = VA.location
	AND CM.date = VA.date
where CM.continent is NOT NULL	
ORDER BY 2,3

---- Pert risolvere il problema possiamo utilizzare diversi modi: CTE o una TEMP_TABLE
---- 1. CTE ----------------------------------------------------------------------------

WITH CTE_POPvsVAC (Continent, Location, Date, Population,new_vaccinations,CONTA_Vaccinazioni)
as
(
Select CM.continent, CM.location, CM.date , CM.population , VA.new_vaccinations,
SUM(CONVERT(int,VA.new_vaccinations)) OVER (PARTITION BY CM.Location ORDER BY CM.Location, CM.date)
AS CONTA_Vaccinazioni --,(CONTA_Vaccinazioni/population)*100 
from Progetti_Portfolio.dbo.Covid_Morti as CM
Join Progetti_Portfolio.dbo.Vaccinazioni as VA
	ON CM.location = VA.location
	AND CM.date = VA.date
where CM.continent is NOT NULL	
)
SELECT *, (CONTA_Vaccinazioni/population)*100 --Eseguo dentro il SELECT l'ISTRUZIONE 
FROM CTE_POPvsVAC
--(ricorda che quando vuoi eseguire una CTE devi selezionare tutto...da WITH CTE_POPvsVAC a FROM CTE_POPvsVAC)


--- 2. TEMP TABLE --------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS #PercPopolazioneVaccinata
CREATE TABLE #PercPopolazioneVaccinata
( Continent nvarchar(255),
  Location nvarchar(255),
  date  datetime, 
  population numeric, -- o Float
  new_vaccinations numeric,  -- o int
  CONTA_Vaccinazioni numeric
)


INSERT INTO #PercPopolazioneVaccinata
Select CM.continent, CM.location, CM.date , CM.population , VA.new_vaccinations,
SUM(CONVERT(int,VA.new_vaccinations)) OVER (PARTITION BY CM.Location ORDER BY CM.Location, CM.date)
AS CONTA_Vaccinazioni --, (CONTA_Vaccinazioni/population)*100 --Voglio fare ciò ma non mi lascia
-- Infatti, non si può utilizzare una colonna che è stata appena creata
from Progetti_Portfolio.dbo.Covid_Morti as CM
Join Progetti_Portfolio.dbo.Vaccinazioni as VA
	ON CM.location = VA.location
	AND CM.date = VA.date
WHERE  CM.continent IS NOT NULL

Select *,(CONTA_Vaccinazioni/population)*100
FROM #PercPopolazioneVaccinata

--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

--- CREATE VIEW --- per salvare i Dati le visualizzazioni che farò dopo

CREATE VIEW PercPopolazioneVaccinata as
Select CM.continent, CM.location, CM.date , CM.population , VA.new_vaccinations,
SUM(CONVERT(int,VA.new_vaccinations)) OVER (PARTITION BY CM.Location ORDER BY CM.Location, CM.date)
AS CONTA_Vaccinazioni --, (CONTA_Vaccinazioni/population)*100 --Voglio fare ciò ma non mi lascia
-- Infatti, non si può utilizzare una colonna che è stata appena creata
from Progetti_Portfolio.dbo.Covid_Morti as CM
Join Progetti_Portfolio.dbo.Vaccinazioni as VA
	ON CM.location = VA.location
	AND CM.date = VA.date
WHERE  CM.continent IS NOT NULL


Select *
from dbo.PercPopolazioneVaccinata