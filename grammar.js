/**
 * @file TS grammar for Monkey-odin
 * @author TESTMECS
 */
/// <reference types="tree-sitter-cli/dsl" />
// @ts-check
const PREC = {
  // Precedence table: Higher numbers bind tighter
  lowest: 0,
  assignment: 1, // =
  arrow: 2, // ->
  logic: 3, // ||, &&
  equals: 4, // ==, !=
  lessgreater: 5, // <, >
  sum: 6, // +, -
  product: 7, // *, /, %
  prefix: 8, // -X, !X
  call: 9, // myFunc(x)
  index: 10, // array[index]
};

module.exports = grammar({
  name: "monkey",

  extras: ($) => [
    $.comment,
    /\s/, // Whitespace
  ],
  conflicts: ($) => [[$.block, $.hash_literal]],

  rules: {
    source_file: ($) => repeat($._statement),

    // --- Statements ---
    _statement: ($) =>
      choice(
        $.let_statement,
        $.return_statement,
        $.for_statement,
        $.foreach_statement,
        // If expressions are also valid statements in Monkey (like Rust/Ruby)
        $.expression_statement,
        $.block,
      ),

    block: ($) => seq("{", repeat($._statement), "}"),

    let_statement: ($) =>
      seq(
        "let",
        field("name", $.identifier),
        "=",
        field("value", $._expression),
        // Use 'optional' for the semicolon, but ensuring it's consumed if present
        optional(";"),
      ),

    return_statement: ($) =>
      seq("return", field("value", $._expression), optional(";")),

    // Wraps expressions so they can stand alone (e.g., "fibonacci(5);")
    expression_statement: ($) => seq($._expression, optional(";")),

    for_statement: ($) =>
      seq(
        "for",
        "(",
        field("condition", $._expression),
        ")",
        field("body", $.block),
      ),

    foreach_statement: ($) =>
      seq(
        "foreach",
        field("variable", $.identifier),
        "in",
        field("collection", $._expression),
        field("body", $.block),
      ),

    // --- Expressions ---
    _expression: ($) =>
      choice(
        $.assignment_expression,
        $.identifier,
        $.integer,
        $.float,
        $.boolean,
        $.string,
        $.array_literal,
        $.hash_literal,
        $.function_definition,
        $.call_expression,
        $.arrow_expression,
        $.unary_expression,
        $.binary_expression,
        $.index_expression,
        $.if_expression,
        $.grouped_expression,
      ),
    assignment_expression: ($) =>
      prec.right(
        PREC.assignment,
        seq(field("left", $._expression), "=", field("right", $._expression)),
      ),
    // Defines "fn(x, y) { ... }"
    function_definition: ($) =>
      seq("fn", field("parameters", $.parameter_list), field("body", $.block)),

    parameter_list: ($) =>
      seq(
        "(",
        optional(seq($.identifier, repeat(seq(",", $.identifier)))),
        ")",
      ),

    // Defines "myFunc(a, b)"
    call_expression: ($) =>
      prec(
        PREC.call,
        seq(
          field("function", $._expression), // Allows calling expressions, e.g., fn(x){x}(1)
          field("arguments", $.argument_list),
        ),
      ),

    argument_list: ($) =>
      seq(
        "(",
        optional(seq($._expression, repeat(seq(",", $._expression)))),
        ")",
      ),

    // Defines "readf->file" or "sum->arr"
    arrow_expression: ($) =>
      prec.left(
        PREC.arrow,
        seq(field("left", $._expression), "->", field("right", $._expression)),
      ),

    // Defines "arr[i]"
    index_expression: ($) =>
      prec(
        PREC.index,
        seq(
          field("operand", $._expression),
          "[",
          field("index", $._expression),
          "]",
        ),
      ),

    unary_expression: ($) =>
      prec(
        PREC.prefix,
        seq(
          field("operator", choice("!", "-", "~")),
          field("operand", $._expression),
        ),
      ),

    binary_expression: ($) =>
      choice(
        prec.left(PREC.logic, seq($._expression, "||", $._expression)),
        prec.left(PREC.logic, seq($._expression, "&&", $._expression)),
        prec.left(PREC.equals, seq($._expression, "==", $._expression)),
        prec.left(PREC.equals, seq($._expression, "!=", $._expression)),
        prec.left(PREC.lessgreater, seq($._expression, "<", $._expression)),
        prec.left(PREC.lessgreater, seq($._expression, ">", $._expression)),
        prec.left(PREC.sum, seq($._expression, "+", $._expression)),
        prec.left(PREC.sum, seq($._expression, "-", $._expression)),
        prec.left(PREC.product, seq($._expression, "*", $._expression)),
        prec.left(PREC.product, seq($._expression, "/", $._expression)),
        prec.left(PREC.product, seq($._expression, "%", $._expression)),
        // Bitwise
        prec.left(PREC.sum, seq($._expression, "|", $._expression)),
        prec.left(PREC.sum, seq($._expression, "^", $._expression)),
        prec.left(PREC.product, seq($._expression, "&", $._expression)),
        prec.left(PREC.product, seq($._expression, "<<", $._expression)),
        prec.left(PREC.product, seq($._expression, ">>", $._expression)),
      ),

    if_expression: ($) =>
      seq(
        "if",
        "(",
        field("condition", $._expression),
        ")",
        field("consequence", $.block),
        optional(seq("else", field("alternative", $.block))),
      ),

    grouped_expression: ($) => seq("(", $._expression, ")"),

    // --- Literals ---
    identifier: ($) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    integer: ($) => /\d+/,

    float: ($) => /\d+\.\d+/,

    boolean: ($) => choice("true", "false"),

    string: ($) =>
      seq(
        '"',
        repeat(
          choice(
            /[^"\\\n]+/, // Non-escaped characters
            /\\./, // Escaped characters
          ),
        ),
        '"',
      ),

    array_literal: ($) =>
      seq(
        "[",
        optional(seq($._expression, repeat(seq(",", $._expression)))),
        "]",
      ),

    hash_literal: ($) =>
      seq("{", optional(seq($.hash_pair, repeat(seq(",", $.hash_pair)))), "}"),

    hash_pair: ($) =>
      seq(field("key", $._expression), ":", field("value", $._expression)),

    comment: ($) =>
      token(
        choice(
          /#.*/, // NEW: Matches # comments (also handles shebangs)
          /\/\/.*/, // Keep // if you want to support both
          /\/\*[\s\S]*?\*\//, // Keep /* */ if you want to support both
        ),
      ),
  },
});
