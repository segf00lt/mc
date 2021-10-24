# The mexpr grammar spec

sentence   ->  	{ system }

		statement

statement  -> 	operation

             	statement > operation

	     	statement < operation

	     	statement == operation

	     	statement != operation

             	statement >= operation

	     	statement <= operation

system	   -> 	equation

	     	system ; equation

equation   -> 	operation = operation

operation  ->	expression

		~ operation

		operation | expression

		operation & expression

		operation ^ expression

expression ->	term

		expression + term

		expression - term

term	   ->	factor

		term * factor

		term / factor

factor	   ->	number

		variable

		( statement )
