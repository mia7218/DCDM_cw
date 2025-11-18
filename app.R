library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)
library(DT)
library(data.table)
library(pheatmap)


# Load data
mouse_data <- read.csv("clean_data.csv", stringsAsFactors = FALSE)


ui <- dashboardPage(
  dashboardHeader(title = "IMPC Gene Phenotype Explorer"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("1. KO Mouse by Gene", tabName = "bygene", icon = icon("dna")),
      menuItem("2. KO Mouse by Phenotype", tabName = "byphenotype", icon = icon("vial")),
      menuItem("3. Gene Clusters", tabName = "gene_clusters", icon = icon("project-diagram"))
    )
  ),
  
  dashboardBody(
    tabItems(
      
      # Tab 1: KO by Gene
      tabItem(tabName = "bygene",
              fluidRow(
                box(width = 4,
                    selectInput("select_gene", "Select KO Mouse Gene:",
                                choices = c("All Genes", sort(unique(mouse_data$gene_symbol))),
                                selected = "All Genes"),
                    uiOutput("phenotype_dropdown"),
                    sliderInput("gene_pval", "p-value Threshold",
                                min = 0, max = 1, value = 0.05, step = 0.01)
                ),
                box(width = 8, title = "Bubble Chart: Statistical Scores",
                    plotlyOutput("gene_bubble", height = "500px"))
              ),
              fluidRow(
                box(width = 12, title = "Significant Phenotypes for Selected Gene",
                    DTOutput("sig_table_gene"))
              )
      ),
      
      # Tab 2: KO by Phenotype
      tabItem(tabName = "byphenotype",
              fluidRow(
                box(width = 4,
                    selectInput("select_phenotype", "Select Phenotype:",
                                choices = c("All Phenotypes", sort(unique(mouse_data$parameter_name))),
                                selected = "All Phenotypes"),
                    uiOutput("gene_dropdown"),
                    sliderInput("phenotype_pval", "p-value Threshold",
                                min = 0, max = 1, value = 0.05, step = 0.01)
                ),
                box(width = 8, title = "Bubble Chart: Statistical Scores",
                    plotlyOutput("phenotype_bubble", height = "500px"))
              ),
              fluidRow(
                box(width = 12, title = "Significant Knockouts for Selected Phenotype",
                    DTOutput("sig_table_phenotype"))
              )
      ),
      
      # Tab 3: Gene Clusters
      tabItem(tabName = "gene_clusters",
              h2("Clusters of Genes with Similar Phenotype Scores"),
              sidebarLayout(
                sidebarPanel(
                  numericInput("clusters", "Number of clusters:",
                               value = 6, min = 2, max = 20),
                  helpText("Genes are clustered based on –log10(p-values) across all phenotypes.")
                ),
                mainPanel(
                  plotlyOutput("clusterPlot", height = "600px"),
                  br(),
                  h3("Genes in Selected Cluster"),
                  h4("Click on a cluster to identify genes"),
                  DTOutput("cluster_table"),   # <-- MISSING OUTPUT!
                  br(),
                  uiOutput("cluster_gene_lists")
                )
              )
      )
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {
  
  
  # Bubble Chart: KO by Gene 
  output$gene_bubble <- renderPlotly({
    df <- mouse_data
    if(input$select_gene != "All Genes") df <- df %>% filter(gene_symbol == input$select_gene)
    if(!is.null(input$select_gene_pheno) && input$select_gene_pheno != "All")
      df <- df %>% filter(parameter_name == input$select_gene_pheno)
    
    df$pvalue[df$pvalue == 0] <- 1e-50
    df$Significant <- factor(ifelse(df$pvalue < input$gene_pval, "Significant", "Not Significant"),
                             levels = c("Not Significant", "Significant"))
    df$tooltip <- paste0(
      "KO Mouse: ", df$analysis_id,
      "<br>p-value: ", signif(df$pvalue, 4),
      "<br>Gene: ", df$gene_symbol,
      "<br>Phenotype: ", df$parameter_name
    )
    
    p <- ggplot(df, aes(x = reorder(parameter_name, pvalue),
                        y = -log10(pvalue),
                        color = Significant,
                        text = tooltip)) +
      geom_point(size = 2) + ggtitle("Phenotype Significance for Selected Gene") + labs(x = "Phenotype", y = "-log10(p-value)") +
      scale_color_manual(values = c("Not Significant" = "grey70", "Significant" = "#ff6b6b")) +
      theme_bw() + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
    
    ggplotly(p, tooltip = "text")
  })
  
  # Gene-based phenotype dropdown 
  output$phenotype_dropdown <- renderUI({
    phenos <- if(input$select_gene == "All Genes") {
      sort(unique(mouse_data$parameter_name))
    } else {
      sort(unique(mouse_data$parameter_name[mouse_data$gene_symbol == input$select_gene]))
    }
    selectInput("select_gene_pheno", "Filter by Phenotype:",
                choices = c("All", phenos), selected = "All")
  })
  
  # Significant table for Gene 
  output$sig_table_gene <- renderDT({
    df <- mouse_data
    if(input$select_gene != "All Genes") df <- df %>% filter(gene_symbol == input$select_gene)
    if(!is.null(input$select_gene_pheno) && input$select_gene_pheno != "All")
      df <- df %>% filter(parameter_name == input$select_gene_pheno)
    df %>% filter(pvalue < input$gene_pval) %>% datatable(options = list(pageLength = 10))
  })
  
  
  # Bubble Chart: KO by Phenotype 
  output$phenotype_bubble <- renderPlotly({
    df <- mouse_data
    if(input$select_phenotype != "All Phenotypes") df <- df %>% filter(parameter_name == input$select_phenotype)
    if(!is.null(input$select_pheno_gene) && input$select_pheno_gene != "All")
      df <- df %>% filter(gene_symbol == input$select_pheno_gene)
    
    df$pvalue[df$pvalue == 0] <- 1e-50
    df$Significant <- factor(ifelse(df$pvalue < input$phenotype_pval, "Significant", "Not Significant"),
                             levels = c("Not Significant", "Significant"))
    df$tooltip <- paste0(
      "KO Mouse: ", df$analysis_id,
      "<br>p-value: ", signif(df$pvalue, 4),
      "<br>Gene: ", df$gene_symbol,
      "<br>Phenotype: ", df$parameter_name
    )
    
    p <- ggplot(df, aes(x = reorder(gene_symbol, pvalue),
                        y = -log10(pvalue),
                        color = Significant,
                        text = tooltip)) +
      geom_point(size = 2) + ggtitle("Gene Significance for Selected Gene") + labs(x = "Gene", y = "-log10(p-value)") +
      scale_color_manual(values = c("Not Significant" = "grey70", "Significant" = "#ff6b6b")) +
      theme_bw() + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
    
    ggplotly(p, tooltip = "text")
  })
  
  # Phenotype-based gene dropdown 
  output$gene_dropdown <- renderUI({
    genes <- if(input$select_phenotype == "All Phenotypes") {
      sort(unique(mouse_data$gene_symbol))
    } else {
      sort(unique(mouse_data$gene_symbol[mouse_data$parameter_name == input$select_phenotype]))
    }
    selectInput("select_pheno_gene", "Filter by Gene:", choices = c("All", genes), selected = "All")
  })
  
  # Significant table for Phenotype 
  output$sig_table_phenotype <- renderDT({
    df <- mouse_data
    if(input$select_phenotype != "All Phenotypes") df <- df %>% filter(parameter_name == input$select_phenotype)
    if(!is.null(input$select_pheno_gene) && input$select_pheno_gene != "All")
      df <- df %>% filter(gene_symbol == input$select_pheno_gene)
    df %>% filter(pvalue < input$phenotype_pval) %>% datatable(options = list(pageLength = 10))
  })
  
  # Gene Clusters Plot
  
  # Store PCA output for click handling
  values <- reactiveValues(pc = NULL)
  
  output$clusterPlot <- renderPlotly({
    
    df <- mouse_data  
    
    # Clean and normalise pvalues
    
    df$pvalue <- suppressWarnings(as.numeric(df$pvalue))
    
    # Replace non-numeric or missing with 1 (no significance)
    df$pvalue[is.na(df$pvalue)] <- 1
    
    # Replace exact zeros (log issues)
    df$pvalue[df$pvalue == 0] <- 1e-50
    
    
   # Summarise data as it needs to be one pvalue per gene x pheno 
    
    summarised <- df %>%
      group_by(gene_symbol, parameter_name) %>%
      summarise(pvalue = min(pvalue, na.rm = TRUE), .groups = "drop")
    
    
   # -log10 transformation
    
    summarised$logp <- -log10(summarised$pvalue)
    summarised$logp[!is.finite(summarised$logp)] <- 0
    
    
    # Make gene x phenotype matrix
    
    gene_matrix <- summarised %>%
      select(gene_symbol, parameter_name, logp) %>%
      pivot_wider(
        names_from = parameter_name,
        values_from = logp,
        values_fill = 0
      )
    
    
    # Extract numeric matrix for PCA
    mat <- gene_matrix %>% select(-gene_symbol)
    
    # Convert all columns to numeric 
    mat <- mat %>% mutate(across(everything(), ~ as.numeric(.)))
    
    # Replace NA/Inf generated from pivot
    mat[!is.finite(as.matrix(mat))] <- 0
    
    
    # pca
    
    pca <- prcomp(mat, scale. = TRUE)
    
    pc <- as.data.frame(pca$x[, 1:2])
    colnames(pc) <- c("PC1", "PC2")
    pc$gene_symbol <- gene_matrix$gene_symbol
    
    
    # Clustering
    
    dist_matrix <- dist(pc[, 1:2])
    hc <- hclust(dist_matrix)
    pc$cluster <- cutree(hc, k = input$clusters)
    
    # Save cluster data
    values$pc <- pc
    
    
    # Interactive pca plot 
    
    plot_ly(
      data = pc,
      x = ~PC1, y = ~PC2,
      type = "scatter", mode = "markers",
      color = ~factor(cluster),
      colors = "Set1",
      text = ~paste0(
        "Gene: ", gene_symbol,
        "<br>Cluster: ", cluster,
        "<br>PC1: ", round(PC1, 2),
        "<br>PC2: ", round(PC2, 2)
      ),
      hoverinfo = "text",
      source = "cluster_plot"
    ) %>%
      layout(
        title = "PCA Clustering of Genes by Phenotype Profiles",
        xaxis = list(title = "PC1"),
        yaxis = list(title = "PC2"),
        legend = list(title = list(text = "Cluster"))
      )
    
  })
  
  
  # Make table that shows all genes when clicking on the cluster
  
  output$cluster_table <- renderDT({
    req(values$pc)
    
    click <- event_data("plotly_click", source = "cluster_plot")  # <-- add source
    if (is.null(click)) return(NULL)
    
    row_clicked <- click$pointNumber + 1
    clicked_cluster <- values$pc$cluster[row_clicked]
    
    values$pc %>%
      filter(cluster == clicked_cluster) %>%
      select(gene_symbol, PC1, PC2, cluster) %>%
      datatable(options = list(pageLength = 10))
  })


  
}

# ---- Run App ----
shinyApp(ui = ui, server = server)
