/*

Queries to clean data in SQL

*/


/* 
Changing the sale date from datetime to date
*/

ALTER TABLE SQLPractice..Housing ALTER COLUMN SaleDate DATE

SELECT SaleDate
FROM SQLPractice..Housing



/* 
Filling property address data
*/

SELECT *
FROM SQLPractice..Housing
WHERE PropertyAddress IS NULL

-- ParcelID is tied to property address, null values can be populated using this
-- Join the table to itself where parcelID is the same but not the same as UniqueID so therefore in a different row
SELECT H1.ParcelID, H1.PropertyAddress, H2.ParcelID, H2.PropertyAddress, ISNULL(H1.PropertyAddress, H2.PropertyAddress)
FROM SQLPractice..Housing H1
JOIN SQLPractice..Housing H2
	ON H1.ParcelID = H2.ParcelID
	AND H1.[UniqueID ] <> H2.[UniqueID ]
WHERE H1.PropertyAddress IS NULL

UPDATE H1
SET PropertyAddress = ISNULL(H1.PropertyAddress, H2.PropertyAddress)
FROM SQLPractice..Housing H1
JOIN SQLPractice..Housing H2
	ON H1.ParcelID = H2.ParcelID
	AND H1.[UniqueID ] <> H2.[UniqueID ]
WHERE H1.PropertyAddress IS NULL



/*
Separating property addresses into individual columns (address, city, state) using substring
*/

SELECT PropertyAddress
FROM SQLPractice..Housing

--+1 and -1 used in character index to remove the comma from the results
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))  AS City
FROM SQLPractice..Housing

--Alter table to add columns and update with information

ALTER TABLE SQLPractice..Housing
ADD PropertySplitAddress nvarchar(255);

UPDATE SQLPractice..Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE SQLPractice..Housing
ADD PropertySplitCity nvarchar(255);

UPDATE SQLPractice..Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))



/*
Separarting owner addresses using parsename
*/

SELECT OwnerAddress
FROM SQLPractice..Housing

--For owner address, the address, city, state all separated by commas
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM SQLPractice..Housing


--Alter table to add columns and update with information

ALTER TABLE SQLPractice..Housing
ADD OwnerSplitAddress nvarchar(255);

UPDATE SQLPractice..Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE SQLPractice..Housing
ADD OwnerSplitCity nvarchar(255);

UPDATE SQLPractice..Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE SQLPractice..Housing
ADD OwnerSplitState nvarchar(255);

UPDATE SQLPractice..Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



/*
Changing the "sold as vacant" column to be consistent (Y to yes, N to no)
*/

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	     WHEN SoldAsVacant = 'N' THEN 'No'
	     ELSE SoldAsVacant
	END
FROM SQLPractice..Housing

UPDATE SQLPractice..Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
		   END



/*
Removing duplicates
*/

WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY 
				ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
		  ) AS row_num
FROM SQLPractice..Housing
)

-- Shows 104 duplicate rows
--SELECT *
--FROM RowNumCTE
--WHERE row_num > 1
--ORDER BY PropertyAddress

-- To delete duplicate rows
DELETE
FROM RowNumCTE
WHERE row_num > 1



/*
Removing unused columns
*/

ALTER TABLE SQLPractice..Housing
DROP COLUMN OwnerAddress, PropertyAddress
