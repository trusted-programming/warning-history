BEGIN {
	n = 0
	old_context=""
	new_context=""
	warning_name=""
}
/^#\[Warning/ {
	if (n>0) {
		old_contexts[n]=old_context
		new_contexts[n]=new_context
		warning_names[n]=warning_name
	}
	n++
	warnings[$0] = warnings[$0] + 1
	warning_name=$0
	old_context=""
	new_context=""
	before=1
}
/^=== 19a3477889393ea2cdd0edcb5e6ab30c ===/ {
	before=0
}
! /^#\[Warning/ && ! /^=== 19a3477889393ea2cdd0edcb5e6ab30c ===/ {
	if (before) {
		old_context=old_context $0 
	} else {
		new_context=new_context $0
	}
}

END {
	old_contexts[n]=old_context
	new_contexts[n]=new_context
	warning_names[n]=warning_name
	n++
	# for (w in warnings) { print w, warnings[w] }
	for (i=1; i<n; i++) {
		print(old_contexts[i])> "" warning_names[i] ".warn-fix.txt.warn"
		print(new_contexts[i])> "" warning_names[i] ".warn-fix.txt.fix"
		print(old_contexts[i])> "clippy.warn-fix.txt.warn"
		print(new_contexts[i])> "clippy.warn-fix.txt.fix"
	}
}
