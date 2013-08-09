module prueba
export printf, sprintf

### external printf interface ###
function printf(args...)
  if length(args) == 0
    error("printf: called with zero arguments")
  end
  str_out = Array(Uint8, 100)
  args = tuple(str_out, args...)

  args_type = typeof(args) 

  at = Expr(:tuple)
  at.args = Array(Any,length(args_type))

  at.args[1] = Expr(:curly)
  at.args[1].args = Array(Any, 2)
  at.args[1].args[1] = :Ptr
  at.args[1].args[2] = :Uint8

  at.args[2] = Expr(:curly)
  at.args[2].args = Array(Any, 2)
  at.args[2].args[1] = :Ptr
  at.args[2].args[2] = :Uint8

  for ii in 3:length(args_type)
    at.args[ii] = symbol("$(args_type[ii])")
  end

  ex = :(ccall( (:sprintf, "libc"), Int32, $at, $(args...)) )
  str_len = eval(ex)

  print(bytestring(str_out[1:str_len]))

#  return at, args, str_out
end

function sprintf(args...)
end

end # module
