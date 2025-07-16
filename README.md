# XL-Chord

**XL-Chord** is an R Shiny app designed to process cross-linking mass spectrometry (XL-MS) search results from [pLink 3.0](https://github.com/pFindStudio/pLink3) and generate a matrix of glutamine–lysine (Q–K) cross-links suitable for visualization as a chord diagram using the [Circos](https://circos.ca/intro/tabular_visualization/) tabular interface. This tool was developed for mapping transglutaminase-mediated cross-links (e.g., FXIIIa, TG2) and is introduced in our upcoming manuscript on trauma patient plasma cross-linking.

---

## 📑 Table of Contents

- [Features](#-features)
- [Repository Contents](#-repository-contents)
- [How to Run the App](#️-how-to-run-the-app)
- [Input Instructions](#-input-instructions)
- [Output](#-output)
- [Creating a Chord Diagram with Circos](#-creating-a-chord-diagram-with-circos)
- [Editing SVG Output](#-editing-svg-output)
- [Citation](#-citation)
- [Contact](#-contact)
- [License](#-license)

---

## ⚙️ Features

- Accepts `_spectra.txt` output files from pLink 3.0 (cross-linked peptides by spectra)
- Filters and tabulates Q–K cross-links
- Generates a symmetric matrix of crosslink sites
- Outputs files compatible with Circos tabular web visualization
- The Circos tool or webserver can be used to produces high-resolution SVG images for further figure customization

---

## 🗂 Repository Contents

- `XL_Chord_ShinyApp.R`: Main R Shiny script
- `www/`: UI assets
- `test_data/`: Includes example pLink 3.0 results and output files  
    - `example_pLink_output.txt` – Sample input file  
    - `example_matrix_output.tsv` – Output matrix used by Circos  
- `screenshots/`: Demonstrations of UI and Circos setup  
    - `app_interface.png` – Full Shiny UI  
    - `input_selection.png` – File upload and filtering options  
    - `output_matrix.png` – Example matrix display  
- `circos_setup/`: Circos configuration images  
    - `circos_input_table.png` – Data import interface  
    - `circos_preview.png` – Example output  
- `output_download/`: Sample SVG results from Circos  
    - `circos_output.svg` – Ready-to-edit file

---

## ▶️ How to Run the App

### Requirements

- R version ≥ 4.2  
- Required R packages: `shiny`, `readr`, `tidyverse`

### Local Use

Clone the repository and run the app from RStudio or your terminal:

```r
shiny::runApp("path/to/XL_Chord_ShinyApp.R")
```

The app will open in your web browser. You will see an interface like the one below:

![Shiny App Interface](screenshots/app_interface.png)

For my local machine here is the command as an example:

!shiny::runApp("C:/Users/User/Documents/R_Scripts/RpLinkapp/Rplinkappc.R")

---

## 📥 Input Instructions

- Upload your **pLink 3.0 cross-link results file** (`.txt`)
- Select cross-link types to filter for Q–K bonds
- App generates a square matrix of cross-linking positions

Example file:  
`test_data/example_pLink_output.txt`

---

## 💾 Output

The main output is a matrix file compatible with Circos:

- `output_matrix.tsv`: Matrix of cross-linked site frequencies
- Preview within app:  
  ![Matrix Output](screenshots/output_matrix.png)

This matrix can be downloaded and used for Circos chord diagram creation.

---

## 🎨 Creating a Chord Diagram with Circos

Use the Circos tabular visualization webserver:  
[https://mk.bcgsc.ca/tableviewer/](https://mk.bcgsc.ca/tableviewer/)

### Quick Start Instructions

1. Visit the [Circos tableviewer](https://mk.bcgsc.ca/tableviewer/)
2. Upload your output matrix (`output_matrix.tsv`)
3. Adjust parameters:
    - **Type**: Chord Diagram
    - **Group name column**: leave as-is
    - **Value column**: matrix counts
4. Optional: adjust color palette, layout, and orientation

Example setup image:  
![Circos Setup](circos_setup/circos_input_table.png)

Resulting diagram preview:  
![Circos Output](circos_setup/circos_preview.png)

---

## ✏️ Editing SVG Output

Final SVG figures from Circos will appear in the app’s download directory (or download them directly from the Circos website):

- `circos_output.svg`

These can be opened in:
- **Adobe Illustrator**
- **Inkscape**

### Suggested edits:
- Remove outer ring labels
- Modify chord coloring
- Reorder segments for clarity

---

## 📚 Citation

Please cite the tool and associated manuscript when published.  

---

## 📬 Contact

For questions or issues, please open an issue in this GitHub repository or [contact us via email](mailto:kirk.hansen@cuanschutz.edu).

---

## 🔒 License

MIT License – see `LICENSE` file for details.
