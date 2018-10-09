# READ-ME: 'make figures' only works with -B parameters: 'make -B figures'
#              Apply the -B to make all too: 'make -B all'

filename=Template
input_filename=paper-j-stars
mendeley_bibtex=/Users/alage/Copy/professional/ufal/meta/meta-writing/bibtex/library.bib
bibtex=library.bib

with-pdf : pdflatex clean-but-pdf

pdflatex :
	pdflatex $(filename).tex
	bibtex $(filename)
	pdflatex $(filename).tex
	pdflatex $(filename).tex
		
pdf :
	latex $(filename).tex
	bibtex $(filename)
	latex $(filename).tex
	latex $(filename).tex
	dvipdf $(filename).dvi

figures :
	cd figures && inkscape architecture.svg -T -E architecture.eps
	
figures-png :
	cd figures && inkscape architecture.svg -d 70 -e architecture.png
	
clean-but-pdf :
	rm -f ${filename}.{ps,log,aux,out,dvi,bbl,blg,lof,gls,ilg,ist,glo,toc,synctex.gz} ${input_filename}.{ps,log,aux,out,dvi,bbl,blg,lof,gls,ilg,ist,glo,toc,synctex.gz} *~ *.log

clean-pdf :
	rm -f ${filename}.pdf

clean-all : clean-but-pdf clean-pdf

copy-bibtex-from-mendeley :
	rm -f $(bibtex) && cp -f $(mendeley_bibtex) $(bibtex)

link-bibtex-from-mendeley :
	ln -sf $(mendeley_bibtex) $(bibtex)
