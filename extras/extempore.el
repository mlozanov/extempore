;;; extempore.el --- Emacs major mode for Extempore source files

;; Author: Ben Swift <benjamin.j.swift@gmail.com>
;; Keywords: Extempore

;; Adapted from: scheme.el by Bill Rozas and Dave Love
;; Also includes some work done by Hector Levesque and Andrew Sorensen

;; Copyright (c) 2011-2012, Andrew Sorensen

;; All rights reserved.

;; Redistribution and use in source and binary forms, with or without 
;; modification, are permitted provided that the following conditions are met:

;; 1. Redistributions of source code must retain the above copyright notice, 
;;    this list of conditions and the following disclaimer.

;; 2. Redistributions in binary form must reproduce the above copyright notice,
;;    this list of conditions and the following disclaimer in the documentation 
;;    and/or other materials provided with the distribution.

;; Neither the name of the authors nor other contributors may be used to endorse
;; or promote products derived from this software without specific prior written 
;; permission.

;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
;; POSSIBILITY OF SUCH DAMAGE.

;; Commentary:

;; A major mode for editing Extempore code. See the Extempore project
;; page at http://github.com/digego/extempore for more details.

;; Installation:

;; To set up Emacs to automatically load this major mode for any .xtm
;; files, add the following lines to your .emacs

;; (autoload 'extempore-mode "/path/to/extempore/extras/extempore.el" "" t)
;; (add-to-list 'auto-mode-alist '("\\.xtm$" . extempore-mode))

;; Currently, extempore.el requires Emacs 24, because it inherits from
;; prog-mode (via lisp-mode)

;;; Code:

(require 'lisp-mode)

(defvar extempore-mode-syntax-table
  (let ((st (make-syntax-table))
	(i 0))
    ;; Symbol constituents
    (while (< i ?0)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)))
    (setq i (1+ ?9))
    (while (< i ?A)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)))
    (setq i (1+ ?Z))
    (while (< i ?a)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)))
    (setq i (1+ ?z))
    (while (< i 128)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)))
    ;; Whitespace
    (modify-syntax-entry ?\t "    " st)
    (modify-syntax-entry ?\n ">   " st)
    (modify-syntax-entry ?\f "    " st)
    (modify-syntax-entry ?\r "    " st)
    (modify-syntax-entry ?\s "    " st)
    ;; paren delimiters
    (modify-syntax-entry ?\( "()  " st)
    (modify-syntax-entry ?\) ")(  " st)
    ;; comment delimiters
    (modify-syntax-entry ?\; "<   " st)
    (modify-syntax-entry ?\" "\"   " st)
    (modify-syntax-entry ?' "'   " st)
    (modify-syntax-entry ?` "'   " st)
    ;; in xtlang, commas are used in type annotations
    (modify-syntax-entry ?, "_   " st)
    ;; Special characters
    (modify-syntax-entry ?@ "'   " st)
    (modify-syntax-entry ?# "'   " st)
    (modify-syntax-entry ?\\ "\\   " st)
    st))

(defvar extempore-mode-abbrev-table nil)
(define-abbrev-table 'extempore-mode-abbrev-table ())

(defvar extempore-imenu-generic-expression
  '((nil ;"Scheme"
     "(\\(define\\(\\|-macro\\|-instrument\\|-sampler\\)\\)\\s-+\\(\\(\\sw\\|\\s_\\)+\\)\\_>" 3)
    (nil ;"xtlang"
     "(\\(bind-\\(func\\|val\\|type\\|alias\\|poly\\|lib\\)\\)\\s-+\\(\\(\\sw\\|\\s_\\)+\\)\\_>" 3))
  "Imenu generic expression for Extempore mode.  See `imenu-generic-expression'.")


(defun extempore-mode-variables ()
  (set-syntax-table extempore-mode-syntax-table)
  (setq local-abbrev-table extempore-mode-abbrev-table)
  (set (make-local-variable 'paragraph-start) (concat "$\\|" page-delimiter))
  (set (make-local-variable 'paragraph-separate) paragraph-start)
  (set (make-local-variable 'paragraph-ignore-fill-prefix) t)
  (set (make-local-variable 'fill-paragraph-function) 'lisp-fill-paragraph)
  ;; Adaptive fill mode gets in the way of auto-fill,
  ;; and should make no difference for explicit fill
  ;; because lisp-fill-paragraph should do the job.
  (set (make-local-variable 'adaptive-fill-mode) nil)
  (set (make-local-variable 'indent-line-function) 'lisp-indent-line)
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'outline-regexp) ";;; \\|(....")
  (set (make-local-variable 'comment-start) ";")
  (set (make-local-variable 'comment-add) 1)
  ;; Look within the line for a ; following an even number of backslashes
  ;; after either a non-backslash or the line beginning.
  (set (make-local-variable 'comment-start-skip)
       "\\(\\(^\\|[^\\\\\n]\\)\\(\\\\\\\\\\)*\\);+[ \t]*")
  (set (make-local-variable 'font-lock-comment-start-skip) ";+ *")
  (set (make-local-variable 'comment-column) 40)
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'lisp-indent-function) 'extempore-indent-function)
  (setq mode-line-process '("" extempore-mode-line-process))
  ;; (set (make-local-variable 'imenu-case-fold-search) t)
  (setq imenu-generic-expression extempore-imenu-generic-expression)
  (set (make-local-variable 'font-lock-defaults)
       '(extempore-font-lock-keywords
	 nil t (("+-*/,.<>=!?$%_&~^:" . "w") (?#. "w 14"))
	 beginning-of-defun
	 (font-lock-mark-block-function . mark-defun)
	 (font-lock-syntactic-face-function
	  . extempore-font-lock-syntactic-face-function)
	 (parse-sexp-lookup-properties . t)
	 (font-lock-extra-managed-props syntax-table)))
  (set (make-local-variable 'lisp-doc-string-elt-property)
       'extempore-doc-string-elt))

(defvar extempore-mode-line-process "")

(defvar extempore-mode-map
  (let ((smap (make-sparse-keymap))
	(map (make-sparse-keymap "Extempore")))
    (set-keymap-parent smap lisp-mode-shared-map)
    (define-key smap [menu-bar extempore] (cons "Extempore" map))
    ;; (define-key map [run-extempore] '("Run Inferior Extempore" . run-extempore))
    (define-key map [uncomment-region]
      '("Uncomment Out Region" . (lambda (beg end)
				   (interactive "r")
				   (comment-region beg end '(4)))))
    (define-key map [comment-region] '("Comment Out Region" . comment-region))
    (define-key map [indent-region] '("Indent Region" . indent-region))
    (define-key map [indent-line] '("Indent Line" . lisp-indent-line))
    (put 'comment-region 'menu-enable 'mark-active)
    (put 'uncomment-region 'menu-enable 'mark-active)
    (put 'indent-region 'menu-enable 'mark-active)
    smap)
  "Keymap for Extempore mode.
All commands in `lisp-mode-shared-map' are inherited by this map.")

;;;###autoload
(define-derived-mode extempore-mode prog-mode "Extempore"
  "Major mode for editing Extempore code.
This mode has been adapted from `scheme-mode'.

In addition, if an Extempore process is running in a shell
buffer, some additional commands will be defined, for evaluating
expressions and controlling the extempore process.

Entry to this mode calls the value of `extempore-mode-hook'."
  (extempore-mode-variables)
  (make-variable-buffer-local 'extempore-process)
  (setq extempore-process nil))

(defgroup extempore nil
  "Editing Extempore code."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :group 'lisp)

(defcustom extempore-mode-hook nil
  "Normal hook run when entering `extempore-mode'.
See `run-hooks'."
  :type 'hook
  :group 'extempore)

(defcustom extempore-default-host "localhost"
  "Default host where the extempore process is running."
  :type 'string
  :group 'extempore)

(defcustom extempore-default-port 7099
  "Default port where the extempore process is running."
  :type 'integer
  :group 'extempore)

(defcustom extempore-use-pretty-lambdas t
  "Use pretty (greek symbol) lambdas in buffer?"
  :type 'boolean
  :group 'extempore)

(defcustom extempore-tab-completion t
  "Use <TAB> key for (contextual) symbol completion"
  :type 'boolean
  :group 'extempore)

(defcustom extempore-path nil
  "Location of the extempore executable."
  :type 'string
  :group 'extempore)

(defcustom extempore-process-args nil
  "Arguments to pass to the extempore process started by `extempore-setup'."
  :type 'string
  :group 'extempore)

;; different faces for the scheme and xtlang defuns.  Feel free to set
;; colours which work with your own colour scheme

;; (defface extempore-scheme-defun-face
;;   '((t (:inherit font-lock-keyword-face)))
;;   "Face used for scheme defuns."
;;   :group 'extempore)

;; (defface extempore-xtlang-defun-face
;;   '((t (:inherit font-lock-variable-name-face)))
;;   "Face used for xtlang defuns."
;;   :group 'extempore)

;; from emacs-starter-kit

(defface extempore-paren-face
  '((((class color) (background dark))
     (:foreground "grey50"))
    (((class color) (background light))
     (:foreground "grey55")))
  "Face used to dim parentheses in extempore."
  :group 'extempore)

(defun extempore-keybindings (keymap)
  (define-key keymap (kbd "C-x C-y") 'extempore-setup)
  (define-key keymap (kbd "C-x C-j") 'extempore-connect)
  (define-key keymap (kbd "C-x C-x") 'extempore-send-definition)
  (define-key keymap (kbd "C-x C-r") 'extempore-send-region)
  (define-key keymap (kbd "C-x C-b") 'extempore-send-buffer))

(extempore-keybindings extempore-mode-map)

(if extempore-tab-completion
    (define-key extempore-mode-map (kbd "TAB")
      '(lambda ()
         (interactive)
         (if (minibufferp)
             (unless (minibuffer-complete)
               (dabbrev-expand nil))
           (if mark-active
               (indent-region (region-beginning)
                              (region-end))
             (if (looking-at "\\_>")
                 (dabbrev-expand nil)
               (indent-for-tab-command)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; generate function name lists from source files
;;
;; scheme ones from OPDefines.h
;; xtlang from llvm.ti
;; (these files need to be open in buffers for the below functions to
;; work properly)
;; 
;; this stuff is currently a bit fragile, so I've hardcoded in the
;; names as they stand at 14/7/12

(setq extempore-builtin-names
      '("or" "and" "let" "lambda" "if" "else" "dotimes" "cond"
        "begin" "syntax-rules" "syntax" "map" "do"
        "letrec-syntax" "letrec" "eval" "apply"
        "quote" "quasiquote"
        "let-syntax" "let*" "for-each" "case"
        "call-with-output-file" "call-with-input-file"
        "call/cc" "call-with-current-continuation"))

;; TODO maybe parse the startup scheme files as well?

(defun extempore-find-scheme-names (names)
  (if (re-search-forward "\".*\"" nil t)
      (extempore-find-scheme-names
       (cons (buffer-substring-no-properties
              (+ (car (match-data)) 1)
              (- (cadr (match-data)) 1))
             names))
    (delete-dups names)))

;; (setq extempore-scheme-names
;;       (cl-set-difference
;;        (with-current-buffer "OPDefines.h"
;;          (goto-char (point-min))
;;          (extempore-find-scheme-names '()))
;;        extempore-builtin-names))

(setq extempore-scheme-names
      '("set!" "caaaar" "cdaaar" "cadaar" "cddaar" "caadar" "cdadar" "caddar" "cdddar" "caaadr" "cdaadr" "cadadr" "cddadr" "caaddr" "cdaddr" "cadddr" "cddddr" "caaar" "cdaar" "cadar" "cddar" "caadr" "cdadr" "caddr" "cdddr" "caar" "cdar" "cadr" "cddr" "car" "cdr" "print" "println" "load" "gensym" "tracing" "make-closure" "defined?" "eval" "apply" "call-with-current-continuation" "inexact->exact" "exp" "log" "sin" "cos" "tan" "asin" "acos" "atan" "sqrt" "expt" "floor" "ceiling" "truncate" "round" "+" "-" "*" "/" "%" "bitwise-not" "bitwise-and" "bitwise-or" "bitwise-eor" "bitwise-shift-left" "bitwise-shift-right" "quotient" "remainder" "modulo" "car" "cdr" "cons" "set-car!" "set-cdr!" "char->integer" "integer->char" "char-upcase" "char-downcase" "symbol->string" "atom->string" "string->symbol" "string->atom" "make-string" "string-length" "string-ref" "string-set!" "string-append" "substring" "vector" "make-vector" "vector-length" "vector-ref" "vector-set!" "not" "boolean?" "eof-object?" "null?" "=" "<" ">" "<=" ">=" "member" "equal?" "eq?" "eqv?" "symbol?" "number?" "string?" "integer?" "real?" "rational?" "char?" "char-alphabetic?" "char-numeric?" "char-whitespace?" "char-upper-case?" "char-lower-case?" "port?" "input-port?" "output-port?" "procedure?" "pair?" "list?" "environment?" "vector?" "cptr?" "eq?" "eqv?" "force" "write" "write-char" "display" "newline" "error" "reverse" "list*" "append" "put" "get" "quit" "new-segment" "oblist" "current-input-port" "current-output-port" "open-input-file" "open-output-file" "open-input-output-file" "open-input-string" "open-output-string" "open-input-output-string" "close-input-port" "close-output-port" "interaction-environment" "current-environment" "read" "read-char" "peek-char" "char-ready?" "set-input-port" "set-output-port" "length" "assq" "get-closure-code" "closure?" "macro?" "macro-expand"))

(defun extempore-find-xtlang-names (names)
  (if (re-search-forward "(\\(member\\|equal\\?\\|eq\\?\\) \\((car ast)\\|ast\\) \'" nil t)
      (let ((syms (read (thing-at-point 'sexp))))
        (extempore-find-xtlang-names
         (if (listp syms)
             (append syms names)
           (cons syms names))))
    (delete-dups (mapcar 'symbol-name names))))

;; (setq extempore-xtlang-names
;;       (cl-set-difference
;;        (with-current-buffer "llvmti.xtm"
;;          (goto-char (point-min))
;;          (extempore-find-xtlang-names '()))
;;        (append extempore-builtin-names
;;                extempore-scheme-names)
;;        :test 'string-equal))

(setq extempore-xtlang-names
      '("random" "afill!" "pfill!" "tfill!" "vfill!" "array-fill!" "pointer-fill!" "tuple-fill!" "vector-fill!" "free" "array" "tuple" "list" "~" "cset!" "cref" "cast" "&" "bor" "ang-names" "<<" ">>" "nil" "printf" "sprintf" "null" "now" "pset!" "pref-ptr" "vset!" "vref" "aset!" "aref" "aref-ptr" "tset!" "tref" "tref-ptr" "salloc" "halloc" "zalloc" "alloc" "schedule" "expf" "logf" "sinf" "cosf" "tanf" "asinf" "acosf" "atanf" "sqrtf" "exptf" "floorf" "ceilingf" "truncatef" "roundf" "llvm_printf" "push_zone" "pop_zone" "memzone" "callback" "llvm_sprintf" "make-array" "array-set!" "array-ref" "array-ref-ptr" "pointer-set!" "pointer-ref" "pointer-ref-ptr" "stack-alloc" "heap-alloc" "zone-alloc" "make-tuple" "tuple-set!" "tuple-ref" "tuple-ref-ptr" "closure-set!" "closure-ref" "pref" "pdref" "impc_null" "bitcast" "void" "ifret" "ret->" "clrun->" "make-env-zone" "make-env" "<>"))

(defconst extempore-font-lock-keywords-shared
  (eval-when-compile
    (list
     ;; other type annotations (has to be first in list)
     '(":[^ \t)]?+"
       (0 font-lock-type-face))
     ;; built-ins
     (list
      (concat
       "("
       (regexp-opt
	extempore-builtin-names t)
       "\\>")
      '(1 font-lock-keyword-face t))
     ;; float and int literals
      '("\\_<[-+]?[/.[:digit:]]+?\\_>"
        (0 font-lock-constant-face))
     ;; hack to make sure / gets highlighted as a function
      '("\\_</\\_>"
        (0 font-lock-function-name-face t))
      ;; boolean literals
      '("\\_<#[tf]\\_>"
       (0 font-lock-constant-face)))))

(defconst extempore-font-lock-keywords-scheme
  (eval-when-compile
    (list
     ;; definitions
     (list (concat
	    "(\\(define\\(\\|-macro\\|-syntax\\|-instrument\\|-sampler\\)\\)\\_>\\s-*(?\\(\\sw+\\)?")
	   '(1 font-lock-keyword-face)
	   '(3 font-lock-function-name-face))
     ;; scheme functions
     (list
      (regexp-opt
       extempore-scheme-names 'symbols)
      '(1 font-lock-function-name-face))
     ;; It wouldn't be Scheme w/o named-let.
     '("(let\\s-+\\(\\sw+\\)"
       (1 font-lock-function-name-face)))))

(defconst extempore-font-lock-keywords-xtlang
  (eval-when-compile
    (list
     ;; definitions
     ;; closure type annotations (i.e. specified with a colon)
     '("(\\(bind-\\(func\\|poly\\)\\)\\s-+\\([^ \t:]+\\)\\(:[^ \t)]?+\\)?"
       (1 font-lock-keyword-face)
       (3 font-lock-function-name-face)
       (4 font-lock-type-face prepend t))
     ;; (list
     ;;  (concat
     ;;   "(\\(bind-\\(func\\|poly\\)\\)\\_>"
     ;;   ;; Any whitespace and declared object.
     ;;   "\s-*"
     ;;   "\\(\\sw+\\)?")
     ;;  '(1 font-lock-keyword-face)
     ;;  '(3 font-lock-function-name-face))
     ;; important xtlang functions
     (list
      (regexp-opt
       extempore-xtlang-names 'symbols)
      '(1 font-lock-function-name-face))
     ;; bind-type/alias
     '("(\\(bind-\\(type\\|alias\\)\\)\\s-+\\(\\S-+\\)\\s-+\\([^ \t)]+\\))"
       (1 font-lock-keyword-face)
       (3 font-lock-function-name-face)
       (4 font-lock-type-face t))
     ;; bind-lib
     '("(\\(bind-lib\\)\\s-+\\(\\S-+\\)\\s-+\\(\\S-+\\)\\s-+\\([^ \t)]+\\))"
       (1 font-lock-keyword-face)
       (2 font-lock-constant-face)
       (3 font-lock-function-name-face)
       (4 font-lock-type-face t))
     ;; bind-val
     '("(\\(bind-val\\)\\s-+\\(\\S-+\\)\\s-+\\([^ \t)]?+\\)"
       (1 font-lock-keyword-face)
       (2 font-lock-function-name-face)
       (3 font-lock-type-face t))
     ;; cast
     '("(cast\\s-+\\S-+\\s-+\\([^ \t)]?+\\))"
       (1 font-lock-type-face))
     ;; type coercion stuff
     (list
      (concat
       "(" (regexp-opt
            (let ((types '("i1" "i8" "i16" "i32" "i64" "f" "d")))
              (apply 'append (mapcar (lambda (a)
                                       (mapcar (lambda (b)
                                                 (concat a "to" b))
                                               (remove a types)))
                                     types))) t) "\\>")
      '(1 font-lock-type-face)))))

(font-lock-add-keywords 'extempore-mode
                        '(("(\\|)" . 'extempore-paren-face)))

(defvar extempore-font-lock-keywords
  (append extempore-font-lock-keywords-shared
	  extempore-font-lock-keywords-scheme
          extempore-font-lock-keywords-xtlang)
  "Expressions to highlight in extempore-mode.")

(defconst extempore-sexp-comment-syntax-table
  (let ((st (make-syntax-table extempore-mode-syntax-table)))
    (modify-syntax-entry ?\; "." st)
    (modify-syntax-entry ?\n " " st)
    (modify-syntax-entry ?#  "'" st)
    st))

(put 'lambda 'extempore-doc-string-elt 2)
;; Docstring's pos in a `define' depends on whether it's a var or fun def.
(put 'define 'extempore-doc-string-elt
     (lambda ()
       ;; The function is called with point right after "define".
       (forward-comment (point-max))
       (if (eq (char-after) ?\() 2 0)))

(defun extempore-font-lock-syntactic-face-function (state)
  (when (and (null (nth 3 state))
	     (eq (char-after (nth 8 state)) ?#)
	     (eq (char-after (1+ (nth 8 state))) ?\;))
    ;; It's a sexp-comment.  Tell parse-partial-sexp where it ends.
    (save-excursion
      (let ((pos (point))
	    (end
	     (condition-case err
		 (let ((parse-sexp-lookup-properties nil))
		   (goto-char (+ 2 (nth 8 state)))
		   ;; FIXME: this doesn't handle the case where the sexp
		   ;; itself contains a #; comment.
		   (forward-sexp 1)
		   (point))
	       (scan-error (nth 2 err)))))
	(when (< pos (- end 2))
	  (put-text-property pos (- end 2)
			     'syntax-table extempore-sexp-comment-syntax-table))
	(put-text-property (- end 1) end 'syntax-table '(12)))))
  ;; Choose the face to use.
  (lisp-font-lock-syntactic-face-function state))

(defvar calculate-lisp-indent-last-sexp)

;; FIXME this duplicates almost all of lisp-indent-function.
;; Extract common code to a subroutine.
(defun extempore-indent-function (indent-point state)
  "Extempore mode function for the value of the variable `lisp-indent-function'.
This behaves like the function `lisp-indent-function', except that:

i) it checks for a non-nil value of the property `extempore-indent-function'
\(or the deprecated `extempore-indent-hook'), rather than `lisp-indent-function'.

ii) if that property specifies a function, it is called with three
arguments (not two), the third argument being the default (i.e., current)
indentation."
  (let ((normal-indent (current-column)))
    (goto-char (1+ (elt state 1)))
    (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
    (if (and (elt state 2)
	     (not (looking-at "\\sw\\|\\s_")))
	;; car of form doesn't seem to be a symbol
	(progn
	  (if (not (> (save-excursion (forward-line 1) (point))
		      calculate-lisp-indent-last-sexp))
	      (progn (goto-char calculate-lisp-indent-last-sexp)
		     (beginning-of-line)
		     (parse-partial-sexp (point)
					 calculate-lisp-indent-last-sexp 0 t)))
	  ;; Indent under the list or under the first sexp on the same
	  ;; line as calculate-lisp-indent-last-sexp.  Note that first
	  ;; thing on that line has to be complete sexp since we are
	  ;; inside the innermost containing sexp.
	  (backward-prefix-chars)
	  (current-column))
      (let ((function (buffer-substring (point)
					(progn (forward-sexp 1) (point))))
	    method)
	(setq method (or (get (intern-soft function) 'extempore-indent-function)
			 (get (intern-soft function) 'extempore-indent-hook)))
	(cond ((or (eq method 'defun)
		   (and (null method)
			(> (length function) 3)
			(string-match "\\`def" function)))
	       (lisp-indent-defform state indent-point))
	      ((integerp method)
	       (lisp-indent-specform method state
				     indent-point normal-indent))
	      (method
		(funcall method state indent-point normal-indent)))))))


;;; 'let' is different in Scheme/xtlang

(defun would-be-symbol (string)
  (not (string-equal (substring string 0 1) "(")))

(defun next-sexp-as-string ()
  ;; Assumes that it is protected by a save-excursion
  (forward-sexp 1)
  (let ((the-end (point)))
    (backward-sexp 1)
    (buffer-substring (point) the-end)))

;; This is correct but too slow.
;; The one below works almost always.
;;(defun extempore-let-indent (state indent-point)
;;  (if (would-be-symbol (next-sexp-as-string))
;;      (extempore-indent-specform 2 state indent-point)
;;      (extempore-indent-specform 1 state indent-point)))

(defun extempore-let-indent (state indent-point normal-indent)
  (skip-chars-forward " \t")
  (if (looking-at "[-a-zA-Z0-9+*/?!@$%^&_:~]")
      (lisp-indent-specform 2 state indent-point normal-indent)
    (lisp-indent-specform 1 state indent-point normal-indent)))

;; (put 'begin 'extempore-indent-function 0), say, causes begin to be indented
;; like defun if the first form is placed on the next line, otherwise
;; it is indented like any other form (i.e. forms line up under first).

(put 'begin 'extempore-indent-function 0)
(put 'case 'extempore-indent-function 1)
(put 'delay 'extempore-indent-function 0)
(put 'dotimes 'extempore-indent-function 1)
(put 'lambda 'extempore-indent-function 1)
(put 'bind-func 'extempore-indent-function 'defun)
(put 'let 'extempore-indent-function 'extempore-let-indent)
(put 'let* 'extempore-indent-function 'extempore-let-indent)
(put 'letrec 'extempore-indent-function 'extempore-let-indent)
;; (put 'let-values 'extempore-indent-function 1) ; SRFI 11
;; (put 'let*-values 'extempore-indent-function 1) ; SRFI 11
;; (put 'sequence 'extempore-indent-function 0) ; SICP, not r4rs
(put 'let-syntax 'extempore-indent-function 1)
(put 'letrec-syntax 'extempore-indent-function 1)
(put 'syntax-rules 'extempore-indent-function 1)
(put 'syntax-case 'extempore-indent-function 2) ; not r5rs

(put 'call-with-input-file 'extempore-indent-function 1)
(put 'with-input-from-file 'extempore-indent-function 1)
(put 'with-input-from-port 'extempore-indent-function 1)
(put 'call-with-output-file 'extempore-indent-function 1)
(put 'with-output-to-file 'extempore-indent-function 1)
(put 'with-output-to-port 'extempore-indent-function 1)
(put 'call-with-values 'extempore-indent-function 1) ; r5rs?
(put 'dynamic-wind 'extempore-indent-function 3) ; r5rs?


;; dealing with the (external) extempore process

(defun extempore-setup ()
  "Switch to a shell buffer in which the extempore process is
running. If no such buffer exists, open a new *extempore* buffer
and start a new extempore process.

The location of the extempore executable should be set with
`extempore-path'.

The arguments passed to extempore can be customised through the
variable `extempore-process-args'.

Currently, the existence of an existing extempore process is
determined by whether there is an *extempore* buffer."
  (interactive)
  (unless extempore-path
    (error "Error: `extempore-path' not set!"))
  ;; create a buffer for the shell & extempore processes
  (unless (get-buffer "*extempore*")
    (progn (shell "*extempore*")
           (sit-for 1)
           (process-send-string "*extempore*"
                                (concat "cd " extempore-path "\n"
                                        (if (string-equal system-type "windows-nt") "" "./")
                                        "extempore --device "
                                        (read-from-minibuffer "Device number: ") "\n"))))
  (display-buffer "*extempore*"))

(defun extempore-default-process-filter (proc str)
  (message (substring str 0 -1)))

;;; SLIP escape codes
;; END       ?\300    /* indicates end of packet */
;; ESC       ?\333    /* indicates byte stuffing */
;; ESC_END   ?\334    /* ESC ESC_END means END data byte */
;; ESC_ESC   ?\335    /* ESC ESC_ESC means ESC data byte */

;; todo need to write this function
(defun extempore-slip-process-filter (proc str)
  (message (substring str 0 -1)))

(defun extempore-connect (host port)
  "Connect to the running extempore process, which must
be running in another (shell-like) buffer."
  (interactive (let ((read-host (read-from-minibuffer
				  (concat "Hostname (default "
					  extempore-default-host
					  "):")))
		     (read-port (read-from-minibuffer
				  (concat "Port (default "
					  (number-to-string extempore-default-port)
					  "):"))))
		 (list (if (string-equal read-host "")
			   extempore-default-host
			 read-host)
		       (if (string-equal read-port "")
			   extempore-default-port
			 (string-to-number read-port)))))
  (if (not (null extempore-process))
      (delete-process extempore-process))
  (setq extempore-process
	(open-network-stream "extempore" nil
			     host
			     port))
  (set-process-filter extempore-process
		      'extempore-default-process-filter))

(defun extempore-stop ()
  "Terminate connection to the Extempore process"
  (interactive)
  (delete-process extempore-process)
  (setq extempore-process nil))

(defun extempore-send-definition ()
  "Send the enclosing top-level def to Extempore server for evaluation"
  (interactive)
  (save-excursion
    (mark-defun)
    (if extempore-process
        (let ((str (concat (buffer-substring (point) (mark))
                           "\r\n")))
          (process-send-string extempore-process str)
          (redisplay) ; flash the def like Extempore
	  (sleep-for .25)
	  ;; add to TR animation list, if appropriate
	  (if (extempore-inside-tr-defun-p)
	      (add-to-list 'extempore-tr-defun-list
			   (vector (extempore-fnsym-in-current-sexp)
				   (current-buffer)))))
      (message (concat "Buffer " (buffer-name) " is not connected to an Extempore process.  You can connect with C-x C-j")))))

(defun extempore-send-region ()
  "Send the current region to Extempore for evaluation"
  (interactive)
  (save-excursion
    (if mark-active
        (let ((start (region-beginning)) (end (region-end)))
          (unless (= (point) (region-beginning)) (exchange-point-and-mark))
          (while (re-search-forward "^[^\n;]*(" end t)
            (extempore-send-definition)
            (end-of-defun)))
      (message "Region not active."))))

(defun extempore-send-buffer ()
  "Send the current buffer to Extempore for evaluation"
  (interactive)
  (save-excursion
    (progn (goto-char (point-min))
           (set-mark (point-max)))
    (let ((start (region-beginning)) (end (region-end)))
      (while (re-search-forward "^[^\n;]*(" end t)
	(extempore-send-definition)
	(end-of-defun)))))

;; eldoc completion

(require 'eldoc)
;; (require 'thingatpt)

(defun extempore-fnsym-in-current-sexp ()
  (save-excursion
    (let ((argument-index (1- (eldoc-beginning-of-sexp))))
      ;; If we are at the beginning of function name, this will be -1.
      (when (< argument-index 0)
	(setq argument-index 0))
      ;; Don't do anything if current word is inside a string.
      (if (= (or (char-after (1- (point))) 0) ?\")
	  nil
	(current-word)))))

(make-variable-buffer-local 'eldoc-documentation-function)

;; currently doesn't actually return the symbol, but sends the request
;; which is echoed back through whichever process filter is active
(defun extempore-eldoc-documentation-function ()
  (if extempore-process
      (let ((fnsym (extempore-fnsym-in-current-sexp)))
        ;; send the documentation request
        (if fnsym (process-send-string
                   extempore-process
                   (concat "(get-eldoc-string "
                           fnsym
                           ")\r\n")))
        ;; always return nil, docstring comes back through the process
        ;; filter
        nil)))

;; misc bits and pieces

(defun xpb1 (name duration)
  (interactive "sName: \nsDuration: ")
  (insert (concat "(define " name
		  "\n  (lambda (beat dur)\n    "
		  "(callback (*metro* (+ beat (* .5 " duration "))) '"
		  name " (+ beat " duration ") " duration ")))\n\n"
		  "(" name " (*metro* 'get-beat 4) " duration ")")))

;; for greek symbol lambdas: from emacs-starter-kit

(if extempore-use-pretty-lambdas
    (font-lock-add-keywords
     nil `(("(?\\(lambda\\>\\)"
	    (0 (progn (compose-region (match-beginning 1) (match-end 1)
				      ,(make-char 'greek-iso8859-7 107))
		      nil))))))

;; temporal-recursion animations

(defun extempore-beginning-of-defun-function (&optional arg)
  (beginning-of-defun arg))

(defun extempore-end-of-defun-function (&optional arg)
  (end-of-defun arg))

;; these could all be made more elegant using (sexp-at-point) to read
;; in the actual s-expressions, but this is probably a bit quicker

(defun extempore-scheme-defun-name ()
  (save-excursion
    (looking-at "(\\(define-\\(\\|macro\\|instrument\\|sampler\\)\\)\\s-+\\([^ \t\n:]+\\)")
    (match-string 3)))

(defun extempore-inside-scheme-defun-p ()
  (save-excursion
    (extempore-beginning-of-defun-function)
    (extempore-scheme-defun-name)))

(defun extempore-xtlang-defun-name ()
  (save-excursion
    (looking-at "(\\(bind-\\(func\\|val\\|type\\|alias\\|poly\\|lib\\)\\)\\s-+\\([^ \t\n:]+\\)")
    (match-string 3)))

(defun extempore-inside-xtlang-defun-p ()
  (save-excursion
    (extempore-beginning-of-defun-function)
    (extempore-xtlang-defun-name)))

(defun extempore-inside-tr-defun-p ()
  (save-excursion
    (extempore-end-of-defun-function)
    (search-backward ")" nil t 2)
    (looking-at "(callback")))

(defun extempore-find-defn-bounds (name)
  "Find the definition of the function `name'."
  (save-excursion
    (goto-char (point-max))
    (if (re-search-backward
         (concat "(\\(\\(bind-func\\)\\|\\(define\\)\\)\\s-+" name "[ \t\n:]")
         nil t)
        (cons (match-beginning 0) (1- (match-end 0)))
      nil)))

;; maintain list of all the TR functions

(defvar extempore-tr-defun-list nil)

;; construct overlays

(defun extempore-make-tr-flash-overlay (name bounds)
  (if bounds
      (let ((overlay (make-overlay (car bounds)
                                   (cdr bounds)
                                   nil t nil)))
        ;; (overlay-put overlay 'face '(:inverse-video t))
        (overlay-put overlay 'evaporate t)
        overlay)))

(defun extempore-update-tr-flash-overlay (overlay flag)
  (if flag
      (overlay-put overlay 'face '(:inverse-video t))
    (if (equal (overlay-get overlay 'face) '(:inverse-video t))
        (overlay-put overlay 'face '(:inverse-video nil)))))

(defun extempore-make-tr-clock-overlay (name bounds)
  (if bounds
      (let* ((defun-start (car bounds))
             (overlay (make-overlay defun-start
                                    (1+ defun-start)
                                    nil t nil)))
        (overlay-put overlay 'face '(:underline t :overline t))
        (overlay-put overlay 'evaporate t)
        overlay)))

(defun extempore-update-tr-clock-overlay (overlay val beg end)
  (move-overlay overlay
                beg
                (max (1+ beg) (round (+ beg (* val (- end beg)))))))

(defvar extempore-tr-overlay-list nil
  "The currently animating TR overlay data.")

(defun extempore-delete-tr-overlays-for-name (name)
  (delete-if (lambda (a)
               (if (string-equal (aref a 0) name)
                   (progn (delete-overlay (aref a 1)) t)
                 nil))
             extempore-tr-overlay-list))

(defun extempore-add-tr-overlays (name period)
  (interactive "sfn name: \nnperiod: ")
  (extempore-delete-tr-overlays-for-name name)
  (let ((bounds (extempore-find-defn-bounds name)))
    (if bounds
        (add-to-list 'extempore-tr-overlay-list
                     (vector name
                             (extempore-make-tr-flash-overlay name bounds)
                             (extempore-make-tr-clock-overlay name bounds)
                             period
                             0.0)
                     t))))

;; animate the overlays

(defvar extempore-tr-animation-update-period (/ 1.0 20))

(defun extempore-update-tr-overlays ()
  (dolist (annot extempore-tr-overlay-list)
    ;; update counter
    (let* ((val (+ (aref annot 4)
                   (/ extempore-tr-animation-update-period (aref annot 3))))
           (flash-flag (> val 1.0))
           (val (mod val 1.0))
           (flash-overlay (aref annot 1)))
      (extempore-update-tr-flash-overlay flash-overlay flash-flag)
      (extempore-update-tr-clock-overlay (aref annot 2)
                                         val
                                         (overlay-start flash-overlay)
                                         (overlay-end flash-overlay))
      (aset annot 4 val))))

;; managing the animation timer

(defvar extempore-tr-animation-timer nil)

(defun extempore-tr-animation-running-p ()
  (and extempore-tr-animation-timer
       extempore-tr-overlay-list))

(defun extempore-cancel-tr-animation-timer ()
  (interactive)
  (message "Cancelling TR animiation timer.")
  (if extempore-tr-animation-timer
      (cancel-timer extempore-tr-animation-timer))
  (remove-overlays)
  (setq extempore-tr-animation-timer nil
        extempore-tr-overlay-list nil))

(defun extempore-start-tr-animation-timer ()
  (interactive)
  (if (extempore-tr-animation-running-p)
      (progn (message "Restarting TR animation timer.")
             (extempore-cancel-tr-animation-timer))
    (message "Starting TR animation timer."))
  (setq extempore-tr-animation-timer
        (run-with-timer 0
                        extempore-tr-animation-update-period
                        'extempore-update-tr-overlays)))

;; auto-detection of TR loops for animation

(defun extempore-tr-watcher-filter (proc str)
  (message (substring str 0 -1))
  (let ((buf (process-buffer proc)))
    (if buf
	(with-current-buffer buf
	  (let ((mtch (string-match "(begin-tr \\([^ \t\n:]+\\) \\([0-9.]+\\))" str))
		(tr-name (match-string 1 str))
		(tr-period (string-to-number (match-string 2 str))))
	    (extempore-add-tr-overlays tr-name tr-period))))))

(defun extempore-add-tr-watcher ()
  (if extempore-process
      (set-process-filter
       extempore-process
       'extempore-tr-watcher-filter)
    (message "Can't start TR watcher: not connected to an Extempore process.")))

(defun extempore-remove-tr-watcher ()
  (if extempore-process
      (set-process-filter
       extempore-process
       'extempore-default-process-filter)
    (message "Can't remove TR watcher: not connected to an Extempore process.")))

(defun extempore-start-tr-animation ()
  (interactive)
  (extempore-start-tr-animation-timer)
  (extempore-add-tr-watcher))

(defun extempore-stop-tr-animation ()
  (interactive)
  (extempore-cancel-tr-animation-timer)
  (extempore-add-tr-watcher))

(provide 'extempore)

;;; extempore.el ends here
