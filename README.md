# latex-typeset
Utilities for latex typesetting on Emacs

This package provides three functions, `latex-typeset-and-preview`, `latex-typeset-and-preview-region`, and `latex-preview-pdf`. 

They are available in any major-mode for LaTeX.  
This package assumes the process of making pdf (using dvipdfmx) as follows :

    .tex -> .dvi -> .pdf

Setting Example :

```lisp
(add-hook 'yatex-mode-hook
          (lambda ()
            (require 'latex-typeset)
            (setf *latex-program* "uplatex"               ;; the default is "platex"
                  *latex-pdf-program* "open"              ;; the default is "evince"
                  *latex-rm-ext* '(".dvi" ".log" ".aux")) ;; the default is '(".dvi")
            (local-set-key (kbd "C-c C-c") 'latex-typeset-and-preview)
            (local-set-key (kbd "C-c C-r") 'latex-typeset-and-preview-region)
            (local-set-key (kbd "C-c C-p") 'latex-preview-pdf)))
```
