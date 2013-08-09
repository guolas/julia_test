module prueba
using Base.Grisu
export @printf, @sprintf

### external printf interface ###

_is_str_expr(ex) =
isa(ex,Expr) && ex.head==:macrocall && isa(ex.args[1],Symbol) &&
(ex.args[1] == :str || endswith(string(ex.args[1]),"_str"))

macro printf(args...)
  if length(args) == 0
    error("@printf: called with zero arguments")
  end
  if !isa(args[1],String) && !(length(args) > 1 && isa(args[2],String))
    if _is_str_expr(args[1]) || length(args) > 1 && _is_str_expr(args[2])
      error("format must be a plain static string (no interpolation or prefix)")
    end
    error("first or second argument must be a format string")
  end
  local io, fmt
  if isa(args[1],String)
    io = :(Base.STDOUT)
    args = args[1:]
  else
    io = args[1]
    args = args[2:]
  end
  args_type = typeof(args) 
  at = Expr(:tuple)
  at.args = Array(Any,length(args_type))
  at.args[1] = Expr(:curly)
  at.args[1].args = Array(Any, 2)
  at.args[1].args[1] = :Ptr
  at.args[1].args[2] = :Uint8
  for ii in 2:length(args_type)
    at.args[ii] = symbol("$(args_type[ii])")
  end

#   ex = :(ccall( (:printf, "libc"), Int32, $at, $(args...)) )
#   eval(ex)

  return args_type, args, at
end

macro sprintf(args...)
  :(sprint(io->@printf(io,$(map(esc,args)...))))
end

end # module
