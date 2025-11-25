
#Database creation and using it
create database dcdmcw;
use dcdmcw;


#Creating and adding data for Datamain table
-- creating the table
CREATE TABLE datamain (
    analysis_id       VARCHAR(20) NOT NULL PRIMARY KEY,
    gene_accession_id VARCHAR(20) NOT NULL,
    gene_symbol       VARCHAR(50),
    mouse_strain      VARCHAR(20),
    mouse_life_stage  VARCHAR(50),
    parameter_id      VARCHAR(50) NOT NULL,
    pvalue            DOUBLE,
    parameter_name    VARCHAR(255)
);

-- adding the data
LOAD DATA LOCAL INFILE 'Path/To/File/clean_data.csv'
INTO TABLE datamain
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
  @pvalue,
  @parameter_name
)
SET
  analysis_id       = NULLIF(TRIM(@analysis_id),''),
  gene_accession_id = NULLIF(TRIM(@gene_accession_id),''),
  gene_symbol       = NULLIF(TRIM(@gene_symbol),''),
  mouse_strain      = NULLIF(TRIM(@mouse_strain),''),
  mouse_life_stage  = NULLIF(TRIM(@mouse_life_stage),''),
  parameter_id      = NULLIF(TRIM(@parameter_id),''),
  pvalue            = CASE WHEN TRIM(@pvalue) = '' or UPPER(TRIM(@pvalue)) = 'NA' THEN NULL ELSE @pvalue END, -- This condition ensures that NAs in the CSV file are converted to nulls in SQL 
  parameter_name    = NULLIF(TRIM(@parameter_name),''
);


#Creating and adding data for parameter_description table
-- Creating the table
CREATE TABLE parameter_description (
    parameter_id             VARCHAR(50) NOT NULL PRIMARY KEY,
    name                     VARCHAR(255) NOT NULL,
    description              VARCHAR(320),
    IMPC_parameter_origin_id VARCHAR(320)
);

-- Adding the data
LOAD DATA LOCAL INFILE 'Path/To/File/updated_parameter_descriptions.csv'
INTO TABLE  parameter_description 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' -- Sometimes the data import needs a -r depending on CSV origin, check data has imported after running
IGNORE 1 lines
(@impcParameterOrigId,
@name,
@description, 
@parameterId
)
set
	parameter_Id = nullif(trim(@parameterId),''),
	name = nullif(trim(@name),''),
	description = nullif(trim(@description),''),
	IMPC_parameter_origin_id = nullif(trim(@impcParameterOrigId),''
);

-- Updating NAs to null in IMPC_parameter_origin_id column of parameter_description table to allow the creation of the PK-FK releationship (phenotype_procedures to parameter_description)
update parameter_description set IMPC_parameter_origin_id = null where IMPC_parameter_origin_id = 'NA'; 


#Creating and adding data for phenotype_procedure table
-- Creating the table
CREATE TABLE phenotype_procedure (
    IMPC_parameter_origin_id VARCHAR(320) NOT NULL PRIMARY KEY,
    procedure_name           VARCHAR(100),
    is_mandatory             BOOLEAN,
    procedure_description    VARCHAR(200)
);

-- Adding the data in
LOAD DATA LOCAL INFILE 'Path/To/File/Cleaned_procedures.csv '
INTO TABLE phenotype_procedure
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
    WHEN 'TRUE'  THEN 1 #Indicating that true =1 and False =0
    WHEN 'FALSE' THEN 0
    ELSE NULL
end;


#Creating and adding data for group_parameter table
-- creating the table
create table group_parameter (
	Id int  auto_increment not null primary key,
	parameter_id Varchar(50) not null,
	Category Varchar(300)
);

-- adding the data
LOAD DATA LOCAL INFILE 'Path/To/File/Parameter_groupings.csv'
INTO TABLE group_parameter
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@parameter_id, @category)
SET
  parameter_id = NULLIF(TRIM(@parameter_id),''),
  Category   = NULLIF(TRIM(@category),''
);


# Adding the foreign key relationships, for Parameter/Procedure side

-- Adding foreign key between parameter_description and phenotype_procedure
ALTER TABLE parameter_description
ADD CONSTRAINT IMPC_parameter_origin_id_fk
	FOREIGN KEY (IMPC_parameter_origin_id) 
	REFERENCES phenotype_procedure(IMPC_parameter_origin_id);
 
-- Adding foreign key between parameter_description and group parameter
ALTER TABLE group_parameter
ADD CONSTRAINT groupings_fk
	FOREIGN KEY (parameter_id) 
	REFERENCES parameter_description(parameter_id);

-- Adding foreign key between datamain and parmeter_description
ALTER TABLE datamain
ADD CONSTRAINT straightparameter_fk
	FOREIGN KEY (parameter_id) 
	REFERENCES parameter_description(parameter_id);

#Dealing with the disease info side of the database
#Creating the disease info table and adding the data
-- creating the table itself
CREATE TABLE disease_info (
    Id int auto_increment primary key,
	DO_disease_id   VARCHAR(30),
    DO_disease_name VARCHAR(100),
    OMIM_id         VARCHAR(300),
    Mouse_MGI_ID    VARCHAR(50)
);

-- adding in the data
LOAD DATA LOCAL INFILE 'Path/To/File/Cleaned_disease_info.csv'
INTO TABLE disease_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' #sometimes have to use a -r depending on the origin of the CSV
IGNORE 1 lines
(DO_disease_id, DO_disease_name, OMIM_id, Mouse_MGI_ID); -- Adding this line ensures that the data is added into the correct columns, especially with the Id column

#Creation of the joining table "all_genes" and adding the data
-- creating the all_genes table
create table all_genes(
	gene_accession_id varchar(100) not null primary key,
	gene_symbol varchar(100)
);

-- Adding the data into the all_genes table
INSERT INTO all_genes (gene_accession_id)
SELECT DISTINCT gene_accession_id
FROM (
    select  gene_accession_id  FROM datamain 
    UNION
    SELECT  Mouse_MGI_ID  from disease_info 
) AS t;

-- Inspecting the current all_genes table, looking at values, counts and nulls
select * from all_genes; -- currently gene_symbol is completely null
select count(gene_accession_id) from dcdmCW.all_genes; -- 2551 total, if not 2551 code has been executed wrong
select count(distinct gene_accession_id) from dcdmCW.all_genes; -- 2,551 total
-- Can rerun these counts again to ensure that totals stay the same

-- Getting the gene_symbol information from the datamain table into the all_genes column
-- This was done to keep gene information (gene accession ids and gene symbol) together in a single table 
UPDATE all_genes INNER JOIN datamain 
ON all_genes.gene_accession_id = datamain.gene_accession_id 
SET all_genes.gene_symbol = datamain.gene_symbol; 

-- To eliminate redundancy we now need to remove the gene_symbol column from the datamain table
alter table datamain
	drop column gene_symbol;

#Now adding the foregin keys to the disease info side of the database
-- adding Pk-Fk relationship between All_genes joining table and disease_info table
ALTER TABLE disease_info 
ADD CONSTRAINT gene_accession_id_to_mouse
FOREIGN KEY (Mouse_MGI_ID)
REFERENCES all_genes (gene_accession_id);


-- adding Pk-Fk relationship between All_genes joining table and datamain table
ALTER TABLE datamain 
ADD CONSTRAINT gene_accession_id_to_datamain
FOREIGN KEY (gene_accession_id)
REFERENCES all_genes (gene_accession_id);


#Updated final query  
select datamain.analysis_id as 'Analysis Id', datamain.pvalue as 'P-Value', all_genes.gene_symbol as 'Gene Symbol', datamain.mouse_life_stage as 'Mouse Life Stage', datamain.mouse_strain as 'Mouse Strain', datamain.parameter_id as 'Parameter Id', parameter_description.name as 'Parameter Name', group_parameter.Category as 'Parameter Grouping', phenotype_procedure.procedure_name as 'Procedure Name', disease_info.DO_disease_name as 'DO Disease Name', disease_info.OMIM_id as 'OMIM Id', phenotype_procedure.is_mandatory as 'Mandatory Procedure' -- 'As' to rename columns for clarity    
	from dcdmCW.all_genes
	inner join datamain on all_genes.gene_accession_id = datamain.gene_accession_id -- Using inner join guarentees that retrieved have an associated result/phenotype entry
	left join disease_info on all_genes.gene_accession_id  = disease_info.Mouse_MGI_ID
	left join parameter_description on parameter_description.parameter_id = datamain.parameter_id
	left join phenotype_procedure on phenotype_procedure.IMPC_parameter_origin_id = parameter_description.IMPC_parameter_origin_id
	left join group_parameter on group_parameter.parameter_id = parameter_description.parameter_id
where dcdmCW.all_genes.gene_symbol = 'Query gene'; -- Group 4 Query genes; Fam72a, Larp6, Ap2s1, Tm4sf19

-- Null return values in the "Procedure Name" column are caused by non-IMPC procedures/parameters, as no information on procedure names are given for these
-- Null return values in the "Mandatory Procedure" column are caused by non-IMPC results which do not indicate if procedures are mandatory
-- A Null return in both "DO Disease Name" and "OMIM Id" are a result of that gene symbol not being associated with a disease in our metadata
-- NA values in the P-value column indicate that a value of either 1 or 0 was calcualted which is a mathimatical impossibility
