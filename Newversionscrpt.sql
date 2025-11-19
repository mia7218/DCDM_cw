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

LOAD DATA LOCAL INFILE 'E:/桌面/Group4/clean_data.csv'
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

select * from datamain 


CREATE TABLE Human_Disease (
    DO_disease_id   VARCHAR(15) NOT NULL PRIMARY KEY,
    DO_disease_name VARCHAR(70),
    OMIM_id         VARCHAR(300),
    Mouse_MGI_ID    VARCHAR(50)
);



LOAD DATA LOCAL INFILE 'E:/桌面/Group4/Cleaned_disease_info.csv'
INTO TABLE Human_Disease
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 lines;


select * from Human_Disease



CREATE TABLE Parameter_Description (
    parameter_id             VARCHAR(50) NOT NULL PRIMARY KEY,
    name                     VARCHAR(255) NOT NULL,
    description              VARCHAR(320),
    IMPC_parameter_origin_id VARCHAR(320)
);

LOAD DATA LOCAL INFILE 'E:/桌面/Group4/updated_parameter_descriptions.csv'
INTO TABLE  Parameter_Description 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 lines;

select * from  Parameter_Description 



CREATE TABLE Phenotype_Procedure (
    IMPC_parameter_origin_id VARCHAR(100) NOT NULL PRIMARY KEY,
    procedure_name           VARCHAR(100),
    is_mandatory             BOOLEAN,
    procedure_description    VARCHAR(200)
    
);


LOAD DATA LOCAL INFILE 'E:/桌面/Group4/Cleaned_procedures.csv '
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


CREATE TABLE IMPC_Parameter_id (
    parameter_id VARCHAR(255) PRIMARY KEY
);


INSERT INTO impc_Parameter_id (parameter_id)
SELECT DISTINCT parameter_id
FROM (
    SELECT parameter_id FROM datamain
    UNION
    SELECT IMPC_parameter_origin_id AS parameter_id FROM parameter_description
) AS t;

select * from  impc_Parameter_id 


ALTER TABLE parameter_description 
ADD CONSTRAINT IMPC_parameter_origin_id
FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES impc_parameter_id(parameter_id);


ALTER TABLE datamain  
ADD CONSTRAINT parameter_id
FOREIGN KEY (parameter_id)
REFERENCES impc_parameter_id(parameter_id);



CREATE TABLE IMPC_origin_id (
    origin_id VARCHAR(255) PRIMARY KEY
);


INSERT INTO impc_origin_id (origin_id)
SELECT DISTINCT origin_id
FROM (
    select IMPC_parameter_origin_id as origin_id FROM parameter_description 
    UNION
    SELECT IMPC_parameter_origin_id  as origin_id FROM Phenotype_Procedure
) AS t;

select * from impc_origin_id


ALTER TABLE  parameter_description 
ADD CONSTRAINT origin_id
FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES impc_origin_id(origin_id);

ALTER TABLE Phenotype_Procedure  
ADD CONSTRAINT origin_id2
FOREIGN KEY (IMPC_parameter_origin_id)
REFERENCES impc_origin_id(origin_id);


CREATE TABLE mgi (
    mgi_id VARCHAR(255) not null primary key
  
);


INSERT INTO mgi (mgi_id)
SELECT DISTINCT gene_accession_id
FROM (
    select  gene_accession_id  FROM datamain 
    UNION
    SELECT  Mouse_MGI_ID  FROM human_disease 
) AS t;


select * from mgi

ALTER TABLE  datamain
ADD CONSTRAINT gene_accession_id 
FOREIGN KEY (gene_accession_id )
REFERENCES mgi (mgi_id);

ALTER TABLE human_disease 
ADD CONSTRAINT gene_accession_id2
FOREIGN KEY (Mouse_MGI_ID)
REFERENCES mgi (mgi_id);

create table Group_Parameter (
	parameter_id Varchar(50) not null primary key,
	Category Varchar(300)
)


LOAD DATA LOCAL INFILE 'E:/桌面/Group4/Parameter_groupings.csv'
INTO TABLE Group_Parameter
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@parameter_id, @category)
SET
  parameter_id = NULLIF(TRIM(@parameter_id),''),
  Category   = NULLIF(TRIM(@category),'');


ALTER TABLE  Group_Parameter
ADD CONSTRAINT parameter_id
FOREIGN KEY (parameter_id )
REFERENCES impc_parameter_id  (parameter_id);

select * from Group_Parameter
















