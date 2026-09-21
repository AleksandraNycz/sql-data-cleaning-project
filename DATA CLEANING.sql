-- =====================================================
-- SQL DATA CLEANING PROJECT
-- Based on a project tutorial by Alex The Analyst
-- =====================================================

-- =====================================================
-- 1. DATA PREPARATION
-- =====================================================

SELECT *
FROM layoffs;

-- Create a staging table to preserve the original dataset
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- =====================================================
-- 2. REMOVE DUPLICATES
-- =====================================================

WITH duplicate_cte AS
(
    SELECT *,
	ROW_NUMBER() OVER 
    (PARTITION BY company, location, industry,
		total_laid_off, percentage_laid_off,
		`date`, stage, country,
		funds_raised_millions
	) row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


-- Create a second staging table with row numbers 
CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    row_num INT
);

INSERT INTO layoffs_staging2
SELECT *,
	ROW_NUMBER() OVER 
		(PARTITION BY company, location, industry,
			total_laid_off, percentage_laid_off,
			`date`, stage, country,
			funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

-- Remove duplicate rows
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- =====================================================
-- 3. STANDARDIZE DATA
-- =====================================================

-- Remove unnecessary whitespace
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardize industry names
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardize country names
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- =====================================================
-- 4. STANDARDIZE DATE FORMAT
-- =====================================================

-- Convert date from text format to DATE
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- =====================================================
-- 5. HANDLE NULL AND BLANK VALUES
-- =====================================================

-- Check for missing industry values
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = '';

-- Convert blank values to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Fill missing industry values using information
-- from other records belonging to the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- =====================================================
-- 6. REMOVE UNNECESSARY ROWS
-- =====================================================

-- Remove rows where both layoff metrics are missing
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- =====================================================
-- 7. FINAL CLEANUP
-- =====================================================

-- Remove helper column used for duplicate detection
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final cleaned dataset
SELECT *
FROM layoffs_staging2;
