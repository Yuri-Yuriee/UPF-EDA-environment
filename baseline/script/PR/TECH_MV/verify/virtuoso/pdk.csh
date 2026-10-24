# Load resource paths through the existing Verify configuration.
if (! $?VERIFY_ROOT) then
    setenv VERIFY_ROOT `cd ..; pwd`
endif
source "$VERIFY_ROOT/config.csh"
set _verify_pdk_os_path = "$FOUNDRYPDK_OS_INSTALL_PATH"
set _verify_cds_home = "$CDSHOME"
source "$TECH_VIRTUOSO_SETUP_FILE"
setenv FOUNDRYPDK_OS_INSTALL_PATH "$_verify_pdk_os_path"
setenv CDSHOME "$_verify_cds_home"
unset _verify_pdk_os_path
unset _verify_cds_home
setenv FOUNDRYPDK_SHARELIB $FOUNDRYPDK_OS_INSTALL_PATH/../shareLib
