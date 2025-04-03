#!/bin/bash

# Script pour exécuter terraform apply avec retry automatique
# Particulièrement utile pour contourner les problèmes de capacité Oracle Cloud ("out host capacity")

# Configuration des variables
 

# Fonction pour exécuter terraform apply
run_terraform() {
    # Exécuter terraform apply en mode auto-approve et capturer la sortie et le code de retour
    terraform apply -auto-approve 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Boucle principale de tentatives
success=false

while [ "$success" = false ]; do
    echo "" | tee -a "$LOG_FILE"
    echo "-------------------------------------------------------------" | tee -a "$LOG_FILE"
    
    # Exécuter terraform apply
    if run_terraform; then
        echo "Succès! Terraform apply" | tee -a "$LOG_FILE"
        success=true
    else
        # Vérifier si l'erreur est liée à la capacité
        if grep -E "$CAPACITY_ERROR" "$LOG_FILE" | tail -n 20 > /dev/null; then
            echo "Erreur de capacité détectée." | tee -a "$LOG_FILE"
        else
            last_error=$(tail -n 20 "$LOG_FILE" | grep "Error:" | tail -n 1)
            if [ -n "$last_error" ]; then
                echo "Erreur détectée: $last_error" | tee -a "$LOG_FILE"
            else
                echo "Échec de Terraform pour une raison inconnue." | tee -a "$LOG_FILE"
            fi
        fi
        
       
        
        # Incrémenter le compteur de tentatives
    fi
done

echo "" | tee -a "$LOG_FILE"
echo "-------------------------------------------------------------" | tee -a "$LOG_FILE"

if [ "$success" = true ]; then
    echo "Déploiement Terraform réussi" | tee -a "$LOG_FILE"
    exit 0
else
    echo "Veuillez vérifier les logs dans $LOG_FILE" | tee -a "$LOG_FILE"
    echo "Dernières erreurs:" | tee -a "$LOG_FILE"
    grep -E "Error:|error:" "$LOG_FILE" | tail -n 5 | tee -a "$LOG_FILE"
    exit 1
fi