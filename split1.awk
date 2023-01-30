BEGIN {
	n = 0
	old_context=""
	new_context=""
	warning_name=""
}
/^##\[Warning/ {
	if (n>0) {
		old_contexts[n]=old_context
		new_contexts[n]=new_context
		warning_names[n]=warning_name
	}
	n++
	warnings[$0] = warnings[$0] + 1
	warning_name=$0
	old_context=$0
	new_context=warning_name
	before=1
}
/^=== 19a3477889393ea2cdd0edcb5e6ab30c ===/ {
	before=0
}
! /^##\[Warning/ && ! /^=== 19a3477889393ea2cdd0edcb5e6ab30c ===/ {
	if (before) {
		old_context=old_context "\n" $0 
	} else {
		new_context=new_context "\n" $0
	}
}

END {
	old_contexts[n]=old_context
	new_contexts[n]=new_context
	warning_names[n]=warning_name
	n++
	for (i=1; i<n; i++) {
		print(old_contexts[i])> "" warning_names[i] ".cs-java.txt.cs"
		print(new_contexts[i])> "" warning_names[i] ".cs-java.txt.java"
		print(old_contexts[i])> "clippy.cs-java.txt.cs"
		print(new_contexts[i])> "clippy.cs-java.txt.java"
	}
	print "please split clippy.cs-java-txt.[cs|java] further into train, valid, test datasets."
}
