;; Draft from the plan-only thread's report. TESTED on Guix 1.4.0 only (built Idris2 0.7.0
;; and regenerated enaction-engine's ABI files byte-identically). NOT tested against Guix
;; master or commit 37d0e81. The build is not bit-reproducible (17 compiled Chez .so differ).
;; The seed idris2.ss is a generated artefact, not bootstrappable from first principles.
;; The licence line is an unconfirmed assumption: check Idris2's LICENSE before publishing.
(define-module (estate packages idris)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages chez)
  #:use-module (gnu packages multiprecision))

(define-public idris2-0.7.0
  (package
    (name "idris2")
    (version "0.7.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/idris-lang/Idris2")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32 "0qxfwsm2gxjxwzni85jb5b4snvjf77knqs9bnd2bqznrfxgxw2sp"))))
    (build-system gnu-build-system)
    (arguments
     (list #:tests? #f
           #:make-flags
           #~(list (string-append "PREFIX=" #$output)
                   "SCHEME=chez-scheme"
                   "CC=gcc")
           #:phases
           #~(modify-phases %standard-phases
               (delete 'configure)
               (add-after 'unpack 'patch-shebangs-of-bootstrap
                 (lambda _
                   (patch-shebang "bootstrap-stage1-chez.sh")
                   (patch-shebang "bootstrap-stage2.sh")))
               (replace 'build
                 (lambda* (#:key make-flags #:allow-other-keys)
                   (apply invoke "make" "bootstrap" make-flags)))
               (replace 'install
                 (lambda* (#:key make-flags #:allow-other-keys)
                   (apply invoke "make" "install" make-flags)))
               (add-after 'install 'drop-build-tree-reference
                 (lambda* (#:key outputs #:allow-other-keys)
                   (for-each
                    (lambda (f)
                      (let ((p (string-append #$output "/bin/idris2_app/" f)))
                        (when (file-exists? p) (delete-file p))))
                    (list "compileChez" "idris2-boot.ss" "idris2-boot.so"))))
               (add-after 'install 'wrap
                 (lambda _
                   (wrap-program (string-append #$output "/bin/idris2")
                     `("CHEZ" = (,(string-append #$(this-package-input "chez-scheme")
                                                 "/bin/chez-scheme")))))))))
    (inputs (list chez-scheme gmp))
    (home-page "https://www.idris-lang.org/")
    (synopsis "Dependently typed functional programming language")
    (description
     "Idris 2, built via its Chez Scheme code generator, from the project's
checked-in Scheme bootstrap (a generated seed).")
    (license license:bsd-3)))
