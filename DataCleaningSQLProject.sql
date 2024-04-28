/*
Data Cleaning Using SQL

This SQL script is used for cleaning and standardizing data in the NashvilleHousing table.
Functions used: CONVERT, ISNULL, SUBSTRING, PARSENAME, DISTINCT, CASE, ROW_NUMBER, PARTITION BY, ORDER BY
*/

-- Retrieve all records from NashvilleHousing table
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

/*
Standardize Date Format Using CONVERT

This section converts the SaleDate into a standard Date format and stores it in a new column.
*/

-- Add a new column for the standardized sale date
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

-- Populate the new column with the standardized sale date
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Display the original and converted sale dates for verification
SELECT saleDate, SaleDateConverted
FROM PortfolioProject.dbo.NashvilleHousing

/*
Populate Missing Property Address Data Using ISNULL

This section handles missing property addresses by attempting to fill gaps using data from similar records.
*/

-- Display all records, primarily for debugging purposes
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID

-- Display missing addresses and their potential replacements
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) AS CorrectedAddress
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

-- Update the table to replace missing addresses
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

/*
Breaking out Property Address into Individual Columns Using SUBSTRING

This section extracts street and city information from the PropertyAddress column into new separate columns.
*/

-- Add new columns for street and city extracted from PropertyAddress
ALTER TABLE NashvilleHousing
ADD 
    PropertyAddressStreet NVARCHAR(255),
    PropertyAddressCity NVARCHAR(255);

-- Populate the new columns with extracted street and city data
UPDATE NashvilleHousing
SET 
    PropertyAddressStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertyAddressCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress) - CHARINDEX(',', PropertyAddress));

-- Display the original and newly extracted data for verification
SELECT PropertyAddress, PropertyAddressStreet, PropertyAddressCity
FROM PortfolioProject.dbo.NashvilleHousing

/*
Breaking out Owner Address into Individual Columns Using PARSENAME

This section extracts street, city, and state information from the OwnerAddress column into new separate columns.
*/

-- Add new columns for street, city, and state extracted from OwnerAddress
ALTER TABLE NashvilleHousing
ADD 
    OwnerAddressStreet NVARCHAR(255),
    OwnerAddressCity NVARCHAR(255),
    OwnerAddressState NVARCHAR(255);

-- Populate the new columns with extracted street, city, and state data
UPDATE NashvilleHousing
SET 
    OwnerAddressStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerAddressCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerAddressState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Display the original and newly extracted data for verification
SELECT OwnerAddress, OwnerAddressStreet, OwnerAddressCity, OwnerAddressState
FROM PortfolioProject.dbo.NashvilleHousing

/*
Change 'Y' and 'N' to 'Yes' and 'No' in the "Sold as Vacant" Field Using CASE

This section standardizes the SoldAsVacant field to improve readability.
*/

-- Display the Distinct Vvalues in SoldAsVacent
SELECT DISTINCT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing

-- Convert 'SoldAsVacant' values from 'Y' and 'N' to 'Yes' and 'No' and display results
Select SoldAsVacant 
,CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END as ScoldAsVacant
from NashvilleHousing
where soldasvacant = 'Y' OR soldasvacant = 'N'

-- Standardize 'Y' and 'N' to 'Yes' and 'No'
UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END

-- Display the standardized SoldAsVacant values for verification
SELECT DISTINCT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing

/*
Identify and Remove Duplicate Records

This section assigns a row number to each record within groups of records that share key attributes (ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference).
Only duplicates (records beyond the first in each group) are identified in this step.
*/

-- Define a CTE to assign row numbers to grouped records, ordered by UniqueID for consistency
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)
-- Delete duplicate records identified by having a row number greater than 1
DELETE
FROM RowNumCTE
WHERE row_num > 1

-- Display records from the NashvilleHousing table to ensure completeness and verify no duplicates remain
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress; 

-- Display records from the NashvilleHousing table to ensure completeness and verify no duplicates remain
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;
