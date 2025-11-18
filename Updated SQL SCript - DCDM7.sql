
#Create all the tables 

CREATE TABLE Gene (
    gene_accession_id VARCHAR(20) NOT NULL PRIMARY KEY,
    gene_symbol       VARCHAR(50) NOT NULL
);

CREATE TABLE Phenotype_Procedure (
    IMPC_parameter_origin_id INT NOT NULL PRIMARY KEY,
    procedure_name           VARCHAR(100),
    procedure_description    VARCHAR(200),
    is_mandatory             BOOLEAN
);

CREATE TABLE Parameter_Description (
    parameter_id             VARCHAR(50) NOT NULL PRIMARY KEY,
    name                     VARCHAR(255) NOT NULL,
    description              VARCHAR(320),
    IMPC_parameter_origin_id INT
);

CREATE TABLE Human_Disease (
    disease_id      INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    DO_disease_id   VARCHAR(15),
    DO_disease_name VARCHAR(70),
    OMIM_id         VARCHAR(300),
    Mouse_MGI_ID    VARCHAR(50)
);

#p-value has changed to (double instead of varchar)
CREATE TABLE Data (
    analysis_id       INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    gene_accession_id VARCHAR(20) NOT NULL,
    gene_symbol       VARCHAR(50),
    mouse_strain      VARCHAR(20),
    mouse_life_stage  VARCHAR(50),
    parameter_id      VARCHAR(50) NOT NULL,
    pvalue            DOUBLE,
    parameter_name    VARCHAR(255)
);

CREATE TABLE Gene_Disease_Relation (
    gene_accession_id VARCHAR(20) NOT NULL,
    disease_id INT NOT NULL,
    PRIMARY KEY (gene_accession_id, disease_id)
);

CREATE TABLE Parameter_Groups (
    group_id   INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    group_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Parameter_Group_relation (
    parameter_id VARCHAR(50) NOT NULL,
    group_id INT NOT NULL, 
    PRIMARY KEY (parameter_id, group_id)
);

#Loading data into table - They must be loaded in the correct order 
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

#Didnt work because description column is data is to long for the varchar of 200 we gave. Need to alter teh varchar. 
ALTER TABLE Phenotype_Procedure
MODIFY procedure_description VARCHAR(300);

SELECT COUNT(*) FROM Phenotype_Procedure;
SELECT * FROM Phenotype_Procedure LIMIT 10;
 # it Worked Now 

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
SELECT * FROM Parameter_Description LIMIT 10;

LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Groups_of_Parameters.csv'
INTO TABLE Parameter_Groups
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@parameter_id, @category)
SET group_name = @category;

SELECT COUNT(*) FROM Parameter_Groups;
SELECT * FROM Parameter_Groups LIMIT 10;
# Above it make sense to output only the differn groups. - look at chat 

CREATE TABLE parameter_group_staging (
    parameter_id VARCHAR(50),
    category VARCHAR(100)
);

LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Groups_of_Parameters.csv'
INTO TABLE parameter_group_staging
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

INSERT INTO Parameter_Group_relation (parameter_id, group_id)
SELECT 
    s.parameter_id,
    pg.group_id
FROM 
    parameter_group_staging s
JOIN 
    Parameter_Groups pg
    ON s.category = pg.group_name;

DROP TABLE parameter_group_staging; #after this you can drop the stageing table3 

SELECT COUNT(*) FROM Parameter_Group_relation;
SELECT * FROM Parameter_Group_relation LIMIT 10;

#Above - Now PG and PRG data is linked 

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
SELECT * FROM Human_Disease LIMIT 10; #Might need to change the primary key here there are two disease_id headings 

#Only importing colomuns 1 and 2 from clean data 2 
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
# Above - It imported, just need to change it so the actual analysis id outputs 

DROP TABLE IF EXISTS Data;
CREATE TABLE Data (
    analysis_id       VARCHAR(20) NOT NULL PRIMARY KEY,  -- because the CSV analysis_id is alphanumeric
    gene_accession_id VARCHAR(20) NOT NULL,
    gene_symbol       VARCHAR(50),
    mouse_strain      VARCHAR(20),
    mouse_life_stage  VARCHAR(50),
    parameter_id      VARCHAR(50) NOT NULL,
    pvalue            DOUBLE,   #This has been changed form varchar to double. 
    parameter_name    VARCHAR(255)
);

LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /clean_data2.csv'
INTO TABLE Data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    analysis_id,
    gene_accession_id,
    gene_symbol,
    mouse_strain,
    mouse_life_stage,
    parameter_id,
    pvalue,
    parameter_name
);

SET pvalue = NULLIF(@pval, ''); #Should we add this rule. i have not run the code yet. 

#ALL data is imported, just need to add the Foreign keys. Tip: Load Data before making the Foreign keys, because it will take longer to make alterations or drop tables, if you already have a forgein key in place.
# Now Just need to add the Foreign Keys.  

#Adding the forgein keys 

#creating a foreign key between parameter description and phenotype description 
ALTER TABLE Parameter_Description ADD FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES Phenotype_Procedure (IMPC_parameter_origin_id);

#creating a foreign key (many-many)between Gene and Human Disease 
ALTER TABLE Gene_Disease_Relation 
ADD FOREIGN KEY (gene_accession_id)
REFERENCES Gene (gene_accession_id);

# creating a foreign key between data and Gene (gene accession) 
ALTER TABLE Data 
ADD FOREIGN KEY (gene_accession_id)
REFERENCES Gene(gene_accession_id);


#creating a foreign key between data and parameter description
ALTER TABLE Data
ADD FOREIGN KEY (parameter_id)
REFERENCES Parameter_Description(parameter_id);


# looking at the data
SELECT COUNT(*) FROM Parameter_Groups ;
SELECT * FROM Parameter_Groups LIMIT 10;

SELECT COUNT(*) FROM Parameter_Group_relation;
SELECT * FROM Parameter_Group_relation LIMIT 10;

DROP TABLE IF EXISTS Parameter_Group_relation; 
CREATE TABLE parameter_group_relation (
    parameter_id VARCHAR(50),
    category VARCHAR(50)
);

LOAD DATA LOCAL INFILE '/Users/ayanabdillahi/Desktop/Group4 /Groups_of_Parameters.csv'
INTO TABLE parameter_group_relation
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(parameter_id, category);

SELECT COUNT(*) FROM Parameter_Group_relation;
SELECT * FROM Parameter_Group_relation LIMIT 10;
DROP TABLE Parameter_Groups;
DROP TABLE parameter_group_staging;
