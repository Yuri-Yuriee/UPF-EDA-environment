# ioPADt public workflow

1. Install an authorized library/profile configuration through the existing setup mechanism.
2. Launch the GUI using the normal project launcher or checkpoint command.
3. Load the intended IO description and connectivity inputs.
4. Refresh facts from the active Innovus DB; verify that the GUI and DB correspond to the same design.
5. Inspect clockwise ordering, pad roles, boundaries, connectivity and unresolved objects.
6. Review the configured geometry checks and previews before applying edits.
7. Save the design and generated files using the existing flow paths.
8. Recheck the live DB and follow the original suspend/resume instructions.

Some operations modify placement or connectivity. Their original prerequisites remain applicable. Configuration does not replace DB validation or physical verification. Historical feature descriptions may describe older versions; use the installed tool and active flow as the authority.

See [profile fields](../../../setup/config/README.ioPADt_rules.md) and [logical roles](IOPAD種類介紹.md). This public guide intentionally contains no actual cell/pin names, dimensions, rule identifiers, design snapshots or private resource paths.
