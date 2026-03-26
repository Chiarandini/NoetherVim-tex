;extends

(
  (generic_environment
    begin: (begin
      name: (curly_group_text
        (text (word) @env_name)
      )
    )
    (curly_group)
    (curly_group
      (text) @texTheoremTag
    )
  )
  (#match? @env_name "^(defn|prop|thm|lem|titledBox|cor|example)$")
)

; this was an attempt at highlithing the } in frac{(}{} as error to more easily identify it
(generic_command
  command: (command_name) @cmd_name
  (#eq? @cmd_name "\\frac")
  arg: (curly_group
    "}" @error
  ) @frac_arg
  (#match? @frac_arg "[(][^)]*$")
  (#set! "priority" 128)
)
