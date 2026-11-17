<!--no-pdf-->
# CMSC 131 Lab 3 Starter

[![lab3-checks](https://github.com/WhiteLicorice/cmsc-131-lab3-starter/actions/workflows/test.yml/badge.svg)](https://github.com/WhiteLicorice/cmsc-131-lab3-starter/actions/workflows/test.yml)

A grep clone whose correctness is agreement with `grep` itself, byte for byte. The manual is the assignment. This file is the repository's own notes.

## Layout

```text
Makefile            platform preamble and build rules
driver.c            provided: file reading, the line loop, and output
cdecl.h             provided: the cdecl macros for the C boundary
args.asm            yours
match.asm           yours
lines.asm           yours
fmt.asm             yours
run_tests.sh        provided: the correctness gate
contract_test.c     provided: the second pass, in C
contract_regs.asm   provided: register checks for contract_test
LICENSE             provided: the repository licence
tests/              provided: the test corpus
```

## What to Run

On Windows, run these commands in Git Bash, the shell from Block 1. In that
shell, `make` is your alias for `mingw32-make`. On Linux, use
your terminal.

```bash
make
make check
```

`make` builds `rengrep` and `contract_test`. `make check` builds both, then
runs `./run_tests.sh`, which reports each test and exits nonzero when any
of them differ.

The first `make check` takes the longest, often more than a minute on
Windows. It saves the output of your installed `grep` in `.grep-cache`, and
later runs read that saved output. A change to your `grep`, `run_tests.sh`,
or a test file makes the next run save the output again.

The gate has two passes. The first runs your tool and `grep` with the same
arguments and compares the two outputs byte for byte. It does that across
all 32 flag subsets, 7 patterns, and 6 files: 1344 comparisons. The second
is `contract_test`. It calls the four routines directly. It checks the
capacity argument, the boundary rules, the formatter, the parser, and the
register discipline. Both passes run every time, because each one catches
what the other cannot.

## Reading a First Run

The assembly files ship as stubs that assemble and link as-is, so the build
works before you write any code. Right now the parser stub exits 2 for
every command. The gate requires exit 0 for a valid invocation, so all
1345 checks fail. That red run is the correct starting state for a starter.
Expect the first passing cells once `args.asm` and `lines.asm` are in
place, and the badge turns green when the matching and formatting routines
are done.

The provided files are fixtures. The grader compares your fork against the
starter. An edit to `driver.c`, `Makefile`, `run_tests.sh`, or a `tests/`
file appears as a diff in the open.

## Documentation

The three sections at the end of this file are yours. Complete Design Notes
and Subsystem Ownership before the Week 1 progress report. Complete Quirks
and Issues before the Week 3 progress report. Each section says what it
needs. Leave the rest of this file as it is.

---

## Design Notes

Complete this section before the Week 1 progress report. The syllabus asks
for problem analysis, a solution architecture, and an estimated timeline.
Keep each part short. Update it when the plan changes.

### Problem analysis

`rengrep` prints the lines that contain a literal pattern.

| Flag | Effect |
|---|---|
| `-n` | Prefix each line with its 1-based number and `:` |
| `-c` | Print only the count of selected lines |
| `-v` | Select the lines that do not match |
| `-i` | Ignore case, but print the original line |
| `-w` | Match only where the pattern is a whole word (`[A-Za-z0-9_]` boundaries) |

The oracle is `LC_ALL=C grep -F`. Correct means byte-identical output.
`-F` is a substring search, so `cat` matches inside `concatenate`. Only
`-w` rejects that match.

### Solution architecture

`driver.c` reads the file, loops over the lines, and prints. It calls
four routines, all cdecl. Each routine preserves `ebx`, `esi`, `edi`,
and `ebp`, and returns in `eax`.

| Routine | File | Approach |
|---|---|---|
| `parse_args` | `args.asm` | `cld`, then `repne scasb` finds each flag char in `flag_chars` (`n c v i w`, bit order). Bit = `1 << index`. The first positional is the pattern, the second is the file. |
| `index_lines` | `lines.asm` | One pass over the buffer. Each `0x0A` closes a line, recorded as `{offset, length}` without the newline. Trailing bytes after the last newline form a final line. `len == 0` gives 0 lines. Stops at `max`. |
| `line_matches` | `match.asm` | Tries each start in `0..linelen-patlen` (signed bound). `repe cmpsb` when `fold == 0`. A register-folding loop when `fold != 0`, so the buffer is never written. On `whole`, it checks the bytes before and after the match and keeps scanning on failure. |
| `int_to_dec` | `fmt.asm` | Divides by 10 and pushes each remainder. Pops them into `out`. Bottom-tested, so 0 prints `0`. |

### Timeline

| Week | Goal | Owner |
|---|---|---|
| 1 | `args.asm`, `lines.asm`: prototype runs on `sample.txt` | Dejel, Romyr |
| 2 | `match.asm` (no flags, `-i`), `fmt.asm` (`-n`, `-c`) | Andrian, Dejel |
| 3 | `-w`, edge cases, extra tests, `make check` green, Quirks | All |
| 4 | Defense | All |

## Subsystem Ownership

Complete this section before the Week 1 progress report. The manual lists
the three subsystems. Each member owns one. In a group of four, two members
share one. The commit history must agree with this table.

| Subsystem | Owner |
|---|---|
| Buffering and lines (`lines.asm`) | Romyr (@Romyr05) |
| Matching (`match.asm`) | Andrian Lloyd Maagma (@andrianllmm) |
| Formatting and flags (`fmt.asm`, `args.asm`, the tests you add) | Dejel Cyrus De Asis (@dejely) |

## Quirks and Issues

Complete this section before the Week 3 progress report. The syllabus asks
for documentation of quirks and issues with the complete implementation.
One entry per item. State what happens, what causes it, and what the group
did about it.

### Known issues

- 

### Quirks

- 
