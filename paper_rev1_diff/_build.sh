#!/bin/bash

latexdiff ../paper/kalis.tex ../paper_rev1/kalis.tex > kalis_diff.tex; pdflatex kalis_diff; pdflatex kalis_diff

#######################################
cd Additional_file_1
latexdiff ../../paper/Additional_file_1/Additional_file_1.tex ../../paper_rev1/Additional_file_1/Additional_file_1.tex > Additional_file_1_diff.tex

# Use sed to find and replace in Additional_file_1_diff.tex to change the line reading "\externaldocument{../kalis}" to "\externaldocument{../kalis_diff}"
sed -i .old 's/\\externaldocument{..\/kalis}/\\externaldocument{..\/kalis_diff}/g' Additional_file_1_diff.tex

cp ../../paper_rev1/Additional_file_1/Additional_file_1.bbl Additional_file_1_diff.bbl
pdflatex Additional_file_1_diff; pdflatex Additional_file_1_diff

#######################################
cd Additional_file_2
latexdiff ../../paper/Additional_file_2/Additional_file_2.tex ../../paper_rev1/Additional_file_2/Additional_file_2.tex > Additional_file_2_diff.tex

# Use sed to find and replace in Additional_file_1_diff.tex to change the line reading "\externaldocument{../kalis}" to "\externaldocument{../kalis_diff}"
sed -i .old 's/]{..\/kalis}/]{..\/kalis_diff}/g' Additional_file_2_diff.tex

cp ../../paper_rev1/Additional_file_2/Additional_file_2.bbl Additional_file_2_diff.bbl
pdflatex Additional_file_2_diff; pdflatex Additional_file_2_diff
