-- Data Cleaning

SELECT *
FROM layoffs
;

#1 Remove duplicats (if any)
#2 Standardize the Data (np. spelling)
#3 NULL values or blank values
#4 Remove unnecessary rows or columns (nic nie wnoszące może lepiej nazwane)

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging
;

INSERT layoffs_staging
SELECT *
FROM layoffs
;

#1 Remove duplicats (if any)
SELECT *,
ROW_NUMBER () OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) row_num
FROM layoffs_staging
;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER () OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1
;

SELECT *
FROM layoffs_staging
WHERE company = 'Cazoo'
;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER () OVER
(PARTITION BY company, location, industry, 
total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1
;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2
;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER () OVER
(PARTITION BY company, location, industry, 
total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) row_num
FROM layoffs_staging
;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1
;

DELETE
FROM layoffs_staging2
WHERE row_num > 1
;

SELECT *
FROM layoffs_staging2
;

#2 Standardize the Data (np. spelling, jedna rzecz napisana na kilka sposobów, itp itd)
SELECT company, TRIM(company)
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET company = TRIM(company)
;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'
;

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1
;

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

-- ig ze tak tez mozna ale robimy nowa metoda, i tez to dziala konkretnie n a US, a nie ogolnie
#UPDATE layoffs_staging2
#SET country = 'United States'
#WHERE country LIKE 'United States%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1
;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- ZMIANA FORMATU DATY !!!! (text -> date)
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
;

SELECT `date`
FROM layoffs_staging2
;

#Zmiana typu danych w tabelce, ale rób takie rzeczy tylko twoich tabelkach
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

#3 NULL values or blank values
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''
;

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%'
;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''
;

# ig ze tak jednak nie mozna ale idk, moze wrocimy 
# bo jednak to działa tylko da konkretnego a nie ogólnie
#UPDATE layoffs_staging2
#SET industry = 'Travel'
#WHERE company = 'Airbnb';

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL or t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
;

#4 Remove unnecessary rows or columns (nic nie wnoszące może lepiej nazwane)
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;

#deleting columns
SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


