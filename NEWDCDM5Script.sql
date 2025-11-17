#create data table
CREATE TABLE Data (
    analysis_id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
    gene_accession_id varchar(15),
    gene_symbol varchar(30),
    mouse_strain varchar(5),
    mouse_life_stage varchar(17),
    parameter_id VARCHAR(20) CHARACTER SET utf8mb4 NOT NULL,
    parameter_name varchar(74),
    pvalue VARCHAR (20)
);

DROP TABLE IF EXISTS Parameter_Description;
#create parameter description table
CREATE TABLE Parameter_Description (
    parameter_id varchar(20) CHARACTER SET utf8mb4 NOT NULL PRIMARY KEY,
    name varchar(100),
    description varchar(300),
    IMPC_parameter_origin_id int(5)
);

# create phenotype procedure table
CREATE TABLE Phenotype_Procedure (

	IMPC_parameter_origin_id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
	procedure_name varchar(100),
	procedure_description varchar(200),
	is_mandatory BOOLEAN
); 

DROP TABLE IF EXISTS Query_Genes;
# create query genes table
CREATE TABLE Query_Genes (
	 gene_symbol varchar(30) NOT NULL PRIMARY KEY
); 

DROP TABLE IF EXISTS Human_disease;
#Creating "human disease" table
create table Human_Disease(
	gene_accession_id varchar(15) not null PRIMARY KEY,
	DO_disease_id varchar(15),
	DO_disease_name	varchar(70),
	OMIM_id varchar(300)
	); 



-- Add foreign keys --
ALTER TABLE Data ADD FOREIGN KEY (parameter_id)
REFERENCES Parameter_Description(parameter_id);

ALTER TABLE Parameter_Description ADD FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES Phenotype_Procedure (IMPC_parameter_origin_id);


ALTER TABLE Data ADD FOREIGN KEY (gene_symbol)
REFERENCES Query_Genes (gene_symbol);

ALTER TABLE Data add foreign key (gene_accession_id) 
references human_disease(gene_accession_id);

SHOW CREATE TABLE Query_Genes;
SHOW CREATE TABLE Data;
DROP TABLE Query_Genes; 
ALTER TABLE Data
DROP FOREIGN KEY data_ibfk_2;

CREATE TABLE Gene (
    gene_accession_id VARCHAR(20) NOT NULL PRIMARY KEY,
    gene_symbol VARCHAR(50) NOT NULL
);

ALTER TABLE Data ADD FOREIGN KEY (gene_accession_id)
REFERENCES Gene(gene_accession_id);

#creating a join table (many to many) for Gene and Human Disease
DROP TABLE IF EXISTS Human_Disease;

CREATE TABLE Human_Disease (
    disease_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    DO_disease_id VARCHAR(15),
    DO_disease_name VARCHAR(70),
    OMIM_id VARCHAR(300)
); 

ALTER TABLE Data
DROP FOREIGN KEY data_ibfk_3;

DROP TABLE IF EXISTS Gene_Disease_Relation;
CREATE TABLE Gene_Disease_Relation (
    gene_accession_id VARCHAR(20) NOT NULL,
    disease_id INT NOT NULL,

    PRIMARY KEY (gene_accession_id, disease_id),

    FOREIGN KEY (gene_accession_id)
        REFERENCES Gene(gene_accession_id),

    FOREIGN KEY (disease_id)
        REFERENCES Human_Disease(disease_id)
);

ALTER TABLE Gene
ADD INDEX (gene_symbol);

ALTER TABLE Data
ADD FOREIGN KEY (gene_symbol)
REFERENCES Gene(gene_symbol);

# Need to use numbers for the True/False in Phenotype_Description - it wont import otherwise
is_mandatory TINYINT(1) - #didnt run yet 

SELECT DISTINCT parameter_id
FROM data
WHERE parameter_id NOT IN (
    SELECT parameter_id FROM parameter_description
);

SELECT COUNT(*) FROM parameter_description;

SELECT * FROM parameter_description LIMIT 10;

#header names dont match what is on the csv sheet  
DROP TABLE IF EXISTS Parameter_Description;

CREATE TABLE Parameter_Description (
    parameter_Id VARCHAR(50) NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(320),
    impcParameterOrigId INT
);

ALTER TABLE Data
DROP FOREIGN KEY data_ibfk_1;

# Data column text length too long, need to change VARCHAR count 
ALTER TABLE Parameter_Description 
MODIFY COLUMN description VARCHAR(320);

#can't import Parameter Description because of a duplicate 

#adding foreign key 
ALTER TABLE Parameter_Description ADD FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES Phenotype_Procedure (IMPC_parameter_origin_id);

DROP TABLE IF EXISTS Parameter_Description;
DROP TABLE IF EXISTS Phenotype_Procedure;

CREATE TABLE Phenotype_Procedure (
    IMPC_parameter_origin_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    procedure_name VARCHAR(100),
    procedure_description VARCHAR(200),
    is_mandatory BOOLEAN
);

CREATE TABLE Parameter_Description (
    parameter_id VARCHAR(20) CHARACTER SET utf8mb4 NOT NULL PRIMARY KEY,
    name VARCHAR(100),
    description VARCHAR(300),
    IMPC_parameter_origin_id INT
);

#adding foreign key 
ALTER TABLE Parameter_Description ADD FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES Phenotype_Procedure (IMPC_parameter_origin_id);

-- load data parameter description data into table--
LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Cleaned_parameter_description.csv' 
INTO TABLE Parameter_Description 
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(IMPC_parameter_origin_id, name, description, parameter_id);

#errorr numbers in the two tables dont match so to check which one it is one run the codes below 

SELECT DISTINCT IMPC_parameter_origin_id
FROM Parameter_Description
WHERE IMPC_parameter_origin_id IS NOT NULL
AND IMPC_parameter_origin_id NOT IN (
    SELECT IMPC_parameter_origin_id FROM phenotype_procedure
);

SELECT DISTINCT IMPC_parameter_origin_id
FROM Parameter_Description
WHERE IMPC_parameter_origin_id IS NOT NULL
AND IMPC_parameter_origin_id NOT IN (
    SELECT IMPC_parameter_origin_id
    FROM phenotype_procedure
);

SELECT *
FROM Parameter_Description
WHERE IMPC_parameter_origin_id IS NOT NULL
AND IMPC_parameter_origin_id NOT IN (
    SELECT IMPC_parameter_origin_id
    FROM phenotype_procedure
);

SELECT *
FROM phenotype_procedure
WHERE IMPC_parameter_origin_id = 123;
# row IMPCParameterOriginId - 75540 does not exsist in 'parameter description' csv but exsits in 'phenotype procedures'csv therefor wont let me load dat till its dealt with. 

ALTER TABLE Human_Disease
ADD COLUMN Mouse_MGI_ID VARCHAR(50);

# load Human Disease data - because csv.file headers have a dot, SQL can't read that so importing data this way allows you to map the column to your chosen names.
LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Cleaned_disease_info.csv'
INTO TABLE Human_Disease
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@doid, @doname, @omim, @mgi)
SET
    DO_disease_id   = @doid,
    DO_disease_name = @doname,
    OMIM_id         = @omim,
    Mouse_MGI_ID    = @mgi;

SELECT COUNT(*) FROM Human_Disease;

#import worked,count = 2925

# view the first few rows
SELECT * FROM Human_Disease LIMIT 10;

#Delete the duplicate columns 
SHOW COLUMNS FROM Human_Disease;

ALTER TABLE Human_Disease
DROP COLUMN `DO.Disease.ID`,
DROP COLUMN `DO.Disease.Name`,
DROP COLUMN `OMIM.IDs`,
DROP COLUMN `Mouse.MGI.ID`;

#Loading into the data table, make sure p-vaule is before parameter_name as it load exactly csv is. 

LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /clean_data2.csv'
INTO TABLE Data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@acc, @sym, @strain, @stage, @pid, @pval, @pname, @analysis_id_csv)
SET
    gene_accession_id = @acc,
    gene_symbol       = @sym,
    mouse_strain      = @strain,
    mouse_life_stage  = @stage,
    parameter_id      = @pid,
    pvalue            = @pval,
    parameter_name    = @pname;

SELECT * FROM Data LIMIT 10;

SELECT COUNT(*) FROM Data;


#load data into Gene table. Only importing colomuns 1 and 2 
LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /clean_data2.csv'
INTO TABLE Gene
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@acc, @sym, @c3, @c4, @c5, @c6, @c7, @c8)
SET
    gene_accession_id = @acc,
    gene_symbol       = @sym;

SELECT COUNT(*) FROM Gene;
SELECT * FROM Gene LIMIT 10;

SELECT COUNT(*) FROM Gene_Disease_Relation;

# Load data into Phenotype table 
LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Cleaned_procedures.csv'
INTO TABLE Phenotype_Procedure
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(procedure_name, procedure_description, is_mandatory);

SELECT COUNT(*) FROM Phenotype_Procedure;
SELECT * FROM Phenotype_Procedure LIMIT 40;

#data didnt come up correctly need to add impc_parameter_origin_csv_id column for the fourth column 

ALTER TABLE Phenotype_Procedure
ADD COLUMN impc_parameter_origin_csv_id INT;

ALTER TABLE Parameter_Description
DROP FOREIGN KEY parameter_description_ibfk_1;

-- 1. Drop old table (ONLY if you want to replace it completely)
DROP TABLE IF EXISTS Phenotype_Procedure;

-- 2. Recreate table with the missing CSV ID column
CREATE TABLE Phenotype_Procedure (
    IMPC_parameter_origin_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    procedure_name VARCHAR(100),
    procedure_description VARCHAR(500),
    is_mandatory BOOLEAN,
    impc_parameter_origin_csv_id INT         -- <-- THIS stores 37882, 37883, etc.
);

-- 3. Load CSV data (adjust the file path if needed)
LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Cleaned_procedures.csv'
INTO TABLE Phenotype_Procedure
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    procedure_name,                -- CSV column 1: name
    procedure_description,         -- CSV column 2: description
    is_mandatory,                  -- CSV column 3: isMandatory
    impc_parameter_origin_csv_id   -- CSV column 4: impcParameterOriginId
);

-- 4. View first rows
SELECT * FROM Phenotype_Procedure LIMIT 20;

LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Cleaned_parameter_description.csv'
INTO TABLE Parameter_Description
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    IMPC_parameter_origin_id,   -- CSV column 1 (impcParameterOrigId)
    name,                       -- CSV column 2
    description,                -- CSV column 3
    parameter_id                -- CSV column 4 (parameterId)
);

SELECT COUNT(*) FROM Parameter_Description;
SELECT * FROM Parameter_Description LIMIT 20;

SELECT IMPC_parameter_origin_id
FROM Parameter_Description
WHERE IMPC_parameter_origin_id NOT IN (
    SELECT IMPC_parameter_origin_id FROM Phenotype_Procedure
);

SELECT *
FROM Parameter_Description
WHERE IMPC_parameter_origin_id NOT IN (
    SELECT IMPC_parameter_origin_id FROM Phenotype_Procedure
);
# Trying to make a foreign key for PD and PhP, it states the ID don't match so i can make a foreign key. Tyring to see the data ranges of both tables  
SELECT MIN(IMPC_parameter_origin_id), MAX(IMPC_parameter_origin_id)
FROM Phenotype_Procedure;

SELECT MIN(IMPC_parameter_origin_id), MAX(IMPC_parameter_origin_id)
FROM Parameter_Description;

# i have a duplicate column in my phenotype table. Need to get rid of one 
DROP TABLE IF EXISTS Phenotype_Procedure;
CREATE TABLE Phenotype_Procedure (
    IMPC_parameter_origin_id INT PRIMARY KEY,   -- <-- REAL IMPC ID
    procedure_name VARCHAR(100),
    procedure_description VARCHAR(200),
    is_mandatory BOOLEAN
);
#load data back into phenotype table 
LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Cleaned_procedures.csv'
INTO TABLE Phenotype_Procedure
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(procedure_name, procedure_description, is_mandatory, IMPC_parameter_origin_id);

#Didnt load because of the TRUE/FALSE, Need to change this to 1/0. We can do this in SQL 
LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Cleaned_procedures.csv'
INTO TABLE Phenotype_Procedure
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    procedure_name,                 -- name
    procedure_description,          -- description
    @is_mandatory,                  -- isMandatory (text: TRUE/FALSE)
    IMPC_parameter_origin_id        -- impcParameterOrigId
)
SET is_mandatory = CASE UPPER(@is_mandatory)
    WHEN 'TRUE'  THEN 1
    WHEN 'FALSE' THEN 0
    ELSE NULL
END;

SELECT COUNT(*) FROM Phenotype_Procedure;
SELECT * FROM Phenotype_Procedure LIMIT 20;

#it's showing the data in the wrong order (correct data) check this first. fix it 
SELECT *
FROM Phenotype_Procedure
ORDER BY IMPC_parameter_origin_id;

# the results of the code below produces an empty tabel output, this is teh same as zero meaning IMPC_parameter_origin_id's match in pd and php. can now create a foreign key between them.
SELECT IMPC_parameter_origin_id
FROM Parameter_Description
WHERE IMPC_parameter_origin_id NOT IN (
    SELECT IMPC_parameter_origin_id FROM Phenotype_Procedure
);

#creating a foreign key between pd and php 
ALTER TABLE Parameter_Description
ADD FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES Phenotype_Procedure(IMPC_parameter_origin_id);

#creatign a foreing key between data and PD. there doesn't seen to be one in my codes 
SELECT parameter_id
FROM Data
WHERE parameter_id NOT IN (
    SELECT parameter_id FROM Parameter_Description
);

ALTER TABLE Data
ADD FOREIGN KEY (parameter_id)
REFERENCES Parameter_Description(parameter_id);
#this did not work - because there is a row in Data whose parameter_id does not exist in Parameter_Description, so I cannot link them.”

# creating a new gene table so we dont need to add all 33k and just use the unique ones 
DROP TABLE IF EXISTS Gene;
CREATE TABLE Gene (
    gene_accession_id VARCHAR(20) NOT NULL PRIMARY KEY,
    gene_symbol VARCHAR(50) NOT NULL
);
ALTER TABLE Gene_Disease_Relation
DROP FOREIGN KEY gene_disease_relation_ibfk_1;

ALTER TABLE Data
DROP FOREIGN KEY data_ibfk_4;

ALTER TABLE Data
DROP FOREIGN KEY data_ibfk_5;



INSERT INTO Gene (gene_accession_id, gene_symbol)
SELECT DISTINCT gene_accession_id, gene_symbol
FROM data;

#to check it worked 
SELECT COUNT(*) FROM Gene;
SELECT * FROM Gene LIMIT 20;

SELECT DISTINCT gene_accession_id, gene_symbol
FROM Data;

SELECT COUNT(DISTINCT gene_accession_id, gene_symbol) AS unique_gene_count
FROM Data;
#this (above)is telling me there are 100 distinc genes

# adding back the forein keys 
ALTER TABLE Gene_Disease_Relation 
ADD FOREIGN KEY (gene_accession_id)
REFERENCES Gene (gene_accession_id);

ALTER TABLE Data 
ADD FOREIGN KEY (gene_accession_id)
REFERENCES Gene(gene_accession_id);

ALTER TABLE Data 
ADD FOREIGN KEY (gene_symbol)
REFERENCES Gene(gene_symbol);

SHOW CREATE TABLE Gene;

ALTER TABLE Gene
ADD PRIMARY KEY (gene_accession_id);

ALTER TABLE Data
ADD FOREIGN KEY (gene_symbol)
REFERENCES Gene(gene_symbol);

