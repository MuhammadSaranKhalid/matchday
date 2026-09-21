#!/usr/bin/env python3
"""Format migrations without changing statement order or parsed SQL.

Requires the pinned Node dependencies and requirements-format.txt. See
docs/database/migration-style.md for installation and usage.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

from pglast import parser


ROOT = Path(__file__).resolve().parents[2]
COMMENT_TOKENS = {"SQL_COMMENT", "C_COMMENT"}
GENERATED_COMMENT = re.compile(r"-- (?:Migration file:|Migration:|Section:) .*")
SECTION_NAMES = {
    "Prerequisites", "Tables and constraints", "Enable row-level security",
    "Indexes", "Functions", "Triggers", "Policies", "Permissions", "Views",
    "Data changes", "Integrations", "Dependency-ordered operations", "Object documentation",
}
POSITION_FIELDS = {
    "location", "stmt_location", "stmt_len", "list_start", "list_end",
    "rexpr_list_start", "rexpr_list_end",
}


def body_tokens(source):
    """Preserve literal values and quoted names inside SQL/PLpgSQL bodies."""
    result = []
    for token in parser.scan(source):
        if token.name in COMMENT_TOKENS:
            continue
        value = source[token.start : token.end + 1]
        if token.name == "SCONST":
            # Adjacent SQL string literals can have different indentation while
            # representing the exact same value. Compare the parsed constant.
            value = sql_ast("select " + value)["stmts"][0]["stmt"]
            result.append((token.name, value))
            continue
        if token.name not in {"SCONST", "BCONST", "XCONST", "ICONST", "FCONST"}:
            if not value.startswith('"'):
                value = value.lower()
        result.append((token.name, value))
    return result


def normalized_ast(value):
    """Ignore source positions, but compare every statement in original order."""
    if isinstance(value, list):
        return [normalized_ast(item) for item in value]
    if not isinstance(value, dict):
        return value
    # PostgreSQL stores quoted routine bodies as strings in the outer AST.
    # Compare their tokens too, including exact dynamic-SQL string literals.
    if value.get("defname") == "as":
        value = dict(value)
        argument = value["arg"]
        if "List" in argument:
            value["arg"] = [
                body_tokens(item["String"]["sval"])
                for item in argument["List"]["items"]
            ]
        elif "String" in argument:
            value["arg"] = body_tokens(argument["String"]["sval"])
    return {
        key: normalized_ast(item)
        for key, item in value.items()
        if key not in POSITION_FIELDS
    }


def sql_ast(source):
    return normalized_ast(json.loads(parser.parse_sql_json(source)))


def section(statement, previous):
    kind, data = next(iter(statement.items()))
    if kind == "CommentStmt":
        return previous or "Object documentation"
    if kind in {"CreateExtensionStmt", "CreateSchemaStmt", "CreateEnumStmt", "CreateSeqStmt"}:
        return "Prerequisites"
    if kind == "AlterTableStmt":
        actions = [item["AlterTableCmd"]["subtype"] for item in data.get("cmds", [])]
        if actions and all(action in {"AT_EnableRowSecurity", "AT_ForceRowSecurity"} for action in actions):
            return "Enable row-level security"
        return "Tables and constraints"
    if kind in {"CreateStmt", "RenameStmt"}:
        return "Tables and constraints"
    if kind == "IndexStmt":
        return "Indexes"
    if kind == "CreateFunctionStmt":
        return "Functions"
    if kind == "CreateTrigStmt":
        return "Triggers"
    if kind == "CreatePolicyStmt":
        return "Policies"
    if kind == "GrantStmt":
        # Keep function permissions beside their definitions.
        if data.get("objtype") in {"OBJECT_FUNCTION", "OBJECT_PROCEDURE", "OBJECT_ROUTINE"}:
            return "Functions"
        return "Permissions"
    if kind == "AlterDefaultPrivilegesStmt":
        return "Permissions"
    if kind == "ViewStmt":
        return "Views"
    if kind in {"InsertStmt", "UpdateStmt", "DeleteStmt"}:
        target = data.get("relation", {})
        if target.get("schemaname") == "storage":
            return "Integrations"
        return "Data changes"
    if kind == "DropStmt":
        return {
            "OBJECT_FUNCTION": "Functions",
            "OBJECT_TRIGGER": "Triggers",
            "OBJECT_POLICY": "Policies",
            "OBJECT_TABLE": "Tables and constraints",
            "OBJECT_INDEX": "Indexes",
            "OBJECT_VIEW": "Views",
        }.get(data.get("removeType"), "Dependency-ordered operations")
    return "Dependency-ordered operations"


def strip_generated_comments(source):
    # Use the scanner so a matching line inside a dollar-quoted string is safe.
    for token in reversed(parser.scan(source)):
        value = source[token.start : token.end + 1]
        if token.name == "SQL_COMMENT" and (
            GENERATED_COMMENT.fullmatch(value)
            or value.removeprefix("-- ") in SECTION_NAMES
            or re.fullmatch(r"--\s*[-=]{3,}\s*", value)
            or re.fullmatch(
                r"--\s*(?:\d+[.)]\s*)?(?:Indexes|Triggers|Functions|Policies|Grants|RLS)\s*",
                value, re.IGNORECASE,
            )
        ):
            source = source[: token.start] + source[token.end + 1 :]
    return source


def split_parameters(source):
    """Put each CREATE FUNCTION parameter on its own line, including defaults."""
    tokens = list(parser.scan(source))
    edits = []
    for index, token in enumerate(tokens):
        if token.name != "FUNCTION":
            continue
        # Only declarations, never GRANT, DROP, or EXECUTE FUNCTION.
        previous = [t.name for t in tokens[max(0, index - 3) : index]]
        if not (previous[-1:] == ["CREATE"] or previous == ["CREATE", "OR", "REPLACE"]):
            continue
        cursor = index + 1
        while cursor < len(tokens) and tokens[cursor].name != "ASCII_40":
            cursor += 1
        opening = tokens[cursor]
        depth = 1
        start = opening.end + 1
        parameters = []
        cursor += 1
        while depth:
            current = tokens[cursor]
            if current.name in {"ASCII_40", "ASCII_91"}:
                depth += 1
            elif current.name in {"ASCII_41", "ASCII_93"}:
                depth -= 1
            if (current.name == "ASCII_44" and depth == 1) or depth == 0:
                parameters.append(source[start : current.start].strip())
                start = current.end + 1
            cursor += 1
        if any(parameters):
            replacement = "\n" + ",\n".join("  " + item for item in parameters) + "\n"
            edits.append((opening.end + 1, current.start, replacement))
    for start, end, replacement in reversed(edits):
        source = source[:start] + replacement + source[end:]
    return source


def align_table_columns(source):
    """Align types after the longest column name, including generated columns.

    PostgreSQL's column/type source positions include complex generated columns.
    """
    encoded = source.encode()
    edits = []
    for statement in json.loads(parser.parse_sql_json(source))["stmts"]:
        table = statement["stmt"].get("CreateStmt")
        if table is None:
            continue
        columns = []
        for element in table.get("tableElts", []):
            column = element.get("ColumnDef")
            if column is None:
                continue
            start = column["location"]
            end = column["typeName"]["location"]
            name = encoded[start:end].decode().strip()
            # Preserve an unusual comment between the name and type verbatim.
            if not re.fullmatch(r'"(?:""|[^"])+"|[^\W\d][\w$]*', name):
                continue
            columns.append((start, end, name))
        width = max((len(name) for _, _, name in columns), default=0) + 1
        edits.extend((start, end, name.ljust(width).encode()) for start, end, name in columns)
    for start, end, replacement in sorted(edits, reverse=True):
        encoded = encoded[:start] + replacement + encoded[end:]
    return encoded.decode()


def add_sections(source, filename):
    # Statement offsets from libpg_query are UTF-8 byte offsets; scanner offsets
    # are Python string offsets. Work in bytes when slicing whole statements.
    statements = json.loads(parser.parse_sql_json(source))["stmts"]
    encoded = source.encode()
    output = [f"-- {'=' * 77}\n-- Migration: {filename}\n-- {'=' * 77}"]
    previous = None
    start = 0
    for item in statements:
        end = item.get("stmt_location", 0) + item.get("stmt_len", 0)
        if not item.get("stmt_len"):
            end = len(encoded)
        elif encoded[end : end + 1] == b";":
            end += 1
        chunk = encoded[start:end].decode().strip()
        if start == 0:
            first_code = next(t for t in parser.scan(chunk) if t.name not in COMMENT_TOKENS)
            introduction = chunk[: first_code.start].strip()
            if introduction:
                output.append(introduction)
            chunk = chunk[first_code.start :]
        group = section(item["stmt"], previous)
        if group != previous:
            output.append(f"-- {'-' * 77}\n-- {group}\n-- {'-' * 77}")
        output.append(chunk)
        previous = group
        start = end
    tail = encoded[start:].decode().strip()
    if tail:
        output.append(tail)
    return "\n\n".join(output).rstrip() + "\n"


def preserve_multiline_literals(before, after, nested=False):
    """Preserve multiline string contents and nested dollar-quoted SQL exactly."""
    before_tokens = [t for t in parser.scan(before) if t.name == "SCONST"]
    after_tokens = [t for t in parser.scan(after) if t.name == "SCONST"]
    if len(before_tokens) != len(after_tokens):
        raise ValueError("formatter changed the number of string literals")
    for old, new in reversed(list(zip(before_tokens, after_tokens))):
        original = before[old.start : old.end + 1]
        formatted = after[new.start : new.end + 1]
        if original.startswith("$"):
            if nested:
                replacement = original
            else:
                old_delimiter = original[: original.index("$", 1) + 1]
                new_delimiter = formatted[: formatted.index("$", 1) + 1]
                body = preserve_multiline_literals(
                    original[len(old_delimiter) : -len(old_delimiter)],
                    formatted[len(new_delimiter) : -len(new_delimiter)], True,
                )
                replacement = new_delimiter + body + new_delimiter
        elif "\n" in original:
            replacement = original
        else:
            continue
        after = after[: new.start] + replacement + after[new.end + 1 :]
    return after


def restore_postgres_syntax(source):
    """Adapt two known SQL-CST 0.22.1 printing gaps; the AST gate stays mandatory."""
    tokens = [token for token in parser.scan(source) if token.name not in COMMENT_TOKENS]
    edits = []
    for index, token in enumerate(tokens[:-2]):
        # A policy expression consisting of a scalar subquery needs both the
        # policy-expression parentheses and the scalar-subquery parentheses.
        policy_query = token.name in {"USING", "CHECK"} and tokens[index + 1].name == "ASCII_40" and tokens[index + 2].name in {"SELECT", "WITH"}
        # PostgreSQL puts NULLS NOT DISTINCT before a UNIQUE constraint's list.
        unique = token.name == "UNIQUE" and tokens[index + 1].name == "ASCII_40"
        if not (policy_query or unique):
            continue
        opening = tokens[index + 1]
        depth = 1
        cursor = index + 2
        while depth:
            closing = tokens[cursor]
            depth += int(closing.name == "ASCII_40") - int(closing.name == "ASCII_41")
            cursor += 1
        if policy_query:
            edits.extend([(opening.end + 1, opening.end + 1, "("), (closing.start, closing.start, ")")])
        elif [t.name for t in tokens[cursor:cursor + 3]] == ["NULLS_P", "NOT", "DISTINCT"]:
            clause_end = tokens[cursor + 2].end + 1
            edits.extend([
                (token.end + 1, opening.start, " nulls not distinct "),
                (closing.end + 1, clause_end, ""),
            ])
    for start, end, replacement in sorted(edits, reverse=True):
        source = source[:start] + replacement + source[end:]
    return source


def polish_layout(source):
    """Give policies and triggers clause indentation without touching literals."""
    encoded = source.encode()
    edits = []
    for item in json.loads(parser.parse_sql_json(source))["stmts"]:
        kind = next(iter(item["stmt"]))
        if kind not in {"CreatePolicyStmt", "CreateTrigStmt", "IndexStmt", "CreateStmt"}:
            continue
        start = item.get("stmt_location", 0)
        length = item.get("stmt_len", 0)
        end = start + length if length else len(encoded)
        chunk = encoded[start:end].decode()
        tokens = parser.scan(chunk)
        first = next(t for t in tokens if t.name not in COMMENT_TOKENS)
        if kind == "CreateStmt":
            local_edits = []
            for i, token in enumerate(tokens):
                # Each foreign-key clause occupies its own readable line.
                is_action = token.name == "ON" and tokens[i + 1].name in {"UPDATE", "DELETE_P"}
                line_start = chunk.rfind("\n", 0, token.start) + 1
                line_end = chunk.find("\n", token.start)
                long_check = token.name == "CHECK" and len(chunk[line_start:line_end]) > 88
                if token.name == "REFERENCES" or is_action or long_check:
                    gap_start = token.start
                    while chunk[gap_start - 1:gap_start].isspace():
                        gap_start -= 1
                    local_edits.append((gap_start, token.start, "\n    "))
                if token.name == "REFERENCES":
                    cursor = i + 1
                    while cursor < len(tokens) and tokens[cursor].name in {"IDENT", "ASCII_46"}:
                        cursor += 1
                    if cursor < len(tokens) and tokens[cursor].name == "ASCII_40":
                        opening = tokens[cursor]
                        cursor += 1
                        while cursor < len(tokens) and tokens[cursor].name != "ASCII_41":
                            cursor += 1
                        closing = tokens[cursor]
                        inner = chunk[opening.end + 1:closing.start]
                        inner_tokens = parser.scan(inner)
                        if not any(t.name in COMMENT_TOKENS for t in inner_tokens):
                            names = [inner[t.start:t.end + 1] for t in inner_tokens if t.name != "ASCII_44"]
                            local_edits.append((opening.end + 1, closing.start, ", ".join(names)))
            for left, right, replacement in sorted(local_edits, reverse=True):
                chunk = chunk[:left] + replacement + chunk[right:]
            edits.append((start, end, chunk.encode()))
            continue
        if kind in {"CreatePolicyStmt", "IndexStmt"}:
            on = next(t for t in tokens if t.start > first.start and t.name == "ON")
            gap_start = on.start
            while chunk[gap_start - 1:gap_start].isspace():
                gap_start -= 1
            chunk = chunk[:gap_start] + "\n" + chunk[on.start:]
        protected = [t for t in parser.scan(chunk) if t.name in {"SCONST", "IDENT"} and "\n" in chunk[t.start:t.end + 1]]
        lines = []
        offset = 0
        first_line_end = chunk.find("\n", first.start)
        for line in chunk.splitlines(keepends=True):
            original_length = len(line)
            inside_literal = any(t.start < offset <= t.end for t in protected)
            if first_line_end >= 0 and offset > first_line_end and line.strip() and not inside_literal:
                line = "  " + line
            lines.append(line)
            offset += original_length
        edits.append((start, end, "".join(lines).encode()))
    for start, end, replacement in reversed(edits):
        encoded = encoded[:start] + replacement + encoded[end:]
    return encoded.decode()


def format_once(source, filename, executable):
    clean = strip_generated_comments(source)
    process = subprocess.run(
        [executable, str(Path(__file__).with_name("prettier_sql.mjs"))],
        input=clean, text=True, capture_output=True,
    )
    if process.returncode:
        raise ValueError(process.stderr.strip())
    result = restore_postgres_syntax(preserve_multiline_literals(clean, process.stdout))
    result = polish_layout(align_table_columns(split_parameters(result)))
    result = add_sections(result, filename)
    if sql_ast(source) != sql_ast(result):
        raise ValueError("formatter changed the SQL AST or routine-body tokens")
    return result


def format_sql(source, filename, executable):
    # Settle the formatter and project layout together. Never write
    # output that would immediately fail --check on the next invocation.
    for _ in range(4):
        formatted = format_once(source, filename, executable)
        if formatted == source:
            return formatted
        source = formatted
    raise ValueError("formatter did not converge after four passes")


def main():
    argument_parser = argparse.ArgumentParser(description=__doc__)
    argument_parser.add_argument("--check", action="store_true", help="report drift without writing")
    argument_parser.add_argument("--node", default=os.environ.get("NODE", "node"))
    arguments = argument_parser.parse_args()
    files = sorted((ROOT / "supabase/migrations").glob("*.sql"))
    pending = []
    errors = []
    for path in files:
        original = path.read_text()
        try:
            formatted = format_sql(original, path.name, arguments.node)
            if formatted != original:
                pending.append((path, original, formatted))
        except Exception as error:
            errors.append(f"{path.name}: {error}")
    if errors:
        print("No files written; semantic checks failed:\n" + "\n".join(errors), file=sys.stderr)
        return 2
    if arguments.check:
        for path, _, _ in pending:
            print(f"Needs formatting: {path.relative_to(ROOT)}")
    else:
        if any(path.read_text() != original for path, original, _ in pending):
            print("No files written: a migration changed during formatting; rerun.", file=sys.stderr)
            return 2
        for path, _, formatted in pending:
            path.write_text(formatted)
    print(f"{len(files)} migrations checked; {len(pending)} "
          f"{'need formatting' if arguments.check else 'formatted'}; SQL equivalence verified.")
    return int(arguments.check and bool(pending))


if __name__ == "__main__":
    sys.exit(main())
