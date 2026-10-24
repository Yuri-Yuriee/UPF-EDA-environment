cat > extract_hdr.sh <<\EOF
#!/bin/sh
set -eu

CELL="FILL_IN_CELL_POWER_SWITCH_029"
LIBDIR="/FILL_IN/FILL_IN_RESOURCE_0178"

echo "============================================================"
echo " Search cell: $CELL"
echo "============================================================"

FILE=$(grep -HilE \
    "^[[:space:]]*\.subckt[[:space:]]+${CELL}([[:space:]]|$)" \
    "$LIBDIR"/*.spi | head -n 1)

if [ -z "$FILE" ]; then
    echo "[ERROR] Cannot find $CELL"
    exit 1
fi

echo "[FOUND]"
echo "$FILE"
echo
echo "============================================================"
echo " SUBCKT CONTENT"
echo "============================================================"

awk -v cell="$CELL" '
{
    f1 = tolower($1)
    f2 = tolower($2)
    target = tolower(cell)
}

f1 == ".subckt" && f2 == target {
    inside = 1
}

inside {
    print
}

inside && f1 == ".ends" {
    exit
}
' "$FILE"

echo
echo "============================================================"
echo " DONE"
echo "============================================================"
EOF
