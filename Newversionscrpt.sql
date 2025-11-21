-- Create and Populate Base Tables --
#Create Data table
CREATE TABLE Datamain (
    analysis_id       VARCHAR(20) NOT NULL PRIMARY KEY,
    gene_accession_id VARCHAR(20) NOT NULL,
    gene_symbol       VARCHAR(50),
    mouse_strain      VARCHAR(20),
    mouse_life_stage  VARCHAR(50),
    parameter_id      VARCHAR(50) NOT NULL,
    pvalue            DOUBLE
);

#Load data into Data table
LOAD DATA LOCAL INFILE '/Users/maisievarcoe/Desktop/DCDM/Group_Project/clean_data.csv'
INTO TABLE Datamain
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  @analysis_id,
  @gene_accession_id,
  @gene_symbol,
  @mouse_strain,
  @mouse_life_stage,
  @parameter_id,
  @pvalue
)
SET
  analysis_id       = NULLIF(TRIM(@analysis_id),''),
  gene_accession_id = NULLIF(TRIM(@gene_accession_id),''),
  gene_symbol       = NULLIF(TRIM(@gene_symbol),''),
  mouse_strain      = NULLIF(TRIM(@mouse_strain),''),
  mouse_life_stage  = NULLIF(TRIM(@mouse_life_stage),''),
  parameter_id      = NULLIF(TRIM(@parameter_id),''),
  pvalue            = CASE WHEN TRIM(@pvalue) = '' THEN NULL ELSE @pvalue END;

select * from datamain 


#Create Human Disease Table
CREATE TABLE Human_Disease (
    DO_disease_id   VARCHAR(15) NOT NULL PRIMARY KEY,
    DO_disease_name VARCHAR(70),
    OMIM_id         VARCHAR(300),
    Mouse_MGI_ID    VARCHAR(50)
);

#Load data into Human Disease Table
LOAD DATA LOCAL INFILE '/Users/maisievarcoe/Desktop/DCDM/Group_Project/Cleaned_disease_info.csv'
INTO TABLE Human_Disease
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 lines;

select * from Human_Disease

#Create Parameter Description table
CREATE TABLE Parameter_Description (
    parameter_id             VARCHAR(50) NOT NULL PRIMARY KEY,
    name                     VARCHAR(255) NOT NULL,
    description              VARCHAR(320),
    IMPC_parameter_origin_id VARCHAR(320)
);

#Load data into Parameter Description table
LOAD DATA LOCAL INFILE '/Users/maisievarcoe/Desktop/DCDM/Group_Project/updated_parameter_descriptions.csv'
INTO TABLE Parameter_Description
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@csv_col1, @csv_col2, @csv_col3, @csv_col4)
SET
    parameter_id = NULLIF(TRIM(@csv_col4), ''),
    name = NULLIF(TRIM(@csv_col2), ''),
    description = NULLIF(TRIM(@csv_col3), ''),
    IMPC_parameter_origin_id = NULLIF(TRIM(@csv_col1), '');

select * from  Parameter_Description 

#Create Phenotype Procedure table
CREATE TABLE Phenotype_Procedure (
    IMPC_parameter_origin_id VARCHAR(100) NOT NULL PRIMARY KEY,
    procedure_name           VARCHAR(100),
    is_mandatory             BOOLEAN,
    procedure_description    VARCHAR(200)
    
);

#Load data into Phenotype Procedure table 
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
SET is_mandatory = CASE UPPER(@is_mandatory)
    WHEN 'TRUE'  THEN 1
    WHEN 'FALSE' THEN 0
    ELSE NULL
END;

select * from  Phenotype_Procedure


-- Create Reference Tables --
#Create IMPC Parameter ID table
CREATE TABLE IMPC_Parameter_id (
    parameter_id VARCHAR(255) PRIMARY KEY
);

#Insert data IMPC Parameter ID table
INSERT INTO impc_Parameter_id (parameter_id)
SELECT DISTINCT parameter_id
FROM (
    SELECT parameter_id FROM datamain
    UNION
    SELECT parameter_id FROM parameter_description
) AS t;

select * from  impc_Parameter_id;

DELETE from IMPC_Parameter_id;

#Create IMPC Origin ID
CREATE TABLE IMPC_origin_id (
    origin_id VARCHAR(255) PRIMARY KEY
);

#Insert data into IMPC Origin ID table 
INSERT INTO impc_origin_id (origin_id)
SELECT DISTINCT origin_id
FROM (
    select IMPC_parameter_origin_id as origin_id FROM parameter_description 
    UNION
    SELECT IMPC_parameter_origin_id  as origin_id FROM Phenotype_Procedure
) AS t;

select * from impc_origin_id

#Create MGI Acession ID table
CREATE TABLE mgi (
    mgi_id VARCHAR(255) not null primary key
  
);

#Insert data into mgi table 
INSERT INTO mgi (mgi_id)
SELECT DISTINCT gene_accession_id
FROM (
    select  gene_accession_id  FROM datamain 
    UNION
    SELECT  Mouse_MGI_ID  FROM human_disease 
) AS t;

select * from mgi


-- Foreign Keys --
ALTER TABLE parameter_description
ADD CONSTRAINT parameter_id
FOREIGN KEY (parameter_id)
REFERENCES impc_parameter_id(parameter_id);


ALTER TABLE datamain  
ADD CONSTRAINT parameter_id2
FOREIGN KEY (parameter_id)
REFERENCES impc_parameter_id(parameter_id);


ALTER TABLE  parameter_description 
ADD CONSTRAINT origin_id
FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES impc_origin_id(origin_id);

ALTER TABLE Phenotype_Procedure  
ADD CONSTRAINT origin_id2
FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES impc_origin_id(origin_id);

ALTER TABLE  datamain
ADD CONSTRAINT gene_accession_id 
FOREIGN KEY (gene_accession_id )
REFERENCES mgi (mgi_id);

ALTER TABLE human_disease 
ADD CONSTRAINT gene_accession_id2
FOREIGN KEY (Mouse_MGI_ID)
REFERENCES mgi (mgi_id);



-- Create Dependent Table, import data and add foreign key --

#Create Group Parameter table
create table Group_Parameter (
	parameter_id Varchar(50) not null primary key,
	Category Varchar(300)
)

#Load data into Group Parameter table 
LOAD DATA LOCAL INFILE '/Users/maisievarcoe/Desktop/DCDM/Group_Project/Parameter_groupings.csv'
INTO TABLE Group_Parameter
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@parameter_id, @category)
SET
  parameter_id = NULLIF(TRIM(@parameter_id),''),
  Category   = NULLIF(TRIM(@category),'');

select * from Group_Parameter

#add foreign key 
ALTER TABLE  Group_Parameter
ADD CONSTRAINT parameter_id3
FOREIGN KEY (parameter_id)
REFERENCES impc_parameter_id  (parameter_id);
