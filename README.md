# warning-history

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
