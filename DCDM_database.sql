#create data table
CREATE TABLE Data (
    analysis_id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
    gene_accession_id varchar(15),
    gene_symbol varchar(30),
    mouse_strain varchar(5),
    mouse_life_stage varchar(17),
    parameter_id VARCHAR(20) CHARACTER SET utf8mb4 NOT NULL,
    parameter_name varchar(74),
    pvalue varchar (20),
);


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
