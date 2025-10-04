#!/bin/bash

################################################################################
# Script di pulizia progetto Bruce
# Elimina tutti i moduli RF, RFID, NFC, FM e iButton
# Autore: Script generato per pulizia progetto
# Data: 2025
################################################################################

set -e  # Esce in caso di errore

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contatori
DELETED_FILES=0
MODIFIED_FILES=0

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Pulizia Progetto Bruce${NC}"
echo -e "${BLUE}  Rimozione moduli RF/RFID/NFC/FM${NC}"
echo -e "${BLUE}================================${NC}\n"

# Verifica di essere nella root del progetto
if [ ! -f "platformio.ini" ]; then
    echo -e "${RED}ERRORE: platformio.ini non trovato!${NC}"
    echo -e "${RED}Esegui questo script dalla root del progetto Bruce${NC}"
    exit 1
fi

# Crea backup
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}Creazione backup in: ${BACKUP_DIR}${NC}"
mkdir -p "$BACKUP_DIR"

################################################################################
# FASE 1: Backup file importanti
################################################################################
echo -e "\n${BLUE}[1/7] Backup file importanti...${NC}"

cp -r src "$BACKUP_DIR/"
cp -r boards "$BACKUP_DIR/"
cp platformio.ini "$BACKUP_DIR/"
[ -f include/precompiler_flags.h ] && cp include/precompiler_flags.h "$BACKUP_DIR/"

echo -e "${GREEN}✓ Backup completato${NC}"

################################################################################
# FASE 2: Eliminazione file menu
################################################################################
echo -e "\n${BLUE}[2/7] Eliminazione file menu...${NC}"

FILES_TO_DELETE=(
    "src/core/menu_items/NRF24.cpp"
    "src/core/menu_items/NRF24.h"
    "src/core/menu_items/RFIDMenu.cpp"
    "src/core/menu_items/RFIDMenu.h"
    "src/core/menu_items/RFMenu.cpp"
    "src/core/menu_items/RFMenu.h"
    "src/core/menu_items/FMMenu.cpp"
    "src/core/menu_items/FMMenu.h"
)

for file in "${FILES_TO_DELETE[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo -e "  ${RED}✗${NC} Eliminato: $file"
        ((DELETED_FILES++))
    fi
done

################################################################################
# FASE 3: Eliminazione moduli others
################################################################################
echo -e "\n${BLUE}[3/7] Eliminazione moduli iButton...${NC}"

if [ -f "src/modules/others/ibutton.cpp" ]; then
    rm -f src/modules/others/ibutton.cpp src/modules/others/ibutton.h
    echo -e "  ${RED}✗${NC} Eliminato: ibutton.cpp/h"
    ((DELETED_FILES+=2))
fi

################################################################################
# FASE 4: Eliminazione serial commands
################################################################################
echo -e "\n${BLUE}[4/7] Eliminazione serial commands RF...${NC}"

if [ -f "src/core/serial_commands/rf_commands.cpp" ]; then
    rm -f src/core/serial_commands/rf_commands.cpp
    rm -f src/core/serial_commands/rf_commands.h
    echo -e "  ${RED}✗${NC} Eliminato: rf_commands.cpp/h"
    ((DELETED_FILES+=2))
fi

################################################################################
# FASE 5: Eliminazione file SD
################################################################################
echo -e "\n${BLUE}[5/7] Eliminazione file SD NFC/RFID...${NC}"

if [ -d "sd_files/nfc" ]; then
    rm -rf sd_files/nfc
    echo -e "  ${RED}✗${NC} Eliminata cartella: sd_files/nfc/"
    ((DELETED_FILES++))
fi

################################################################################
# FASE 6: Pulizia file JSON delle board
################################################################################
echo -e "\n${BLUE}[6/7] Pulizia configurazioni board...${NC}"

if [ -d "boards/_boards_json" ]; then
    for json_file in boards/_boards_json/*.json; do
        if [ -f "$json_file" ]; then
            # Backup del file originale
            cp "$json_file" "${json_file}.bak"

            # Rimuove sezioni rfidPins, nrf24Pins, fmPins usando sed
            # Questo è un approccio semplificato - potrebbe richiedere aggiustamenti
            sed -i.tmp '/"rfidPins"/,/}/d' "$json_file" 2>/dev/null || true
            sed -i.tmp '/"nrf24Pins"/,/}/d' "$json_file" 2>/dev/null || true
            sed -i.tmp '/"fmPins"/,/}/d' "$json_file" 2>/dev/null || true

            rm -f "${json_file}.tmp"

            echo -e "  ${YELLOW}~${NC} Modificato: $(basename $json_file)"
            ((MODIFIED_FILES++))
        fi
    done
fi

################################################################################
# FASE 7: Modifica file sorgente principali
################################################################################
echo -e "\n${BLUE}[7/7] Modifica file sorgente principali...${NC}"

# File da modificare
MAIN_MENU="src/core/main_menu.cpp"
SERIAL_CMDS="src/core/serialcmds.cpp"

# Modifica main_menu.cpp
if [ -f "$MAIN_MENU" ]; then
    cp "$MAIN_MENU" "${MAIN_MENU}.bak"

    # Rimuove include
    sed -i.tmp '/RFMenu\.h/d' "$MAIN_MENU"
    sed -i.tmp '/RFIDMenu\.h/d' "$MAIN_MENU"
    sed -i.tmp '/NRF24\.h/d' "$MAIN_MENU"
    sed -i.tmp '/FMMenu\.h/d' "$MAIN_MENU"

    rm -f "${MAIN_MENU}.tmp"

    echo -e "  ${YELLOW}~${NC} Modificato: main_menu.cpp (include rimossi)"
    ((MODIFIED_FILES++))

    echo -e "${YELLOW}⚠  ATTENZIONE: Devi rimuovere manualmente le chiamate alle funzioni RF/RFID/NFC/FM${NC}"
fi

# Modifica serialcmds.cpp
if [ -f "$SERIAL_CMDS" ]; then
    cp "$SERIAL_CMDS" "${SERIAL_CMDS}.bak"

    # Rimuove include rf_commands
    sed -i.tmp '/rf_commands\.h/d' "$SERIAL_CMDS"

    rm -f "${SERIAL_CMDS}.tmp"

    echo -e "  ${YELLOW}~${NC} Modificato: serialcmds.cpp (include rimossi)"
    ((MODIFIED_FILES++))

    echo -e "${YELLOW}⚠  ATTENZIONE: Devi rimuovere manualmente i comandi rf_* dal parsing${NC}"
fi

################################################################################
# FASE 8: Pulizia file .bak
################################################################################
echo -e "\n${BLUE}Pulizia file temporanei...${NC}"
find boards/_boards_json -name "*.bak" -delete 2>/dev/null || true

################################################################################
# REPORT FINALE
################################################################################
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}  PULIZIA COMPLETATA!${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${BLUE}Statistiche:${NC}"
echo -e "  • File eliminati: ${RED}${DELETED_FILES}${NC}"
echo -e "  • File modificati: ${YELLOW}${MODIFIED_FILES}${NC}"
echo -e "  • Backup salvato in: ${GREEN}${BACKUP_DIR}${NC}\n"

echo -e "${YELLOW}⚠  AZIONI MANUALI RICHIESTE:${NC}\n"

echo -e "${YELLOW}1. Modifica src/core/main_menu.cpp:${NC}"
echo -e "   • Rimuovi tutte le chiamate a funzioni RF/RFID/NFC/FM dai menu"
echo -e "   • Cerca: 'RF', 'RFID', 'NFC', 'FM', 'NRF24', 'iButton'"
echo -e ""

echo -e "${YELLOW}2. Modifica src/core/serialcmds.cpp:${NC}"
echo -e "   • Rimuovi tutti i comandi seriali che iniziano con 'rf_'"
echo -e "   • Rimuovi gestione comandi RF nel parsing"
echo -e ""

echo -e "${YELLOW}3. Verifica include/precompiler_flags.h:${NC}"
echo -e "   • Disabilita flag: HAS_RF, HAS_RFID, HAS_NFC, HAS_NRF24, HAS_FM"
echo -e "   • Commenta o rimuovi le relative definizioni"
echo -e ""

echo -e "${YELLOW}4. Verifica boards/*/interface.cpp:${NC}"
echo -e "   • Commenta definizioni pin per RFID/RF/NFC se presenti"
echo -e ""

echo -e "${YELLOW}5. Test finale:${NC}"
echo -e "   • Esegui: ${BLUE}pio run -e <tua-board>${NC}"
echo -e "   • Verifica assenza errori di compilazione"
echo -e "   • Testa su hardware reale"
echo -e ""

echo -e "${GREEN}Per ripristinare il backup:${NC}"
echo -e "  cp -r ${BACKUP_DIR}/src ."
echo -e "  cp -r ${BACKUP_DIR}/boards ."
echo -e "  cp ${BACKUP_DIR}/platformio.ini ."
echo -e ""

echo -e "${BLUE}Script completato!${NC}"

exit 0
