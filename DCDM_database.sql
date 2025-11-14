#create data table
CREATE TABLE Data (
    analysis_id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
    gene_accession_id varchar(15),
    gene_symbol varchar(30),
    mouse_strain varchar(5),
    mouse_life_stage varchar(17),
    parameter_id varchar (20),
    parameter_name varchar(74),
    pvalue varchar (20)
); 

#create parameter description 
CREATE TABLE Parameter_Description (
    parameter_id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name varchar(100),
    description varchar(300),
    origin_id int(5)
); 

#create phenotype procedure table
CREATE TABLE Phenotype_Procedure (

	IMPC_parameter_origin_id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
	procedure_name varchar(100),
	procedure_description varchar(200),
	is_mandatory BOOLEAN
); 


#create query genes table
CREATE TABLE Query_Genes (
	 gene_symbol int NOT NULL PRIMARY KEY AUTO_INCREMENT
	
);

#Creating "human disease" table
create table "Human_disease"(
	gene_association_id varchar(15) not null PRIMARY KEY,
	DO_disease_id varchar(15),
	DO_disease_name	varchar(70),
	OMIM_id varchar(300)
	); 

















# put the first row of data into the Gene table
INSERT INTO Gene (gene_symbol, name, cosmic_gene_id, chromosome, genome_start, genome_stop, molecular_genetics) 
VALUES ("A1CF", "APOBEC1 complementation factor", "COSG46891", "10", 52559169, 52645435, "Dom"); 
#second row of data
INSERT INTO Gene (gene_symbol, name, cosmic_gene_id, chromosome, genome_start, genome_stop, molecular_genetics) 
VALUES ("ABI1", "abl interactor 1",	"COSG5120",	"10",	27035522,	27150016,	"Dom"); 
#third row
INSERT INTO Gene (gene_symbol, name, cosmic_gene_id, chromosome, genome_start, genome_stop, molecular_genetics) 
VALUES ("ABL1",	"ABL proto-oncogene 1, non-receptor tyrosine kinase",	"COSG4968",	"9", 133589333, 133763062,	"Rec"); 
#fourth row
INSERT INTO Gene (gene_symbol, name, cosmic_gene_id, chromosome, genome_start, genome_stop, molecular_genetics) 
VALUES ("ABL2",	"ABL proto-oncogene 2, non-receptor tyrosine kinase",	"COSG36573",	"1",	179068462,	179198819,	"Dom");

Select * from Gene;
Select * from Gene where chromosome = 10;

Select gene_id, gene_symbol, name, molecular_genetics from Gene where molecular_genetics = "Dom";
Select gene_id, gene_symbol, name, molecular_genetics from Gene where genome_start > 27150016 and genome_start < 57150016;

select distinct molecular_genetics from Gene; 

