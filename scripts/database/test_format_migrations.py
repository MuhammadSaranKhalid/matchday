"""Regression checks for the formatter's semantic guard and repeatability."""

import os
import unittest

from format_migrations import format_sql, sql_ast


class MigrationFormattingTest(unittest.TestCase):
    def test_rejects_changed_statement_order(self):
        self.assertNotEqual(
            sql_ast("select 1; select 2;"), sql_ast("select 2; select 1;")
        )

    def test_rejects_changed_routine_and_dynamic_sql(self):
        for body in ("begin return 1; end;", "begin execute 'select 1'; end;"):
            original = "create function f() returns int language plpgsql as $$" + body + "$$;"
            self.assertNotEqual(sql_ast(original), sql_ast(original.replace("1", "2")))

    def test_rejects_changed_literal_case_and_quoted_identifier(self):
        for body in ("begin raise notice 'ABC'; end;", 'begin perform "ABC"; end;'):
            original = "do $$" + body + "$$;"
            self.assertNotEqual(sql_ast(original), sql_ast(original.replace("ABC", "abc")))

    def test_accepts_case_whitespace_and_continued_string_indentation(self):
        self.assertEqual(
            sql_ast("DO $$ BEGIN RAISE NOTICE 'hello '\n 'world'; END; $$;"),
            sql_ast("do $$begin raise notice 'hello '\n     'world'; end;$$;"),
        )

    def test_formatting_is_repeatable_and_preserves_embedded_sql(self):
        source = '''-- Pokémon: preserve UTF-8 offsets and comments.
CREATE TABLE public.example (id uuid PRIMARY KEY, name text);
ALTER TABLE public.example ENABLE ROW LEVEL SECURITY;
CREATE FUNCTION public.example_fn(p_id uuid, p_values text[] DEFAULT ARRAY['a', 'b'])
RETURNS void LANGUAGE plpgsql AS $body$
BEGIN
  -- Migration file: this is a body comment, not a generated header.
  PERFORM cron.schedule('example', '* * * * *', $query$SELECT 1;$query$);
END;
$body$;
REVOKE ALL ON FUNCTION public.example_fn(uuid, text[]) FROM PUBLIC;
-- Tail comment stays present.
'''
        executable = os.environ.get("PG_FORMAT", "pg_format")
        formatted = format_sql(source, "example.sql", executable)
        self.assertEqual(sql_ast(source), sql_ast(formatted))
        self.assertEqual(formatted, format_sql(formatted, "example.sql", executable))
        self.assertIn("$query$SELECT 1;$query$", formatted)
        self.assertIn("-- Tail comment stays present.", formatted)
        self.assertIn("-- Migration file: this is a body comment", formatted)
        self.assertIn("\n  p_id uuid,\n  p_values text[]", formatted)
        self.assertEqual(formatted.count("-- Section: Functions"), 1)

    def test_table_types_align_after_longest_column_name(self):
        source = '''create table public.example (
          id uuid primary key,
          display_name text,
          -- This generated expression used to make pgFormatter skip alignment.
          created_at timestamptz default now(),
          computed integer generated always as (case when display_name is null then 0 else 1 end) stored
        );
        comment on table public.example is 'First part '
          'second part.';
        '''
        formatted = format_sql(source, "example.sql", os.environ.get("PG_FORMAT", "pg_format"))
        lines = formatted.splitlines()
        positions = [
            next(line for line in lines if line.lstrip().startswith(name + " ")).index(kind)
            for name, kind in (("id", "uuid"), ("display_name", "text"), ("created_at", "timestamptz"))
        ]
        self.assertEqual(positions, [15, 15, 15])
        self.assertEqual(formatted, format_sql(formatted, "example.sql", os.environ.get("PG_FORMAT", "pg_format")))


if __name__ == "__main__":
    unittest.main()
