# Mobile Phone Data Cleaning & Transformation Project using SQL Server
 
## Project Overview
 
This project showcases the practical application of **Data Cleaning** and **Feature Engineering** skills using **Transact-SQL (T-SQL)** within a **SQL Server** environment.
 
The core objective was to transform a raw, inconsistent dataset detailing mobile phone specifications into a **clean**, **standardized**, and **analysis-ready** final table. The project demonstrates advanced techniques to handle missing data and parse complex strings.
 
 
---
 
## Key Challenges Addressed
 
1. **Data Integrity & Duplicate Removal:**
    * Identifying and deleting **true product duplicates** based on the combination of `brand_name` and `model_name`.
    * Imputing missing categorical data (`os`) with 'Unknown'.
 
2. **Robust Missing Data Imputation:**
    * Calculating and utilizing the **Median** (`PERCENTILE_CONT(0.5)`) to fill missing price and memory values, effectively mitigating the influence of price outliers.
    * Excluding rows with missing critical physical specifications (`screen_size`, `battery_size`) to maintain data quality.
 
3. **Complex Feature Engineering (String Parsing):**
    * Extracting detailed, granular information (like **RAM Size** and **Phone Color**) hidden within the complex `model_name` string field. This required highly specific and prioritized `CASE WHEN` logic to cover various naming conventions (e.g., `X/YGB` fraction pattern).
 
---
 
## Methodology & Advanced SQL Techniques
 
The project was structured into logical, sequential steps, utilizing professional T-SQL constructs to ensure clean, maintainable, and highly readable code.
 
### 1. Data Auditing and Cleanup
* **Median Calculation:** Utilizing `DECLARE` variables to store the calculated Median for price and memory, enhancing the performance and efficiency of the subsequent `UPDATE` operations.
 
### 2. Feature Persistence (The UPDATE JOIN)
This step is the heart of the project, showcasing proficiency in advanced data transformation:
* **Feature Extraction (CTE):** A single **Common Table Expression (`FeatureExtraction`)** calculates the new features (`Calculated_RAM_Size` and `Calculated_Phone_Color`).
* **Update Join:** The results of the CTE are persisted (saved) back into the main `phones` table using an efficient `UPDATE...JOIN` statement, which is the professional standard for this task.
 
---
 
## Project Deliverables
 
The final output is a structured dataset featuring several newly created and cleaned columns, ready for BI tool visualization or further statistical analysis:
 
| Column | Source Field | Transformation Applied | Description of Extracted Value |
| :--- | :--- | :--- | :--- |
| **`RAM_Size`** | `model_name` | `CASE WHEN / LIKE` | Standardized RAM size (e.g., '4GB', '8GB'). |
| **`Phone_Color`** | `model_name` | `CASE WHEN / LIKE` | Extracted color (e.g., 'Black', 'Blue', 'Unknown'). |
| `os` | `os` | `UPDATE...SET 'Unknown'` | Missing OS values filled. |
| `lowest_price` | `lowest_price` | Imputation by Median | Missing prices filled with the robust Median value. |
| `release_date` | `release_date` | `CONVERT(DATE, ...)` | Transformed into a usable Date format. |
