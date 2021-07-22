/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM DataCleaningProject..housing_price


--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM DataCleaningProject..housing_price

ALTER TABLE housing_price
ADD SaleDateConverted Date;

UPDATE housing_price
SET SaleDateConverted = CONVERT(Date, SaleDate)


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
-- Check the Property Address correlation with the ParcelID
-- Using self joint to populate the null data corresponding to the ParcelID

SELECT PropertyAddress, ParcelID
FROM housing_price
--WHERE PropertyAddress is null
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing_price a
JOIN housing_price b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing_price a
JOIN housing_price B
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null
	



--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
-- Using Subtring to seperate the elements in the PropertyAddress column

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, len(PropertyAddress) ) AS City
FROM housing_price

ALTER TABLE housing_price
ADD PropertySplitAddress nvarchar(255);

UPDATE housing_price
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) 

ALTER TABLE housing_price
ADD PropertySplitCity nvarchar(255);

UPDATE housing_price
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, len(PropertyAddress) )


-- Using Parsename to break out OwnerAddress into Address,City, State
-- Use Replace to change comma to period as Parsename only acts on period

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 1)
FROM housing_price

ALTER TABLE housing_price
ADD 
OwnerSplitAddress nvarchar(255),
OwnerSplitCity nvarchar(255),
OwnerSplitState nvarchar(255)

UPDATE housing_price
SET
OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3), 
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 1)



--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM housing_price
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
	 WHEN SoldAsVacant = 'N'THEN 'NO'
	 ELSE SoldAsVacant
	 END
FROM housing_price

UPDATE housing_price
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
						WHEN SoldAsVacant = 'N'THEN 'NO'
						ELSE SoldAsVacant
						END





-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- Using Row_number() Over PArtiton BY to find duplicates row and using CTE to use Where confition on row_num

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order By
					UniqueID
					) row_num

FROM housing_price
)
DELETE
FROM RowNumCTE
WHERE row_num > 1









---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns
-- Delete unwanted columns that cause redundancy

SELECT *
FROM housing_price

ALTER TABLE housing_price
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate





