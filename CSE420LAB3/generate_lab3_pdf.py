from pathlib import Path
import re

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import PageBreak, Paragraph, Preformatted, SimpleDocTemplate, Spacer


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "Lab3_Code_Explanation.pdf"

FILES = [
    "22101235_22101870.l",
    "22101235_22101870.y",
    "symbol_info.h",
    "scope_table.h",
    "symbol_table.h",
]


PDF_SUMMARY = [
    "The assignment PDF asks for semantic analysis on top of the earlier syntax analyzer. "
    "This repository implements that pipeline in the standard Flex/Bison shape: Flex scans "
    "raw source code into tokens, Bison parses those tokens with grammar rules, and semantic "
    "checks run inside the parser actions.",
    "The code is checked in three stages. First, the lexer checks lexemes such as identifiers, "
    "numbers, keywords, operators, punctuation, whitespace, and newlines. Second, the parser "
    "checks whether the token sequence matches the grammar. Third, the semantic actions and "
    "symbol-table lookups validate declarations, scopes, assignments, array indexing, function "
    "calls, and type consistency.",
]


FLOW_POINTS = [
    "Entry point: `main()` in `22101235_22101870.y` opens the input file, opens the log and error files, creates the symbol table, enters the global scope, and calls `yyparse()`.",
    "Lexical analysis: `22101235_22101870.l` uses Flex patterns to match lexemes and return tokens such as `ID`, `CONST_INT`, `CONST_FLOAT`, `ADDOP`, `MULOP`, `RELOP`, and `LOGICOP`.",
    "Parsing and semantic analysis: `22101235_22101870.y` defines grammar productions and embeds C++ actions that update attributes, query the symbol table, and report semantic errors.",
    "Symbol metadata: `symbol_info.h` stores what a symbol represents, including variable/array/function information, data type, return type, parameters, and array size.",
    "Scope and lookup: `scope_table.h` implements one hash-based scope table, and `symbol_table.h` manages the chain of scopes used during parsing.",
]


LEXEME_POINTS = [
    "Lexeme checks are made in `22101235_22101870.l`.",
    "The named Flex definitions on lines 19-26 define the legal shapes of whitespace, newlines, identifiers, integers, and floating-point literals.",
    "The rules on lines 30-99 map matching lexemes to parser tokens. Keywords return fixed tokens directly, while operators and literals often create a `symbol_info` object in `yylval` so the parser receives both the token kind and the text of the lexeme.",
    "The generated file `lex.yy.c` is only the C output produced by Flex from this `.l` file. The handwritten lexeme logic lives in the `.l` file.",
]


SEMANTIC_POINTS = [
    "Assignment compatibility and float-to-int warning are checked in `expression : variable ASSIGNOP logic_expression` at lines 598-618 of `22101235_22101870.y`.",
    "Array index type is checked in `variable : ID LTHIRD expression RTHIRD` at lines 559-588.",
    "Modulus integer-only rules and zero checks for modulus/division are handled in `term : term MULOP unary_expression` at lines 703-742 with `is_zero_literal()` from lines 81-89.",
    "Function-call argument count and type consistency are checked in `factor : ID LPAREN argument_list RPAREN` at lines 775-830.",
    "Void-valued expressions are rejected indirectly: function calls propagate return type, then later expression rules reject `void` operands in assignment, logic, relational, additive, and multiplicative expressions.",
    "Results of `LOGICOP` and `RELOP` are explicitly typed as `int` in lines 628-643 and 653-668.",
    "Duplicate variable declarations, void variable declarations, undeclared identifiers, array/non-array misuse, and wrong function usage are also checked in the parser and symbol-table lookups.",
]


FILE_INTROS = {
    "22101235_22101870.l": (
        "This Flex file defines token patterns and returns tokens to the parser. It is the place "
        "where raw characters become lexemes and then parser tokens."
    ),
    "22101235_22101870.y": (
        "This Bison file contains helper functions, grammar rules, semantic checks, logging, and "
        "the program entry point."
    ),
    "symbol_info.h": (
        "This header defines the data carried for each symbol. The parser uses it both as semantic "
        "attributes and as symbol-table entries."
    ),
    "scope_table.h": (
        "This header implements one scope as a hash table of `symbol_info*` entries, including lookup, "
        "insert, deletion, printing, and cleanup."
    ),
    "symbol_table.h": (
        "This header manages nested scopes and provides the parser-facing API for insert, lookup, "
        "scope entry, scope exit, and printing."
    ),
}


def html_escape(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def classify_l_line(line_no: int, line: str) -> str:
    stripped = line.strip()
    if not stripped:
        return "Blank line used to separate lexer sections."
    if stripped == "%%":
        return "Flex section separator. It splits definitions from rules, or rules from user code."
    if stripped.startswith("%option"):
        return "Flex option that disables the default `yywrap()` requirement."
    if stripped == "%{":
        return "Starts the C/C++ prologue copied into the generated lexer."
    if stripped == "%}":
        return "Ends the lexer prologue block."
    if stripped.startswith("#include"):
        return "Includes a dependency needed by the lexer."
    if stripped.startswith("#define YYSTYPE"):
        return "Makes the parser semantic value type `symbol_info*`."
    if stripped.startswith("extern "):
        return "Declares a variable or function provided from another translation unit."
    if stripped.startswith("void yyerror"):
        return "Declares the parser error-reporting function used across lexer/parser code."
    if re.match(r"^[a-zA-Z_]+\s", stripped) and "{" not in stripped:
        if line_no == 19:
            return "Defines the character class used as generic delimiters."
        if line_no == 20:
            return "Defines the newline pattern and accepts both Unix and Windows line endings."
        if line_no == 21:
            return "Defines one-or-more whitespace characters using the delimiter macro."
        if line_no == 22:
            return "Defines the first character allowed in an identifier."
        if line_no == 23:
            return "Defines one decimal digit."
        if line_no == 24:
            return "Defines the full identifier lexeme: letter/underscore followed by letters, underscores, or digits."
        if line_no == 25:
            return "Defines an integer literal lexeme as one or more digits."
        if line_no == 26:
            return "Defines floating-point literal forms accepted by this lexer."
    if stripped.startswith("{ws}"):
        return "Consumes whitespace lexemes and ignores them."
    if stripped.startswith("{newline}"):
        return "Consumes a newline lexeme and increments the global line counter."
    if re.match(r"^(if|else|for|while|do|break|continue|return|int|float|char|void|double|switch|case|default|printf)\b", stripped):
        return "Checks whether the current lexeme is this reserved keyword and returns the matching token."
    if stripped.startswith('"+"') or stripped.startswith('"*"') or stripped.startswith('"&&"') or stripped.startswith('"<"'):
        return "Checks a grouped operator lexeme, packages the matched text in `yylval`, and returns the operator token."
    if stripped.startswith('"++"') or stripped.startswith('"--"') or stripped.startswith('"="') or stripped.startswith('"!"') or stripped.startswith('"("') or stripped.startswith('")"') or stripped.startswith('"{"') or stripped.startswith('"}"') or stripped.startswith('"["') or stripped.startswith('"]"') or stripped.startswith('";"') or stripped.startswith('","'):
        return "Checks this exact punctuation/operator lexeme and returns the matching token."
    if stripped.startswith("{id}"):
        return "Checks an identifier lexeme, stores the actual text in `yylval`, and returns `ID`."
    if stripped.startswith("{integers}"):
        return "Checks an integer literal lexeme, stores the text in `yylval`, and returns `CONST_INT`."
    if stripped.startswith("{floats}"):
        return "Checks a floating-point literal lexeme, stores the text in `yylval`, and returns `CONST_FLOAT`."
    if "symbol_info *s = new symbol_info" in stripped:
        return "Creates a semantic-value object that carries the matched lexeme text to the parser."
    if "yylval = (YYSTYPE)s;" in stripped:
        return "Publishes the created semantic value so Bison can read it."
    if stripped.startswith("return "):
        return "Returns the token chosen by this lexer rule."
    if stripped == "{":
        return "Starts the action block for the lexer rule above."
    if stripped == "}":
        return "Ends the current lexer action block."
    return "Continues the current lexer definition or action."


def classify_header_line(path: str, line_no: int, line: str) -> str:
    stripped = line.strip()
    if not stripped:
        return "Blank line used to separate declarations and methods."
    if stripped.startswith("#include"):
        return "Includes a dependency required by this header."
    if stripped.startswith("using namespace std"):
        return "Makes the standard namespace directly available in this header."
    if stripped.startswith("class "):
        return "Starts the class definition."
    if stripped in {"private:", "public:"}:
        return f"Begins the `{stripped[:-1]}` section of the class."
    if stripped.startswith("//"):
        return "Comment describing intended design or behavior."
    if stripped == "{":
        return "Opens the class or function body."
    if stripped == "}":
        return "Closes the current class or function body."
    if stripped == "};":
        return "Ends the class definition."
    if re.match(r"^(string|bool|int|vector<|scope_table \*|symbol_info \*|ofstream )", stripped):
        return "Declares stored state used by this class or helper."
    if "(" in stripped and stripped.endswith(";"):
        return "Declares a constructor, method, or destructor interface."
    if "::" in stripped and stripped.endswith("{"):
        return "Starts the out-of-class method definition."
    if "return " in stripped:
        return "Returns the requested value from this helper or method."
    if "delete " in stripped:
        return "Releases dynamically allocated memory."
    if "lookup_in_scope" in stripped or "insert_in_scope" in stripped or "delete_from_scope" in stripped:
        return "Declares or uses a scope-table operation."
    if "print_scope_table" in stripped or "print_all_scopes" in stripped or "print_current_scope" in stripped:
        return "Declares or performs symbol-table printing."
    if "=" in stripped and stripped.endswith(";"):
        return "Assigns or initializes class state."
    if stripped.startswith("for ") or stripped.startswith("while ") or stripped.startswith("if "):
        return "Starts control flow used to implement the data-structure behavior."
    if stripped.startswith("for (") or stripped.startswith("while (") or stripped.startswith("if ("):
        return "Starts control flow used to implement the data-structure behavior."
    return "Continues the data-structure implementation."


def classify_y_line(line_no: int, line: str) -> str:
    stripped = line.strip()
    if not stripped:
        return "Blank line used to separate parser helpers, grammar rules, or actions."
    if stripped == "%{":
        return "Starts the Bison prologue copied into the generated parser."
    if stripped == "%}":
        return "Ends the Bison prologue."
    if stripped == "%%":
        return "Bison section separator between declarations, grammar rules, and user code."
    if stripped.startswith("#include"):
        return "Includes a dependency required by the parser and semantic actions."
    if stripped.startswith("#define YYSTYPE"):
        return "Tells Bison that semantic values are `symbol_info*`."
    if stripped.startswith("extern "):
        return "Declares a symbol supplied by another compilation unit."
    if stripped.startswith("int yyparse") or stripped.startswith("int yylex"):
        return "Declares the parser or lexer function."
    if stripped.startswith("symbol_table *st"):
        return "Creates the global symbol-table pointer used by semantic actions."
    if stripped.startswith("string current_type"):
        return "Stores the current declaration type while parsing declarations."
    if stripped.startswith("string currentFunction"):
        return "Tracks the function currently being defined."
    if stripped.startswith("vector<pair<string, string>> current_func_params"):
        return "Stores the parameter list of the function currently being processed."
    if stripped.startswith("vector<string> current_arg_types"):
        return "Stores argument types collected for the current function call."
    if stripped.startswith("set<string> func_done"):
        return "Tracks which function names have already been fully defined."
    if stripped.startswith("vector<string> pending_decl_duplicate_errors"):
        return "Buffers duplicate declaration names so they can be reported after a declaration statement completes."
    if stripped.startswith("int lines"):
        return "Initializes the shared source line counter."
    if stripped.startswith("int error_count"):
        return "Initializes the global semantic/syntax error counter."
    if stripped.startswith("ofstream outlog") or stripped.startswith("ofstream errlog"):
        return "Declares output streams for normal logs and error logs."
    if stripped.startswith("static const string ERROR_TYPE"):
        return "Defines the sentinel type used to propagate semantic failure safely."
    if stripped.startswith("void report_error"):
        return "Starts the helper that writes a formatted error message and increments the error counter."
    if stripped.startswith("void yyerror"):
        return "Starts the standard Bison error callback and forwards syntax errors into the same reporting path."
    if stripped.startswith("symbol_info *lookup_symbol"):
        return "Starts a helper that searches the whole visible scope chain."
    if stripped.startswith("symbol_info *lookup_current_scope_symbol"):
        return "Starts a helper that searches only the current scope."
    if stripped.startswith("bool is_error_type") or stripped.startswith("bool is_float_type") or stripped.startswith("bool is_int_type") or stripped.startswith("bool is_void_type"):
        return "Starts a small type-predicate helper used by semantic checks."
    if stripped.startswith("bool is_zero_literal"):
        return "Starts the helper used to detect literal zero in division/modulus checks."
    if stripped.startswith("string merged_numeric_type"):
        return "Starts the helper that computes the resulting numeric type of arithmetic expressions."
    if stripped.startswith("void set_symbol_type"):
        return "Starts the helper that writes a semantic type into a `symbol_info` object."
    if stripped.startswith("void flush_pending_declaration_errors"):
        return "Starts the helper that flushes buffered duplicate-declaration errors."
    if stripped.startswith("%token"):
        return "Declares the tokens the parser expects from the lexer."
    if stripped.startswith("%nonassoc"):
        return "Declares precedence/associativity information used to resolve grammar ambiguity."
    if stripped == "{":
        return "Opens the action block or function body."
    if stripped == "}":
        return "Closes the current action block or function body."
    if stripped == ";":
        return "Ends the current grammar rule."
    if re.match(r"^[a-z_]+\s*:", stripped):
        return "Starts a grammar production for this nonterminal."
    if stripped.startswith("|"):
        return "Begins an alternative production for the same nonterminal."
    if stripped.startswith("outlog<<") or stripped.startswith('outlog <<'):
        return "Writes a trace entry showing the reduction or current derived text."
    if stripped.startswith("errlog<<") or stripped.startswith('errlog <<'):
        return "Writes directly into the error log."
    if stripped.startswith("report_error("):
        return "Emits a semantic error or warning for the condition detected in this action."
    if "lookup_symbol(" in stripped or "lookup_current_scope_symbol(" in stripped:
        return "Queries the symbol table to validate a declaration or use."
    if "st->insert(" in stripped:
        return "Inserts a symbol into the current scope."
    if "st->enter_scope()" in stripped:
        return "Creates and enters a new nested scope."
    if "st->exit_scope()" in stripped:
        return "Leaves the current scope after finishing the compound statement."
    if "set_symbol_type(" in stripped:
        return "Assigns the semantic type that this parser node should carry upward."
    if stripped.startswith("$$ ="):
        return "Creates the synthesized semantic value for the left-hand side of this production."
    if stripped.startswith("if (") or stripped.startswith("else if") or stripped == "else":
        return "Starts semantic control flow that decides whether to report an error or set a type."
    if stripped.startswith("for ("):
        return "Starts iteration used to process parameters, arguments, or buffered errors."
    if stripped.startswith("return "):
        return "Returns from the current helper or from `main()`."
    if stripped.startswith("yyin = fopen"):
        return "Opens the input source file that will be compiled."
    if stripped.startswith("outlog.open") or stripped.startswith("errlog.open"):
        return "Opens the output files used by the analyzer."
    if stripped.startswith("yyparse();"):
        return "Starts parsing, which triggers both syntax analysis and semantic checks."
    if stripped.startswith("delete st;"):
        return "Destroys the symbol table and all remaining scopes."
    if stripped.startswith("fclose(yyin);"):
        return "Closes the input source file."
    return "Continues the current parser helper, grammar rule, or semantic action."


def line_explanation(path: str, line_no: int, line: str) -> str:
    if path.endswith(".l"):
        return classify_l_line(line_no, line)
    if path.endswith(".y"):
        return classify_y_line(line_no, line)
    return classify_header_line(path, line_no, line)


def add_heading(story, styles, text, level=1):
    style_name = f"Heading{level}"
    story.append(Paragraph(html_escape(text), styles[style_name]))
    story.append(Spacer(1, 0.10 * inch))


def add_bullets(story, styles, items):
    for item in items:
        story.append(Paragraph("&#8226; " + html_escape(item), styles["Body"]))
        story.append(Spacer(1, 0.05 * inch))


def build_story():
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(
        name="TitleCenter",
        parent=styles["Title"],
        alignment=TA_CENTER,
        textColor=colors.HexColor("#1f2937"),
        spaceAfter=14,
    ))
    styles.add(ParagraphStyle(
        name="Body",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=9,
        leading=12,
        spaceAfter=4,
    ))
    styles.add(ParagraphStyle(
        name="CodeLine",
        parent=styles["Code"],
        fontName="Courier",
        fontSize=7.2,
        leading=8.8,
        leftIndent=8,
        textColor=colors.HexColor("#111827"),
    ))
    styles["Heading1"].fontSize = 16
    styles["Heading1"].leading = 18
    styles["Heading2"].fontSize = 12
    styles["Heading2"].leading = 14
    styles["Heading3"].fontSize = 10
    styles["Heading3"].leading = 12

    story = []
    story.append(Paragraph("Lab 3 Code Explanation and Semantic Analysis Walkthrough", styles["TitleCenter"]))
    story.append(Paragraph("Repository: d:\\CSE420LAB3", styles["Body"]))
    story.append(Spacer(1, 0.15 * inch))

    add_heading(story, styles, "1. Lab Objective Summary", 1)
    for paragraph in PDF_SUMMARY:
        story.append(Paragraph(html_escape(paragraph), styles["Body"]))
    story.append(Spacer(1, 0.1 * inch))

    add_heading(story, styles, "2. End-to-End Code Flow", 1)
    add_bullets(story, styles, FLOW_POINTS)

    add_heading(story, styles, "3. Where Lexeme Checks Happen", 1)
    add_bullets(story, styles, LEXEME_POINTS)

    add_heading(story, styles, "4. Mapping the PDF Semantic Checks to the Code", 1)
    add_bullets(story, styles, SEMANTIC_POINTS)

    add_heading(story, styles, "5. Where the Full Code Is Checked", 1)
    add_bullets(story, styles, [
        "The full source program is first checked lexically in `22101235_22101870.l`, where individual lexemes are recognized.",
        "The full token stream is then checked syntactically in `22101235_22101870.y`, where grammar productions accept or reject the structure.",
        "The same parser file also performs the full semantic checking through symbol lookups and type rules during reductions.",
        "The symbol-table files do not parse source text directly; they support the parser by storing declarations and scope information used in those checks.",
    ])

    add_heading(story, styles, "6. Line-by-Line Explanation", 1)
    story.append(Paragraph(
        "The next sections explain every line of the handwritten source files. Blank lines are also recorded so the document remains truly line-by-line.",
        styles["Body"],
    ))

    for path_name in FILES:
        path = ROOT / path_name
        lines = path.read_text(encoding="utf-8").splitlines()
        story.append(PageBreak())
        add_heading(story, styles, f"File: {path_name}", 2)
        story.append(Paragraph(html_escape(FILE_INTROS[path_name]), styles["Body"]))
        story.append(Spacer(1, 0.08 * inch))

        for i, raw in enumerate(lines, start=1):
            code = raw if raw else "<blank>"
            explanation = line_explanation(path_name, i, raw)
            text = f"{i:>4} | {code}\n      Explanation: {explanation}"
            story.append(Preformatted(text, styles["CodeLine"]))
            story.append(Spacer(1, 0.03 * inch))

    story.append(PageBreak())
    add_heading(story, styles, "7. Conclusion", 1)
    for paragraph in [
        "The lexer file is the answer to the lexeme-check question: that is where identifier, number, keyword, operator, punctuation, whitespace, and newline checks are written.",
        "The parser file is the answer to the semantic-check question: that is where declaration checks, assignment checks, array-index checks, function-call checks, and type propagation are implemented.",
        "The symbol-table headers provide the storage and lookup behavior that make those semantic checks possible.",
    ]:
        story.append(Paragraph(html_escape(paragraph), styles["Body"]))

    return story


def add_page_number(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#4b5563"))
    canvas.drawRightString(A4[0] - 36, 20, f"Page {doc.page}")
    canvas.restoreState()


def main():
    doc = SimpleDocTemplate(
        str(OUTPUT),
        pagesize=A4,
        rightMargin=36,
        leftMargin=36,
        topMargin=40,
        bottomMargin=30,
        title="Lab 3 Code Explanation",
        author="OpenAI Codex",
    )
    story = build_story()
    doc.build(story, onFirstPage=add_page_number, onLaterPages=add_page_number)
    print(f"Generated {OUTPUT}")


if __name__ == "__main__":
    main()
