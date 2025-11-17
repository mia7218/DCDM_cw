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

# load Human Disease data - because csv heading have dot SQL can read that so importing this way allows you to map the column to your chosen names.
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

#Loading into teh data table, make sure p-vaule is before parameter_name as it load exactly csv is. 

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

SELECT LOAD_FILE('/');
SELECT LOAD_FILE('/Users/ayanabdillahi/Desktop/Group4/clean_data2.csv');
SHOW VARIABLES LIKE 'local_infile';
SELECT LOAD_FILE('/Users/ayanabdillahi/Desktop/Group4 /clean_data2.csv');