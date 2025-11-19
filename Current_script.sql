-- MAKING TABLES --

#create data table
DROP TABLE IF EXISTS Data;
CREATE TABLE Data (
    analysis_id varchar(30) CHARACTER SET utf8mb4 NOT NULL PRIMARY KEY,
    gene_accession_id varchar(15),
    gene_symbol varchar(30),
    mouse_strain varchar(5),
    mouse_life_stage varchar(17),
    parameter_id VARCHAR(20) CHARACTER SET utf8mb4 NOT NULL,
    pvalue DOUBLE,
    parameter_name VARCHAR(255)
);


#create parameter description table
DROP TABLE IF EXISTS Parameter_Description;
CREATE TABLE Parameter_Description (
    parameter_id varchar(50) CHARACTER SET utf8mb4 NOT NULL PRIMARY KEY,
    name varchar(255),
    description varchar(320),
    IMPC_parameter_origin_id varchar(50)
);

# create phenotype procedure table
DROP TABLE IF EXISTS Phenotype_Procedure;
CREATE TABLE Phenotype_Procedure (
	IMPC_parameter_origin_id varchar(50) NOT NULL PRIMARY KEY,
	procedure_name varchar(100),
	procedure_description varchar(300),
	is_mandatory BOOLEAN
); 

DROP TABLE IF EXISTS Gene;
# create gene table
CREATE TABLE Gene (
	 gene_symbol varchar(30) NOT NULL PRIMARY KEY,
	 gene_accession_id varchar(15)
); 

DROP TABLE IF EXISTS Human_disease;
#Creating "human disease" table
create table Human_Disease(
	DO_disease_id varchar(15) not null PRIMARY KEY,
	DO_disease_name	varchar(70),
	OMIM_id varchar(300)
	); 

DROP TABLE IF EXISTS Gene_Disease_Relation;
CREATE TABLE Gene_Disease_Relation (
    gene_accession_id VARCHAR(20) NOT NULL,
    disease_id INT NOT NULL,

    PRIMARY KEY (gene_accession_id, disease_id)

    #FOREIGN KEY (gene_accession_id)
      #  REFERENCES Gene(gene_accession_id),

    #FOREIGN KEY (disease_id)
    #    REFERENCES Human_Disease(disease_id)
);




-- ADDING DATA --

#allowing data import in MySQL and DBeaver
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

SELECT @local_infile;

-- Fix all ID columns to VARCHAR on all three tables
ALTER TABLE phenotype_procedure 
MODIFY COLUMN IMPC_parameter_origin_id VARCHAR(50);

ALTER TABLE parameter_description 
MODIFY COLUMN IMPC_parameter_origin_id VARCHAR(50),
MODIFY COLUMN parameter_id VARCHAR(50);

ALTER TABLE data 
MODIFY COLUMN parameter_id VARCHAR(50);

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE data;
TRUNCATE TABLE parameter_description;
TRUNCATE TABLE phenotype_procedure;

SET FOREIGN_KEY_CHECKS = 1;


-- Lowest Level Tables -- 
#add data into lowest level tables (no foreign keys) first to allow import into the other tables

#Load data into phenotype procedure table 
#Loading data into table - They must be loaded in the correct order 
LOAD DATA LOCAL INFILE '/Users/maisievarcoe/Desktop/DCDM/Group_Project/Cleaned_procedures.csv'
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
#to deal with is_mandatory boolean class, must assign True = 1 and False = 0
SET is_mandatory = CASE UPPER(@is_mandatory)
    WHEN 'TRUE'  THEN 1
    WHEN 'FALSE' THEN 0
    ELSE NULL
END;

SELECT COUNT(*) FROM Phenotype_Procedure;
SELECT * FROM Phenotype_Procedure LIMIT 100;
 # it Worked Now 



#Load data into parameter description table 
LOAD DATA LOCAL INFILE '/Users/maisievarcoe/Desktop/DCDM/Group_Project/updated_parameter_descriptions.csv'
INTO TABLE Parameter_Description 
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    parameter_id ,   -- CSV column 1 (impcParameterOrigId)
    name,                       -- CSV column 2
    description,
    IMPC_parameter_origin_id-- CSV column 3
                   -- CSV column 4 (parameterId)
    
);

SELECT COUNT(*) FROM Parameter_Description;
SELECT * FROM Parameter_Description LIMIT 100;

delete from parameter_description  ;

#Load data into Data table 
LOAD DATA LOCAL INFILE '/Users/maisievarcoe/Desktop/DCDM/Group_Project/clean_data.csv'
INTO TABLE Data 
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
	analysis_id,
	gene_accession_id,
	gene_symbol,
	mouse_strain,
	mouse_life_stage,
	parameter_id,
	pvalue
    
);

SELECT COUNT(*) FROM Data;
SELECT * FROM Data LIMIT 100;

SELECT @@sql_mode;

ALTER TABLE Data DROP COLUMN parameter_name; 

SELECT parameter_id FROM parameter_description LIMIT 10;
SELECT parameter_id FROM data LIMIT 10;


#Load data into human disease table 
LOAD DATA LOCAL INFILE '/Users/maisievarcoe/Desktop/DCDM/Group_Project/Cleaned_disease_info.csv'
INTO TABLE Human_Disease  
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
	gene_accession_id,        -- CSV column 4 Mouse.MGI.ID
	DO_disease_id,            -- CSV column 1 (DO.Disease.ID)
	DO_disease_name,          -- CSV column 2 (DO.Disease.Name)
	OMIM_id                   -- CSV column 3 (OMIM.IDs)
   
);

#Load data into human disease table 
LOAD DATA LOCAL INFILE '/Users/maisievarcoe/Desktop/DCDM/Group_Project/Cleaned_disease_info.csv'
INTO TABLE Human_Disease  
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
	DO_disease_id,            -- CSV column 1 (DO.Disease.ID)
	DO_disease_name,          -- CSV column 2 (DO.Disease.Name)
	OMIM_id,                  -- CSV column 3 (OMIM.IDs)
	Mouse.MGI.ID #gene_accession_id         -- CSV column 4 Mouse.MGI.ID 
);



delete from Data ;



SELECT COUNT(*) FROM Phenotype_Procedure

SELECT * FROM Phenotype_Procedure pp  LIMIT 30;

delete from Parameter_Description;



SHOW COLUMNS FROM Parameter_Description;

SELECT COUNT(*) FROM Parameter_Description;








-- ADDING FOREIGN KEYS --
SELECT pd.IMPC_parameter_origin_id, COUNT(*) as orphan_count
FROM parameter_description pd
LEFT JOIN phenotype_procedure pp 
  ON pd.IMPC_parameter_origin_id = pp.IMPC_parameter_origin_id
WHERE pp.IMPC_parameter_origin_id IS NULL
GROUP BY pd.IMPC_parameter_origin_id;

ALTER TABLE Parameter_Description ADD FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES Phenotype_Procedure (IMPC_parameter_origin_id);


ALTER TABLE Data
ADD FOREIGN KEY (parameter_id)
REFERENCES Parameter_Description(parameter_id);


ALTER TABLE parameter_description 
DROP FOREIGN KEY parameter_description_ibfk_1;


ALTER TABLE Parameter_Description ADD FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES Phenotype_Procedure (IMPC_parameter_origin_id);

ALTER TABLE Data ADD FOREIGN KEY (parameter_id)
REFERENCES Parameter_Description(parameter_id);



ALTER TABLE Data ADD FOREIGN KEY (gene_symbol)
REFERENCES Gene (gene_symbol);

ALTER TABLE Data add foreign key (gene_accession_id) 
references human_disease(gene_accession_id);


