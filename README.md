# warning-history

This script processes the history of a source Git repository of Rust project
in order to find out how warnings have been addressed.

## Synoposis:
```bash
  ./warning-history.sh <path> [date]
```

### Input arguments:

```
  $path -- indicates the path to a folder of Git repository
  $date -- indicates the date of the history since, e.g., "6 weeks ago"
```

### Outputs:

As a result, it produces the following files where `$base` refers to `$(basename $path)`:
```
  ./data/$base/diagnostics/$base-warnings.tar.bz2 -- the tarball of the results per project
  ./data/$base/diagnostics/warning-history-per-KLOC.png -- number of warnings and ratio of warning density per KLOC over time
  ./data/$base/diagnostics/counts.csv -- statistics data to generate the above figure
  ./data/$base/diagnostics/git.log -- hashes of individual versions since $date according git log 
  ./data/$base/diagnosticses/$i where i = 1 .. n -- folder of individual version from the date of analysis as v1.
  ./data/$base/diagnosticses/$i/$hash where $hash is the hash of vi -- folder of individual vi 
  ./data/$base/diagnosticses/$i/$hash/counts.txt -- output from rust-diagnostics, including warning pairs
  ./data/$base/diagnosticses/$i/$hash/counts.txt/tokei.txt -- output from tokei, counting LOC in Rust
```
At the end, it aggregates the individual warning pairs for CodeT5's "translate" task, and the "cs-java" sub-task.
Specifically, we map the code hunks before fix as "cs", and the code hunks after fix as "java", e.g.,
the warning accociated with `clippy::as_conversions` will be listed as parallel data in the following two files:
```
  ./[Warning(clippy::as_conversions).cs-java.txt.cs
  ./[Warning(clippy::as_conversions).cs-java.txt.java
```
Overall, all these different types of warnings are aggregated into the following two files:
```
  ./clippy.cs-java.txt.cs
  ./clippy.cs-java.txt.java
```
They are packed into the following tarball:
```
  ./clippy-warning-fix.tar.bz2 -- the above warning data in CodeT5 format
```

## The underlying algorithm

```
Algorithm Minimize history of warning fixes
 Given 
 * history H as a sequence of hashes h_1 .. h_n 
  = the result of command `$git log` 
 * \Delta(h_{i-1}, h_i) as the diff records on version h_i
  = the result of command `$git diff h_i^..h_i`
 * p(d, f) as apply patch d onto file f
  = the result of command `$patch f < d`
 * W_t(h_i) as warnings of type t in version h_i
  = the result of command `git checkout h_i && cargo clippy`
 Return P = \{ P_t \} where P_t =\{ (func, func')\} as pairs of fixes for type t of warnings
{
    P = \{ \}
    for t = 1..w {
        for i = 2..n  {
            P_t = \{ \}
            if W_t(h_{i-1}) > W_t(h_i) {
                D = \Delta (h_{i-1}, h_i) 
                foreach d \in D {
                    let f = file(d) 
                    let h' = p(d, f)
                    if W_t(h_i) == W_t(h') {
                        D = D \setminus \{d\} 
                    }
                    P_t = P_t \cup {D} 
                }
            }
        }
        P = P \cup \{P_t\}
    }
    return P
}
```

## Crates-IO projects

The following commands can be used to count the number of warnings on crates-io projects:
```bash
git clone https://github.com/rust-lang/rust-clippy
cp lintcheck_crates.toml rust-clippy/lintcheck
cd rust-clippy
cargo lintcheck
```
At the moment of study, 94735 projects have proper version to be configured.
Results of analysis are stored under `target/lintcheck`.

## Some related projects

 * https://github.com/trusted-programming/rust-diagnostics
 * https://github.com/rust-lang/rust-clippy
 * https://github.com/rust-lang/git2-rs
 * https://github.com/salesforce/codet5

