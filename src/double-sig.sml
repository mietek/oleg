local
    type 'a binder  = bindSort * visSort * frzLocGlob * string list * string list * 'a
    type  'a ctxt = 'a binder list
in
    signature DOUBLE =
	sig
	    type cnstr_c
	    val do_inductive_type_double 
		: bool -> cnstr_c ctxt -> cnstr_c ctxt -> cnstr_c ctxt -> bool -> cnstr_c 
                -> cnstr_c ctxt * cnstr_c
	end
end
