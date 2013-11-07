parser grammar QuestionsParser;

options {
tokenVocab = QuestionsLexer;
}

@header {
package rezitests;
}

question returns [Question q]
@init {
	List<Question.Option> options = new ArrayList<Question.Option>();
}
	:	Q_NR title
		(option
		{options.add(new Question.Option($option.ID, $option.str, $option.strikethrough));}
		)+
		answer

		{$q = new Question($Q_NR.int, $title.str, $title.strikethrough, options,
				$answer.str, $answer.strikethrough);}
	;

title returns [String str, boolean strikethrough]
@init	{$strikethrough = false;}
@after	{$str = $t.text;}
	:	t=Q_TITLE
	|	S_ST t=Q_TITLE S_END {$strikethrough = true;}
	;

option returns [String ID, String str, boolean strikethrough]
@init	{$strikethrough = false;}
@after	{$ID = $n.text; $str = $t.text;}
	:	n=OPT_NAME t=OPT_TEXT
	|	S_ST n=OPT_NAME t=OPT_TEXT S_END {$strikethrough=true;}
	;

answer returns [String str, boolean strikethrough]
@init	{$strikethrough = false;}
@after	{$str = $a.text;}
	:	a=ANSWER
	|	S_ST a=ANSWER S_END {$strikethrough = true;}
	;

questions returns [List<Question> l]
@init {
	l = new ArrayList<Question>();
}
	:	TABLE_START
		(question {l.add($question.q);})+
		TABLE_END
	;
