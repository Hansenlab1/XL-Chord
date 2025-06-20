library(shiny)
library(dplyr)
library(stringr)

# Predefined Level1 site lists for Human and Mouse
Q_sites_human <- c("A2AP_Q41", "A2AP_Q43", "A2AP_Q60", "A2AP_Q447", "A2AP_Q458", 
                   "FINC_Q32", "FINC_Q1996", "FINC_QQ2348",
                   "A2MG_Q693", "A2MG_Q694", "FIBA_Q240", "FIBA_Q256", 
                   "FIBA_Q347", "FIBA_Q385", "FIBA_Q582", "FIBG_Q424", "FIBG_Q425")
K_sites_human <- c("FIBA_K227", "FIBA_K238", "FIBA_K249", "FIBA_K432", "FIBA_K437", 
                   "FIBA_K440", "FIBA_K446", "FIBA_K448", "FIBA_K463", "FIBA_K467", 
                   "FIBA_K476", "FIBA_K48", "FIBA_K480", "FIBA_K527", "FIBA_K558", 
                   "FIBA_K575", "FIBA_K581", "FIBA_K599", "FIBA_K602", "FIBA_K620", 
                   "FIBGA_K21")
# Placeholder lists for Mouse (update with correct values as needed)
Q_sites_mouse <- c("A2AP_Q41_mouse", "A2AP_Q43_mouse", "A2AP_Q60_mouse", "A2AP_Q447_mouse", "A2AP_Q458_mouse")
K_sites_mouse <- c("FIBA_K227_mouse", "FIBA_K238_mouse", "FIBA_K249_mouse", "FIBA_K432_mouse", "FIBA_K437_mouse")

# Protein group choices (apply to both Q and K selection)
protein_groups <- c("FIB", "FINC", "A2AP", "ALBU", "A2MG")

ui <- fluidPage(
  titlePanel("Shiny File Processor - Phase 1 & 2"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file1", "Choose CSV File",
                accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")),
      radioButtons("mode", "Select Mode:",
                   choices = c("Process Data" = "process", 
                               "Generate Matrix" = "matrix",
                               "Process & Generate Matrix" = "both"),
                   selected = "process"),
      # Options for matrix generation (visible when mode is matrix or both)
      conditionalPanel(
        condition = "input.mode == 'matrix' || input.mode == 'both'",
        radioButtons("matrixScope", "Matrix Scope:",
                     choices = c("All pairs", "Level1 pairs"),
                     selected = "All pairs"),
        conditionalPanel(
          condition = "input.matrixScope == 'Level1 pairs'",
          radioButtons("species", "Select Species:",
                       choices = c("Human", "Mouse"),
                       selected = "Human"),
          radioButtons("selectionType", "Select Level1 Site Selection Type:",
                       choices = c("Individual sites", "Protein group"),
                       selected = "Individual sites"),
          conditionalPanel(
            condition = "input.selectionType == 'Individual sites'",
            uiOutput("QsiteSelector"),
            uiOutput("KsiteSelector")
          ),
          conditionalPanel(
            condition = "input.selectionType == 'Protein group'",
            selectInput("selectProteinQ", "Select Protein groups for Q sites:", 
                        choices = c("All", protein_groups),
                        selected = "All", multiple = TRUE),
            selectInput("selectProteinK", "Select Protein groups for K sites:", 
                        choices = c("All", protein_groups),
                        selected = "All", multiple = TRUE)
          )
        )
      ),
      actionButton("processBtn", "Run"),
      downloadButton("downloadData", "Download Output File")
    ),
    mainPanel(
      textOutput("status")
    )
  )
)

server <- function(input, output, session) {
  # Reactive value to store output file name (saved in working directory)
  outputFile <- reactiveVal(NULL)
  
  # Dynamic UI for individual site selection based on species
  output$QsiteSelector <- renderUI({
    if (input$species == "Human") {
      selectInput("selectQs", "Select Q sites:", 
                  choices = c("All", Q_sites_human), selected = "All", multiple = TRUE)
    } else {
      selectInput("selectQs", "Select Q sites:", 
                  choices = c("All", Q_sites_mouse), selected = "All", multiple = TRUE)
    }
  })
  
  output$KsiteSelector <- renderUI({
    if (input$species == "Human") {
      selectInput("selectKs", "Select K sites:", 
                  choices = c("All", K_sites_human), selected = "All", multiple = TRUE)
    } else {
      selectInput("selectKs", "Select K sites:", 
                  choices = c("All", K_sites_mouse), selected = "All", multiple = TRUE)
    }
  })
  
  observeEvent(input$processBtn, {
    req(input$file1)
    inFile <- input$file1
    rawData <- read.csv(inFile$datapath, stringsAsFactors = FALSE)
    
    # Helper function for Phase 1: Process Data
    processData <- function(data) {
      extract_aa <- function(peptide) {
        num <- str_extract(peptide, "\\(\\d+\\)")
        if (!is.na(num)) {
          pos <- as.numeric(gsub("[()]", "", num))
          if (pos >= 1 && pos <= nchar(peptide)) {
            return(substr(peptide, pos, pos))
          }
        }
        return(NA)
      }
      data <- data %>%
        mutate(
          P1 = sapply(str_split(Peptide, "-"), `[`, 1),
          P2 = sapply(str_split(Peptide, "-"), `[`, 2),
          P1_AA = sapply(P1, extract_aa),
          P2_AA = sapply(P2, extract_aa)
        )
      split_proteins <- function(protein_string) {
        parts <- str_split(protein_string, "\\)-")[[1]]
        if (length(parts) >= 2) {
          Prot1 <- paste0(parts[1], ")-")
          Prot2 <- str_split(parts[2], "/")[[1]][1]
          return(c(Prot1, Prot2))
        }
        return(c(protein_string, ""))
      }
      proteins <- t(sapply(data$Proteins, split_proteins))
      data$Prot1 <- proteins[, 1]
      data$Prot2 <- proteins[, 2]
      assign_prot <- function(P1_AA, Prot1, Prot2) {
        if (!is.na(P1_AA) && P1_AA == "K") {
          return(c(ProtQ = Prot2, ProtK = Prot1))
        } else if (!is.na(P1_AA) && P1_AA == "Q") {
          return(c(ProtQ = Prot1, ProtK = Prot2))
        }
        return(c(ProtQ = "", ProtK = ""))
      }
      prot_assigned <- t(mapply(assign_prot, data$P1_AA, data$Prot1, data$Prot2))
      data$ProtQ <- prot_assigned[, "ProtQ"]
      data$ProtK <- prot_assigned[, "ProtK"]
      create_QK_prot <- function(prot_string, type = "Q") {
        prot_name <- str_match(prot_string, "\\|([^|]+)_HUMAN")[, 2]
        num <- str_match(prot_string, "\\((\\d+)\\)")[, 2]
        if (!is.na(prot_name) && !is.na(num)) {
          if (type == "K") {
            return(paste0(prot_name, "_K", num))
          } else {
            return(paste0(prot_name, "_Q", num))
          }
        }
        return("")
      }
      data$QProt <- sapply(data$ProtQ, create_QK_prot, type = "Q")
      data$KProt <- sapply(data$ProtK, create_QK_prot, type = "K")
      return(data)
    }
    
    # Helper function for Phase 2: Generate Matrix
    generateMatrix <- function(data) {
      if (input$matrixScope == "All pairs") {
        Q_levels <- sort(unique(data$QProt))
        K_levels <- sort(unique(data$KProt))
      } else if (input$matrixScope == "Level1 pairs") {
        # Use either individual site selection or protein group selection
        if (input$selectionType == "Individual sites") {
          if (input$species == "Human") {
            Q_levels <- if("All" %in% input$selectQs) Q_sites_human else input$selectQs
            K_levels <- if("All" %in% input$selectKs) K_sites_human else input$selectKs
          } else {
            Q_levels <- if("All" %in% input$selectQs) Q_sites_mouse else input$selectQs
            K_levels <- if("All" %in% input$selectKs) K_sites_mouse else input$selectKs
          }
          data_filtered <- data %>% filter(QProt %in% Q_levels, KProt %in% K_levels)
        } else if (input$selectionType == "Protein group") {
          # For protein group selection, filter rows whose QProt (or KProt) starts with one of the selected groups
          if (input$species == "Human") {
            Q_groups <- if("All" %in% input$selectProteinQ) protein_groups else input$selectProteinQ
            K_groups <- if("All" %in% input$selectProteinK) protein_groups else input$selectProteinK
          } else {
            Q_groups <- if("All" %in% input$selectProteinQ) protein_groups else input$selectProteinQ
            K_groups <- if("All" %in% input$selectProteinK) protein_groups else input$selectProteinK
          }
          data_filtered <- data %>% filter(
            sapply(QProt, function(x) any(sapply(Q_groups, function(g) grepl(paste0("^", g), x)))),
            sapply(KProt, function(x) any(sapply(K_groups, function(g) grepl(paste0("^", g), x))))
          )
          Q_levels <- sort(unique(data_filtered$QProt))
          K_levels <- sort(unique(data_filtered$KProt))
        }
      }
      matrix_data <- table(factor(data_filtered$QProt, levels = Q_levels),
                           factor(data_filtered$KProt, levels = K_levels))
      matrix_data <- as.matrix(matrix_data)
      row_totals <- rowSums(matrix_data)
      col_totals <- colSums(matrix_data)
      matrix_with_totals <- cbind(matrix_data, Total = row_totals)
      matrix_with_totals <- rbind(matrix_with_totals, Total = col_totals)
      count_rows <- apply(matrix_data, 1, function(x) sum(x > 0))
      matrix_with_totals <- cbind(matrix_with_totals, Count = c(count_rows, NA))
      count_cols <- apply(matrix_data, 2, function(x) sum(x > 0))
      matrix_with_totals <- rbind(matrix_with_totals, Count = c(count_cols, NA))
      return(matrix_with_totals)
    }
    
    # Decide which mode to run
    if (input$mode == "process") {
      # Run Phase 1 only
      processedData <- processData(rawData)
      base <- tools::file_path_sans_ext(inFile$name)
      ext <- tools::file_ext(inFile$name)
      output_name <- paste0(base, "_QK.", ext)
      write.csv(processedData, file = output_name, row.names = FALSE)
      outputFile(output_name)
      output$status <- renderText({
        paste("Processing complete. Processed file:", output_name)
      })
    } else if (input$mode == "matrix") {
      # Run Phase 2 only (assumes input file already has QProt/KProt)
      mat <- generateMatrix(rawData)
      base <- tools::file_path_sans_ext(inFile$name)
      ext <- tools::file_ext(inFile$name)
      output_name <- paste0(base, "_filtered_matrix.", ext)
      write.csv(mat, file = output_name, row.names = TRUE)
      outputFile(output_name)
      output$status <- renderText({
        paste("Matrix generation complete. Output file:", output_name)
      })
    } else if (input$mode == "both") {
      # Run Phase 1 then Phase 2 sequentially
      processedData <- processData(rawData)
      base <- tools::file_path_sans_ext(inFile$name)
      ext <- tools::file_ext(inFile$name)
      proc_name <- paste0(base, "_QK.", ext)
      write.csv(processedData, file = proc_name, row.names = FALSE)
      mat <- generateMatrix(processedData)
      output_name <- paste0(base, "_filtered_matrix.", ext)
      write.csv(mat, file = output_name, row.names = TRUE)
      outputFile(output_name)
      output$status <- renderText({
        paste("Processing and matrix generation complete. Output file:", output_name)
      })
    }
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      req(outputFile())
      outputFile()
    },
    content = function(file) {
      req(outputFile())
      file.copy(outputFile(), file)
    }
  )
}

shinyApp(ui = ui, server = server)

                                       