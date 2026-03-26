;; extends

(enum_item) @item.outer

; (generic_environment) @environment.outer

((generic_environment
  begin: (begin
    name: (curly_group_text
      text: (text
        word: (word) @box_env)))
  (#match? @box_env "^(defn|thm|prop|lem|cor)$")))

((generic_environment
  begin: (begin
    name: (curly_group_text
      text: (text
        word: (word) @exercise)))
  (#match? @exercise "^(Exercise)$")))

(generic_environment
  begin: (begin
		   name: (curly_group_text
				   text: (text
						   word: (word) @proof_and_example_env)))
  (#match? @proof_and_example_env "^(Proof|example)$"))

; For proof environments
(generic_environment
  begin: (begin
    name: (curly_group_text
      text: (text
        word: (word) @proof_env)))
  end: (end
    name: (curly_group_text
      text: (text
        word: (word) @proof_end)))
  (#match? @proof_env "^(Proof)$")
  (#match? @proof_end "^(Proof)$"))

; For proof environments
(generic_environment
  begin: (begin
    name: (curly_group_text
      text: (text
        word: (word) @example_env)))
  end: (end
    name: (curly_group_text
      text: (text
        word: (word) @example_end)))
  (#match? @example_env "^(example)$")
  (#match? @example_end "^(example)$"))

end: (end
  name: (curly_group_text
	text: (text
	  word: (word) @proof_and_example_end))
  (#match? @proof_end "^(Proof)$"))

end: (end
  name: (curly_group_text
	text: (text
	  word: (word) @proof_and_example_end))
  (#match? @example_end "^(example)$"))

(chapter) @chapter



; examples in other peoples dot-files
; ((subject) @comment.error
;   (#vim-match? @comment.error ".\{50,}")
;   (#offset! @comment.error 0 50 0 0))
;
; ((message_line) @comment.error
;   (#vim-match? @comment.error ".\{72,}")
;   (#offset! @comment.error 0 72 0 0))
