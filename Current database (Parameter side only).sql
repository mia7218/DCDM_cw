#Database creation and using it
create database dcdmlocal5;
use DCDMLocal5;


#Creating and adding data for Datamain table
-- creating the table
CREATE TABLE Datamain (
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
LOAD DATA LOCAL INFILE 'path/to/file/clean_data.csv'
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
  pvalue            = CASE WHEN TRIM(@pvalue) = '' THEN NULL ELSE @pvalue END,
  parameter_name    = NULLIF(TRIM(@parameter_name),'');


#Creating and adding data for parameter_description table
-- Creating the table
CREATE TABLE parameter_description (
    parameter_id             VARCHAR(50) NOT NULL PRIMARY KEY,
    name                     VARCHAR(255) NOT NULL,
    description              VARCHAR(320),
    IMPC_parameter_origin_id VARCHAR(320)
);

-- Adding the data
LOAD DATA LOCAL INFILE 'path/to/file/updated_parameter_descriptions.csv'
INTO TABLE  Parameter_Description 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n\r'
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
	IMPC_parameter_origin_id = nullif(trim(@impcParameterOrigId),'');

-- Updates NAs to null in SQL to allow the creation of the PK-FK releationship (phenotype_procedures to parameter_description)
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
LOAD DATA LOCAL INFILE 'path/to/file/Cleaned_procedures.csv '
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
    WHEN 'TRUE'  THEN 1 #Indicating that true =1 and False =0
    WHEN 'FALSE' THEN 0
    ELSE NULL
END;


#Creating and adding data for phenotype_procedure table
-- creating the table
create table group_parameter (
	Id int  auto_increment not null primary key,
	parameter_id Varchar(50) not null,
	Category Varchar(300)
);

-- adding the data
LOAD DATA LOCAL INFILE 'path/to/file/Parameter_groupings.csv'
INTO TABLE Group_Parameter
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@parameter_id, @category)
SET
  parameter_id = NULLIF(TRIM(@parameter_id),''),
  Category   = NULLIF(TRIM(@category),'');



#Final, adding the foreign key relationships

-- Adding foreign key between parameter_description and phenotype_procedure
ALTER TABLE parameter_description
ADD CONSTRAINT IMPC_parameter_origin_id_fk
	FOREIGN KEY (IMPC_parameter_origin_id) 
	REFERENCES phenotype_procedure(IMPC_parameter_origin_id);
 

-- Adding foreign key between parameter_description and group parameter
ALTER TABLE Group_Parameter
ADD CONSTRAINT groupings_fk
	FOREIGN KEY (parameter_id) 
	REFERENCES parameter_description(parameter_id);

-- Adding foreign key between datamain and parmeter_description
ALTER TABLE datamain
ADD CONSTRAINT straightparameter_fk
	FOREIGN KEY (parameter_id) 
	REFERENCES parameter_description(parameter_id);


#My current query set up 
select datamain.analysis_id, datamain.pvalue, datamain.gene_symbol, datamain.mouse_life_stage, datamain.parameter_id, parameter_description.name as parameter_name, group_parameter.Category as parameter_groupings, phenotype_procedure.procedure_name, human_disease.DO_disease_name, human_disease.OMIM_id, phenotype_procedure.is_mandatory      
	from dcdmlocal6.datamain
	left join group_parameter on datamain.parameter_id = group_parameter.parameter_id
	left join parameter_description on datamain.parameter_id = parameter_description.parameter_id
	left join phenotype_procedure on parameter_description.IMPC_parameter_origin_id = phenotype_procedure.IMPC_parameter_origin_id
	left join mgi on datamain.gene_accession_id = mgi.mgi_id
	left join human_disease on mgi.mgi_id = human_disease.Mouse_MGI_ID
where dcdmlocal6.datamain.gene_symbol = 'Fam72a'; -- changing the query genes makes not difference to missing outputs


#Current thinking for fix
-- Might need to put the genes_symbols in the same table as all of the MGI ids as this groups them together. 
-- Not entirely sure though







