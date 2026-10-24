# Logical IO pad roles

| Role | General purpose |
|---|---|
| Signal | Carry a design signal across the IO interface. |
| Core supply | Provide a configured core-supply connection. |
| IO supply | Provide a configured IO-supply connection. |
| Boundary separator | Separate configured electrical sections of the ring. |
| Corner | Represent a configured corner object. |
| Unknown | Lacks sufficient configured or queried facts for a safe classification. |

Actual master names, pin signatures, rail mappings and boundary rules belong to the installed private profile. Classification retains its existing matching predicates; an unknown object must be reviewed rather than assigned a guessed family.

[User workflow](IOPAD說明.md)
