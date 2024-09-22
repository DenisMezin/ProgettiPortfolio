------------------------------------------------------------------------------------------------------

---------------------------------- DATA CLEANING IN SQL ----------------------------------------------

------------------------------------------------------------------------------------------------------
Select * 
FROM Progetti_Portfolio.dbo.NashvilleAlloggi

------------------------------------------------------------------------------------------------------
--(1)STANDARIZZARE IL FORMATO DELLA DATA
------------------------------------------------------------------------------------------------------

-- Istruzione di conversione
Select SaleDate, Convert(date, SaleDate) as DataSemplice
FROM Progetti_Portfolio.dbo.NashvilleAlloggi

--Update con SET (nel SET non ci va l' ALIAS ma l'istruzione)
UPDATE NashvilleAlloggi
SET SaleDate = Convert(date, SaleDate) -- !!! Proviamo a modificare SaleDate ma non va

--Procedura di Sostituzione del SaleDate 
ALTER TABLE NashvilleAlloggi        -- 1. Aggiungiamo nuova Colonna di tipo (Date)
ADD SaleDateConvertito Date;

UPDATE NashvilleAlloggi             -- 2. UPDATE e SET con l'istruzione di CONVERSIONE
SET SaleDateConvertito = Convert(date, SaleDate)

SELECT *                           -- 3. Verifichiamo
FROM Progetti_Portfolio.dbo.NashvilleAlloggi

-----------------------------------------------------------------------------------------------
--(2)POPULATE PROPERTY ADDRESS DATA
-----------------------------------------------------------------------------------------------

-- verifichiamo i casi in cui PropertyAddress sono Nulli per trarne qualche caso particolare
Select *
FROM Progetti_Portfolio.dbo.NashvilleAlloggi
--WHERE PropertyAddress is Null
ORDER BY ParcelID

-- JOIN dei ParceID == con UniqueID !=   ||  ISNULL istruzione che sostit posiz A. con B.
Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM Progetti_Portfolio.dbo.NashvilleAlloggi AS A
JOIN Progetti_Portfolio.dbo.NashvilleAlloggi AS B
	ON A.ParcelID = B.ParcelID -- Con Unique ID andiamo a modificare solo casi specifici
	AND A. [UniqueID ] <> B.[UniqueID ] --Perciò, cosi facendo non SOVVRASCRIVIAMO i dati
WHERE A.PropertyAddress IS NULL
--Upadate del database A (alias) in cui vado a SETtare gli indirizzi NULLI
UPDATE A
SET PROPERTYADDRESS = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM Progetti_Portfolio.dbo.NashvilleAlloggi AS A
JOIN Progetti_Portfolio.dbo.NashvilleAlloggi AS B
	ON A.ParcelID = B.ParcelID 
	AND A. [UniqueID ] <> B.[UniqueID ] 
WHERE A.PropertyAddress IS NULL


------------------------------------------------------------------------------------------------------
--(3)BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMS (ADDRESS, CITY, STATE)
------------------------------------------------------------------------------------------------------

--Vedo che PropertyAddress ha tanti valori che si possono suddividere in nuove colonne
Select PropertyAddress
from Progetti_Portfolio.dbo.NashvilleAlloggi

-- Istruzione che ci permette 
Select Substring(PropertyAddress,1, CHARINDEX(',' , PropertyAddress) -1 ) as Address --  -1 Cosi togliamo ','
from Progetti_Portfolio.dbo.NashvilleAlloggi

-- SPLITTING della colonna PropertyAddress in Nuove colonne
-- colonne ADDRESS e CITY
Select 
Substring(PropertyAddress,1,CHARINDEX(',' , PropertyAddress) -1 ) as Address, --1° split ADDRESS 
Substring(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1 , LEN(PropertyAddress)) as City --2° split City
from Progetti_Portfolio.dbo.NashvilleAlloggi


-- UPDATE delle nuove colonne splittate
ALTER TABLE NashvilleAlloggi
ADD PropertySplidAddress nvarchar(255);

	UPDATE NashvilleAlloggi
	SET PropertySplidAddress = Substring(PropertyAddress,1,CHARINDEX(',' , PropertyAddress) -1 )

	ALTER TABLE NashvilleAlloggi
	ADD PropertySplidCity nvarchar(255);

	UPDATE NashvilleAlloggi
	SET PropertySplidCity = Substring(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1 , LEN(PropertyAddress))


--Verifichiamo (le colonne nuove vengono disposte in fondo)
Select *
FROM Progetti_Portfolio.dbo.NashvilleAlloggi


---------------------------------------------------------------------------------------------------------

-- Modo piu semplice -> Stesso esercizio ma con OwnerAddress
--PARSNAME 

--Vado a selezionare OwnerAddress e osservo la Tabella
Select OwnerAddress
from Progetti_Portfolio.dbo.NashvilleAlloggi
Where OwnerAddress is Not NULL

-- Studio la funzione PARSNAME, ma non è cambiato nulla 
Select PARSENAME(OwnerAddress,1)
from Progetti_Portfolio.dbo.NashvilleAlloggi
Where OwnerAddress is not NULL


-- Per rimediare a ciò uso il REPLACE che mi consente di rimpiazzare tutte le ',' con '.'
-- La funzione PARSNAME estrae la prima parte, quindi l'ultima componente dopo l'ultimo punto '.' ovvero TN
Select PARSENAME(REPLACE(OwnerAddress, ',' , '.' ), 1 )
from Progetti_Portfolio.dbo.NashvilleAlloggi
Where OwnerAddress is not NULL

-- Ecco che qui andiamo a aggiungere altre 2 istruzioni così da suddividere in 3 colonne 
-- L'ordine è 3,2,1 poichè con PARSNAME si parte dalla prima Parola dopo l'ultima ',' o in questo caso '.' 
Select 
PARSENAME(REPLACE(OwnerAddress, ',' , '.' ), 3 ),
PARSENAME(REPLACE(OwnerAddress, ',' , '.' ), 2 ),
PARSENAME(REPLACE(OwnerAddress, ',' , '.' ), 1 )
from Progetti_Portfolio.dbo.NashvilleAlloggi
Where OwnerAddress is not NULL

-- Ora bisogna inserire queste colonne nel nostro DATABASE e aggiungere i valori all'interno di esse

                                  -- |1| OwnerAddressNew
ALTER TABLE Progetti_Portfolio.dbo.NashvilleAlloggi
ADD OwnerAddressNew nvarchar(255);

UPDATE Progetti_Portfolio.dbo.NashvilleAlloggi
SET OwnerAddressNew = PARSENAME(REPLACE(OwnerAddress, ',' , '.' ), 3 )
                                  -- |2| OwnerAddressPlace
ALTER TABLE Progetti_Portfolio.dbo.NashvilleAlloggi
ADD OwnerAddressPlace nvarchar(255);

UPDATE Progetti_Portfolio.dbo.NashvilleAlloggi
SET OwnerAddressPlace = PARSENAME(REPLACE(OwnerAddress, ',' , '.' ), 2 )
                                  -- |3| OwnerAddressTN
ALTER TABLE Progetti_Portfolio.dbo.NashvilleAlloggi
ADD OwnerAddressTN nvarchar(255);

UPDATE Progetti_Portfolio.dbo.NashvilleAlloggi
SET OwnerAddressTN = PARSENAME(REPLACE(OwnerAddress, ',' , '.' ), 1 )


-- VERIFICHIAMOO!!!
Select *
FROM Progetti_Portfolio.dbo.NashvilleAlloggi
WHERE OwnerAddress is NOT NULL


------------------------------------------------------------------------------------------------------
--(4)CHANGE Y AND N TO YES AND NO IN 'SOLD AS VACANT' FIELD
------------------------------------------------------------------------------------------------------

--Guardo la colonna 'SoldAsVacant', e con questa Query noto che ci sono casi particolari di risposte 'N' e 'Y' rispetto a 'Yes & 'No'
Select SoldAsVacant, count(SoldAsVacant) as Casi_di_SoldAsVacant
FROM Progetti_Portfolio.dbo.NashvilleAlloggi
Group by SoldAsVacant

-- rigurardo questi casi N e Y
Select SoldAsVacant
FROM Progetti_Portfolio.dbo.NashvilleAlloggi
WHERE SoldAsVacant like 'N' or SoldAsVacant LIKE 'Y'


------------- OBIETTIVO: Sostituire N -> No  &  Y -> Yes ----------------------------


-- Per fare ciò uso un CASE STATEMENT dove vado a sostituire i casi specifici e vado a lasciare intatto il resto
Select SoldAsVacant, count(SoldAsVacant), 
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END 
FROM Progetti_Portfolio.dbo.NashvilleAlloggi
Group by SoldAsVacant


-- UPDATE 
UPDATE Progetti_Portfolio.dbo.NashvilleAlloggi
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END 

-- Verifico
Select SoldAsVacant, count(SoldAsVacant) as Casi_di_SoldAsVacant
FROM Progetti_Portfolio.dbo.NashvilleAlloggi
Group by SoldAsVacant

----------------------------------------------------------------------------------------------------------
--(5)REMOVE DUPLICATE S
----------------------------------------------------------------------------------------------------------

--             , 114 Colonne sono Doppioni
WITH Row_NumCTE AS(
Select *, 
ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID ) AS Row_Num
FROM Progetti_Portfolio.dbo.NashvilleAlloggi
)
SELECT *
FROM Row_NumCTE
WHERE Row_Num > 1
ORDER BY ParcelID

-- Eliminazione di queste colonne doppie

WITH Row_NumCTE AS(
Select *, 
ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID ) AS Row_Num
FROM Progetti_Portfolio.dbo.NashvilleAlloggi
)
DELETE 
FROM Row_NumCTE
WHERE Row_Num > 1


-- Verifichiamo
WITH Row_NumCTE AS(
Select *, 
ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID ) AS Row_Num
FROM Progetti_Portfolio.dbo.NashvilleAlloggi
)
SELECT *
FROM Row_NumCTE
WHERE Row_Num > 1
ORDER BY ParcelID


----------------------------------------------------------------------------------------------------------
--(6)DELETE UNUSED COLUMS
----------------------------------------------------------------------------------------------------------

----------- OBIETTIVO: Eliminare le colonne TaxDistinct, SaleDate (x la Data),
                    -- PropertyAddress e OwnerAddress (non servono piu perchè gia spartite in Nuove-colonne)

ALTER TABLE Progetti_Portfolio.dbo.NashvilleAlloggi
DROP COLUMN TaxDistrict, PropertyAddress, OwnerAddress, SaleDate

-- Verifico
Select *
From Progetti_Portfolio.dbo.NashvilleAlloggi

----------------------------------------------------------------------------------------------------------