# ioPADt public guide

ioPADt assists with IO-ring inspection, connectivity review and placement preparation. Library-specific names and rules are supplied by an authorized local profile; this document contains no installed process values.

- [User workflow](IOPAD說明.md)
- [Logical pad roles](IOPAD種類介紹.md)
- [Profile interface](../../../setup/config/README.ioPADt_rules.md)

Launch through the existing GUI launcher or `TT_IOPAD_GUI_START` at an IO-edit checkpoint. Load the intended design inputs, refresh DB facts, inspect the ring and checks, preview generated changes, and save before applying changes. Follow the original checkpoint resume rules.

The installed profile is selected through `IOPADT_RULES_FILE` or the existing local private setup. Its semantic fields and `literal_tokens` must remain consistent. Missing configuration is an error; the public template is not a working process profile.

Generated native queries preserve the existing protocol and algorithms. Core tests cover classification, model propagation and query text with the original-value profile. Live GUI/Innovus Apply and arbitrary technology portability are not established by those tests.

Process-specific historical documentation is retained under the local `private/` directory and excluded from public distribution. Generated outputs and user design inputs are private unless separately reviewed.
