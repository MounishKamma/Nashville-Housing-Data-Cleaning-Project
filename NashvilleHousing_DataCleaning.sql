USE PortfolioProject;

-- STEP 1: Initial Data Review
SELECT *
FROM nashvillehousing
LIMIT 10;

-- STEP 2: Review Sale Date of Housing
SELECT SaleDate
FROM nashvillehousing;

-- STEP 3: Test Sale Date Conversion
SELECT
    SaleDate,
    STR_TO_DATE(SaleDate, '%M %d, %Y') AS ConvertedDate
FROM nashvillehousing;

SELECT SaleDate
FROM nashvillehousing
LIMIT 20;

-- STEP 4: Disable Safe Updates
SET SQL_SAFE_UPDATES = 0;

-- STEP 5: Standardize Sale Date Format
UPDATE nashvillehousing
SET SaleDateConverted = DATE(SaleDate);

-- STEP 6: Identify Missing Property Addresses
SELECT *
FROM nashvillehousing
WHERE PropertyAddress IS NULL;

-- STEP 7: Populate Missing Property Addresses
UPDATE nashvillehousing a
JOIN nashvillehousing b
    ON a.ParcelID = b.ParcelID
   AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL;

SELECT ParcelID, PropertyAddress
FROM nashvillehousing
WHERE PropertyAddress IS NULL;

-- STEP 8: Split Property Address into Address and City
SELECT
    PropertyAddress,
    SUBSTRING_INDEX(PropertyAddress, ',', 1) AS PropertySplitAddress,
    SUBSTRING_INDEX(PropertyAddress, ',', -1) AS PropertySplitCity
FROM nashvillehousing
LIMIT 20;

-- Add new columns for split address values
ALTER TABLE nashvillehousing
ADD PropertySplitAddress TEXT;

ALTER TABLE nashvillehousing
ADD PropertySplitCity TEXT;

-- Populate new split address columns
UPDATE nashvillehousing
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1),
    PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1);
    
    
-- Verify split address results
SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM nashvillehousing
LIMIT 20;

-- STEP 9: Split Owner Address into Address, City, and State
SELECT
    OwnerAddress,
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS OwnerSplitAddress,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS OwnerSplitCity,
    SUBSTRING_INDEX(OwnerAddress, ',', -1) AS OwnerSplitState
FROM nashvillehousing
LIMIT 20;

-- Add new columns
ALTER TABLE nashvillehousing
ADD OwnerSplitAddress TEXT;

ALTER TABLE nashvillehousing
ADD OwnerSplitCity TEXT;

ALTER TABLE nashvillehousing
ADD OwnerSplitState TEXT;

-- Populate new owner address columns
UPDATE nashvillehousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1),
    OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
    OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

-- Verify results
SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM nashvillehousing
LIMIT 20;

-- STEP 10: Standardize SoldAsVacant Values
-- Check existing values
SELECT DISTINCT SoldAsVacant, COUNT(*) AS Count
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY Count DESC;

-- Preview standardization logic
SELECT
    SoldAsVacant,
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS StandardizedSoldAsVacant
FROM nashvillehousing;

-- Update values
UPDATE nashvillehousing
SET SoldAsVacant =
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;

-- Verify updated values
SELECT DISTINCT SoldAsVacant, COUNT(*) AS Count
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY Count DESC;

-- STEP 11: Identify Duplicate Records
SELECT
    ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference,
    COUNT(*) AS DuplicateCount
FROM nashvillehousing
GROUP BY
    ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference
HAVING COUNT(*) > 1;

-- STEP 12: Review Duplicate Rows Using ROW_NUMBER
WITH RowNumCTE AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM nashvillehousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;

-- STEP 13: Remove Duplicate Records
DELETE FROM nashvillehousing
WHERE UniqueID IN
(
    SELECT UniqueID
    FROM
    (
        SELECT
            UniqueID,
            ROW_NUMBER() OVER (
                PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                ORDER BY UniqueID
            ) AS row_num
        FROM nashvillehousing
    ) duplicate_rows
    WHERE row_num > 1
);
-- Verify duplicate removal
WITH RowNumCTE AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM nashvillehousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;

-- STEP 14: Remove Unused Columns
ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress,
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;

-- STEP 15: Review Final Cleaned Dataset
SELECT *
FROM nashvillehousing
LIMIT 20;

DESCRIBE nashvillehousing;

-- STEP 16: Export Final Cleaned Dataset
SELECT *
FROM nashvillehousing;