#!/bin/sh

set -e

# Configuration
CONFIG_FILE="/buckets-config.json"
MINIO_ALIAS="minio"
MINIO_ENDPOINT="http://minio:9000"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérification des variables d'environnement critiques
if [ -z "$MINIO_USERNAME" ]; then
    log_error "Variable d'environnement MINIO_USERNAME non définie"
    exit 1
fi

if [ -z "$MINIO_PASSWORD" ]; then
    log_error "Variable d'environnement MINIO_PASSWORD non définie"
    exit 1
fi

# Header avec version
echo "🔧 ===== CONFIGURATION MINIO BUCKETS ====="
config_version=$(jq -r '.version // "unknown"' $CONFIG_FILE 2>/dev/null || echo "unknown")
log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# Fonction pour tester la connectivité MinIO avec différents endpoints
test_minio_connectivity() {
    local endpoint=$1
    local host=$(echo $endpoint | sed -E 's|https?://([^:/]+).*|\1|')
    local port=$(echo $endpoint | sed -E 's|.*:([0-9]+).*|\1|')
    
    # Si pas de port explicite, utiliser 9000 par défaut
    if [ "$port" = "$endpoint" ]; then
        port=9000
    fi
    
    log_info "Test de connectivité pour $endpoint..."
    
    # Test de résolution DNS
    if nslookup $host > /dev/null 2>&1; then
        log_success "Résolution DNS OK pour $host"
    else
        log_warning "Échec de résolution DNS pour $host"
        return 1
    fi
    
    # Test de connectivité port
    if nc -z $host $port 2>/dev/null; then
        log_success "Port $port accessible sur $host"
        return 0
    else
        log_warning "Port $port non accessible sur $host"
        return 1
    fi
}

# Liste des endpoints possibles à tester
POSSIBLE_ENDPOINTS="http://minio:9000 http://localhost:9000 http://127.0.0.1:9000"

# Détecter l'endpoint accessible
WORKING_ENDPOINT=""
for endpoint in $POSSIBLE_ENDPOINTS; do
    if test_minio_connectivity $endpoint; then
        WORKING_ENDPOINT=$endpoint
        log_success "Endpoint accessible trouvé: $endpoint"
        break
    fi
done

# Utiliser l'endpoint détecté ou garder celui par défaut
if [ -n "$WORKING_ENDPOINT" ]; then
    MINIO_ENDPOINT=$WORKING_ENDPOINT
    log_info "Utilisation de l'endpoint: $MINIO_ENDPOINT"
else
    log_warning "Aucun endpoint accessible détecté, utilisation par défaut: $MINIO_ENDPOINT"
fi

# Attendre que MinIO soit prêt
log_info "Attente du démarrage de MinIO..."
log_info "Endpoint: $MINIO_ENDPOINT"
log_info "Username: $MINIO_USERNAME"

# Vérifier la résolution DNS et la connectivité réseau
log_info "Vérification de la connectivité réseau..."

# Extraire l'host et le port de l'endpoint
MINIO_HOST=$(echo $MINIO_ENDPOINT | sed -E 's|https?://([^:/]+).*|\1|')
MINIO_PORT=$(echo $MINIO_ENDPOINT | sed -E 's|.*:([0-9]+).*|\1|')

# Si pas de port explicite, utiliser 9000 par défaut
if [ "$MINIO_PORT" = "$MINIO_ENDPOINT" ]; then
    MINIO_PORT=9000
fi

log_info "Test de résolution DNS pour $MINIO_HOST..."
if nslookup $MINIO_HOST > /dev/null 2>&1; then
    log_success "Résolution DNS OK"
else
    log_warning "Échec de résolution DNS, test avec ping..."
    if ping -c 1 $MINIO_HOST > /dev/null 2>&1; then
        log_success "Host accessible via ping"
    else
        log_error "Host $MINIO_HOST inaccessible"
    fi
fi

log_info "Test de connectivité sur le port $MINIO_PORT..."
if nc -z $MINIO_HOST $MINIO_PORT 2>/dev/null; then
    log_success "Port $MINIO_PORT accessible"
else
    log_warning "Port $MINIO_PORT non accessible, installation de netcat si nécessaire..."
    apk add --no-cache netcat-openbsd > /dev/null 2>&1 || true
    if nc -z $MINIO_HOST $MINIO_PORT 2>/dev/null; then
        log_success "Port $MINIO_PORT accessible après installation de netcat"
    else
        log_error "Port $MINIO_PORT toujours inaccessible"
    fi
fi

# Test HTTP direct avant d'utiliser mc
log_info "Test HTTP direct sur $MINIO_ENDPOINT/minio/health/live..."
if curl -f -s $MINIO_ENDPOINT/minio/health/live > /dev/null 2>&1; then
    log_success "MinIO health check OK"
else
    log_warning "Health check échoué ou curl non disponible"
fi

retry_count=0
max_retries=30

until mc alias set $MINIO_ALIAS $MINIO_ENDPOINT $MINIO_USERNAME $MINIO_PASSWORD > /dev/null 2>&1; do
    retry_count=$((retry_count + 1))
    if [ $retry_count -ge $max_retries ]; then
        log_error "MinIO n'est pas accessible après $max_retries tentatives"
        
        # Diagnostic détaillé en cas d'échec
        log_error "=== DIAGNOSTIC DÉTAILLÉ ==="
        log_error "Endpoint: $MINIO_ENDPOINT"
        log_error "Username: $MINIO_USERNAME"
        log_error "Password: [${#MINIO_PASSWORD} caractères]"
        
        # Test de la commande mc avec sortie détaillée
        log_error "Test de connexion avec sortie détaillée:"
        mc alias set $MINIO_ALIAS $MINIO_ENDPOINT $MINIO_USERNAME $MINIO_PASSWORD || true
        
        exit 1
    fi
    echo "   Tentative $retry_count/$max_retries - MinIO n'est pas encore prêt..."
    sleep 2
done
log_success "MinIO est prêt et accessible!"

# Vérifier si le fichier de configuration existe
if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Fichier de configuration non trouvé: $CONFIG_FILE"
    exit 1
fi



# Fonction pour créer un utilisateur IAM
create_iam_user() {
    local bucket_name=$1
    local user_name="${bucket_name}-user"
    
    log_info "Création de l'utilisateur IAM: $user_name"
    
    # Créer l'utilisateur (ignore l'erreur si existe déjà)
    mc admin user add $MINIO_ALIAS $user_name $(openssl rand -base64 32) 2>/dev/null || log_warning "Utilisateur $user_name existe déjà"
    
    # Créer la politique IAM pour ce bucket
    policy_name="${bucket_name}-policy"
    policy_file="/tmp/${policy_name}.json"
    
    cat > $policy_file <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowBucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObjectAcl",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:GetObject",
                "s3:PutObjectAcl",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${bucket_name}",
                "arn:aws:s3:::${bucket_name}/*"
            ]
        }
    ]
}
EOF
    
    # Ajouter la politique
    if mc admin policy add $MINIO_ALIAS $policy_name $policy_file; then
        log_success "Politique IAM $policy_name créée"
    else
        log_warning "Politique $policy_name existe déjà ou erreur"
    fi
    
    # Attacher la politique à l'utilisateur
    if mc admin policy set $MINIO_ALIAS $policy_name user=$user_name; then
        log_success "Politique $policy_name attachée à l'utilisateur $user_name"
    else
        log_warning "Erreur lors de l'attachement de la politique"
    fi
    
    # Générer les clés d'accès
    log_info "Génération des clés d'accès pour $user_name..."
    access_key=$(mc admin user svcacct add $MINIO_ALIAS $user_name --access-key "${bucket_name}-access" --secret-key "$(openssl rand -base64 32)" 2>/dev/null | grep "Access Key" | awk '{print $3}' || echo "Erreur")
    
    if [ "$access_key" != "Erreur" ]; then
        log_success "Clés d'accès générées pour $user_name"
        log_info "   🔑 Identifiants générés:"
        log_info "   Access Key: ${bucket_name}-access"
        log_info "   Secret Key: [généré automatiquement]"
    else
        log_warning "Les clés d'accès existent déjà ou erreur de génération"
    fi
    
    rm -f $policy_file
}

# Parser le JSON et configurer chaque bucket
log_info "Lecture de la configuration des buckets..."
bucket_count=$(jq '.buckets | length' $CONFIG_FILE)
log_info "$bucket_count bucket(s) à configurer"

success_count=0
error_count=0

for i in $(seq 0 $((bucket_count - 1))); do
    # Extraire les informations du bucket
    bucket_name=$(jq -r ".buckets[$i].name" $CONFIG_FILE)
    bucket_desc=$(jq -r ".buckets[$i].description // \"\"" $CONFIG_FILE)
    public_read=$(jq -r ".buckets[$i].public_read" $CONFIG_FILE)
    cors_enabled=$(jq -r ".buckets[$i].cors.enabled" $CONFIG_FILE)
    versioning=$(jq -r ".buckets[$i].versioning" $CONFIG_FILE)
    block_public_acls=$(jq -r ".buckets[$i].block_public_acls // true" $CONFIG_FILE)
    
    echo ""
    echo "🪣 =================="
    log_info "Bucket: $bucket_name"
    [ -n "$bucket_desc" ] && log_info "Description: $bucket_desc"
    echo "=================="
    
    # Validation du nom de bucket
    if [ -z "$bucket_name" ] || [ "$bucket_name" = "null" ]; then
        log_error "Nom de bucket invalide à l'index $i"
        error_count=$((error_count + 1))
        continue
    fi
    
    bucket_configured=true
    
    # Créer le bucket
    if mc ls $MINIO_ALIAS/$bucket_name > /dev/null 2>&1; then
        log_success "Bucket $bucket_name existe déjà"
    else
        if mc mb $MINIO_ALIAS/$bucket_name; then
            log_success "Bucket $bucket_name créé"
        else
            log_error "Échec de la création du bucket $bucket_name"
            bucket_configured=false
            error_count=$((error_count + 1))
            continue
        fi
    fi
    
    # Configurer le versioning
    if [ "$versioning" = "true" ]; then
        if mc version enable $MINIO_ALIAS/$bucket_name > /dev/null 2>&1; then
            log_success "Versioning activé"
        else
            log_warning "Échec de l'activation du versioning"
            bucket_configured=false
        fi
    else
        if mc version suspend $MINIO_ALIAS/$bucket_name > /dev/null 2>&1; then
            log_success "Versioning désactivé"
        else
            log_warning "Versioning déjà désactivé ou échec"
        fi
    fi
    
    # Configurer CORS si activé (nouvelle logique pour plusieurs règles)
    if [ "$cors_enabled" = "true" ]; then
        # Vérifier si on a des règles définies
        rules_count=$(jq ".buckets[$i].cors.rules | length" $CONFIG_FILE 2>/dev/null || echo "0")
        
        if [ "$rules_count" -gt 0 ]; then
            log_info "Configuration CORS avec $rules_count règle(s)"
            
            # Générer le fichier CORS avec toutes les règles
            cors_config="/tmp/cors_${bucket_name}.json"
            
            # Créer la configuration CORS avec plusieurs règles
            jq -n --argjson bucket_config "$(jq ".buckets[$i]" $CONFIG_FILE)" '
            {
                "CORSRules": [
                    $bucket_config.cors.rules[] | {
                        "ID": .id,
                        "AllowedHeaders": .allowed_headers,
                        "AllowedMethods": .allowed_methods,
                        "AllowedOrigins": .allowed_origins,
                        "ExposeHeaders": (.expose_headers // [])
                    }
                ]
            }' > $cors_config
            
            # Appliquer CORS
            if mc cors set $cors_config $MINIO_ALIAS/$bucket_name; then
                log_success "CORS configuré avec $rules_count règle(s)"
                
                # Afficher les détails de chaque règle
                for j in $(seq 0 $((rules_count - 1))); do
                    rule_id=$(jq -r ".buckets[$i].cors.rules[$j].id" $CONFIG_FILE)
                    origins=$(jq -r ".buckets[$i].cors.rules[$j].allowed_origins[]?" $CONFIG_FILE | tr '\n' ' ')
                    methods=$(jq -r ".buckets[$i].cors.rules[$j].allowed_methods[]?" $CONFIG_FILE | tr '\n' ' ')
                    log_info "   Règle $rule_id: $methods depuis [$origins]"
                done
            else
                log_warning "Échec de la configuration CORS"
                bucket_configured=false
            fi
            
            # Nettoyer le fichier temporaire
            rm -f $cors_config
        else
            # Fallback vers l'ancienne structure (rétrocompatibilité)
            origins_count=$(jq ".buckets[$i].cors.allowed_origins | length" $CONFIG_FILE 2>/dev/null || echo "0")
            if [ "$origins_count" -gt 0 ]; then
                log_warning "Structure CORS obsolète détectée, utilisation de la rétrocompatibilité"
                
                cors_config="/tmp/cors_${bucket_name}.json"
                jq -n --argjson bucket_config "$(jq ".buckets[$i]" $CONFIG_FILE)" '
                {
                    "CORSRules": [
                        {
                            "ID": "CORSRule1",
                            "AllowedHeaders": $bucket_config.cors.allowed_headers,
                            "AllowedMethods": $bucket_config.cors.allowed_methods,
                            "AllowedOrigins": $bucket_config.cors.allowed_origins,
                            "ExposeHeaders": []
                        }
                    ]
                }' > $cors_config
                
                if mc cors set $cors_config $MINIO_ALIAS/$bucket_name; then
                    log_success "CORS configuré (mode rétrocompatibilité)"
                fi
                rm -f $cors_config
            else
                log_warning "CORS activé mais aucune règle définie"
            fi
        fi
    else
        log_info "CORS désactivé"
    fi
    
    # Configurer l'accès public en lecture si nécessaire
    if [ "$public_read" = "true" ]; then
        # Vérifier Block Public ACLs (équivalent AWS)
        if [ "$block_public_acls" = "false" ]; then
            log_info "Block Public ACLs: désactivé (équivalent AWS)"
        else
            log_warning "Block Public ACLs activé - l'accès public pourrait être limité"
        fi
        
        policy_file="/tmp/policy_${bucket_name}.json"
        cat > $policy_file <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"AWS": ["*"]},
            "Action": ["s3:GetObject"],
            "Resource": ["arn:aws:s3:::${bucket_name}/*"]
        }
    ]
}
EOF
        if mc policy set-json $policy_file $MINIO_ALIAS/$bucket_name; then
            log_success "Accès public en lecture activé"
        else
            log_warning "Échec de la configuration de l'accès public"
            bucket_configured=false
        fi
        rm -f $policy_file
    else
        if mc policy set none $MINIO_ALIAS/$bucket_name > /dev/null 2>&1; then
            log_success "Accès privé configuré"
        else
            log_info "Accès privé (par défaut)"
        fi
    fi
    
#!/bin/bash

set -e

# Configuration
CONFIG_FILE="/buckets-config.json"
MINIO_ALIAS="minio"
MINIO_ENDPOINT="http://minio:9000"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Header avec version
echo "🔧 ===== CONFIGURATION MINIO BUCKETS ====="
config_version=$(jq -r '.version // "unknown"' $CONFIG_FILE 2>/dev/null || echo "unknown")
log_info "Version de la configuration: $config_version"
log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# Attendre que MinIO soit prêt
log_info "Attente du démarrage de MinIO..."
retry_count=0
max_retries=30

until mc alias set $MINIO_ALIAS $MINIO_ENDPOINT $MINIO_USERNAME $MINIO_PASSWORD > /dev/null 2>&1; do
    retry_count=$((retry_count + 1))
    if [ $retry_count -ge $max_retries ]; then
        log_error "MinIO n'est pas accessible après $max_retries tentatives"
        exit 1
    fi
    echo "   Tentative $retry_count/$max_retries - MinIO n'est pas encore prêt..."
    sleep 2
done
log_success "MinIO est prêt et accessible!"

# Vérifier si le fichier de configuration existe
if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Fichier de configuration non trouvé: $CONFIG_FILE"
    exit 1
fi

# Valider le JSON
if ! jq empty $CONFIG_FILE 2>/dev/null; then
    log_error "Le fichier de configuration JSON est invalide"
    exit 1
fi

# Fonction pour créer un utilisateur IAM pour un bucket
create_iam_user() {
    local bucket_name=$1
    local user_name="${bucket_name}-user"
    
    log_info "Création de l'utilisateur IAM: $user_name"
    
    # Créer l'utilisateur (ignore l'erreur si existe déjà)
    mc admin user add $MINIO_ALIAS $user_name $(openssl rand -base64 32) 2>/dev/null || log_warning "Utilisateur $user_name existe déjà"
    
    # Créer la politique IAM pour ce bucket
    policy_name="${bucket_name}-policy"
    policy_file="/tmp/${policy_name}.json"
    
    cat > $policy_file <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowBucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObjectAcl",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:GetObject",
                "s3:PutObjectAcl",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${bucket_name}",
                "arn:aws:s3:::${bucket_name}/*"
            ]
        }
    ]
}
EOF
    
    # Ajouter la politique
    if mc admin policy add $MINIO_ALIAS $policy_name $policy_file; then
        log_success "Politique IAM $policy_name créée"
    else
        log_warning "Politique $policy_name existe déjà ou erreur"
    fi
    
    # Attacher la politique à l'utilisateur
    if mc admin policy set $MINIO_ALIAS $policy_name user=$user_name; then
        log_success "Politique $policy_name attachée à l'utilisateur $user_name"
    else
        log_warning "Erreur lors de l'attachement de la politique"
    fi
    
    # Générer les clés d'accès
    log_info "Génération des clés d'accès pour $user_name..."
    access_key="${bucket_name}-access"
    secret_key=$(openssl rand -base64 32)
    
    if mc admin user svcacct add $MINIO_ALIAS $user_name --access-key "$access_key" --secret-key "$secret_key" > /dev/null 2>&1; then
        log_success "Clés d'accès générées pour $user_name"
        log_info "   🔑 Identifiants générés:"
        log_info "   Access Key: $access_key"
        log_info "   Secret Key: $secret_key"
    else
        log_warning "Les clés d'accès existent déjà ou erreur de génération"
    fi
    
    rm -f $policy_file
}

# Parser le JSON et configurer chaque bucket
log_info "Lecture de la configuration des buckets..."
bucket_count=$(jq '.buckets | length' $CONFIG_FILE)
log_info "$bucket_count bucket(s) à configurer"

success_count=0
error_count=0

for i in $(seq 0 $((bucket_count - 1))); do
    # Extraire les informations du bucket
    bucket_name=$(jq -r ".buckets[$i].name" $CONFIG_FILE)
    bucket_desc=$(jq -r ".buckets[$i].description // \"\"" $CONFIG_FILE)
    public_read=$(jq -r ".buckets[$i].public_read" $CONFIG_FILE)
    cors_enabled=$(jq -r ".buckets[$i].cors.enabled" $CONFIG_FILE)
    versioning=$(jq -r ".buckets[$i].versioning" $CONFIG_FILE)
    block_public_acls=$(jq -r ".buckets[$i].block_public_acls // true" $CONFIG_FILE)
    create_iam=$(jq -r ".buckets[$i].create_iam_user // false" $CONFIG_FILE)
    
    echo ""
    echo "🪣 =================="
    log_info "Bucket: $bucket_name"
    [ -n "$bucket_desc" ] && log_info "Description: $bucket_desc"
    echo "=================="
    
    # Validation du nom de bucket
    if [ -z "$bucket_name" ] || [ "$bucket_name" = "null" ]; then
        log_error "Nom de bucket invalide à l'index $i"
        error_count=$((error_count + 1))
        continue
    fi
    
    bucket_configured=true
    
    # Créer le bucket
    if mc ls $MINIO_ALIAS/$bucket_name > /dev/null 2>&1; then
        log_success "Bucket $bucket_name existe déjà"
    else
        if mc mb $MINIO_ALIAS/$bucket_name; then
            log_success "Bucket $bucket_name créé"
        else
            log_error "Échec de la création du bucket $bucket_name"
            bucket_configured=false
            error_count=$((error_count + 1))
            continue
        fi
    fi
    
    # Configurer le versioning
    if [ "$versioning" = "true" ]; then
        if mc version enable $MINIO_ALIAS/$bucket_name > /dev/null 2>&1; then
            log_success "Versioning activé"
        else
            log_warning "Échec de l'activation du versioning"
            bucket_configured=false
        fi
    else
        if mc version suspend $MINIO_ALIAS/$bucket_name > /dev/null 2>&1; then
            log_success "Versioning désactivé"
        else
            log_warning "Versioning déjà désactivé ou échec"
        fi
    fi
    
    # Configurer CORS si activé (gestion de plusieurs règles)
    if [ "$cors_enabled" = "true" ]; then
        # Vérifier si on a des règles définies
        rules_count=$(jq ".buckets[$i].cors.rules | length" $CONFIG_FILE 2>/dev/null || echo "0")
        
        if [ "$rules_count" -gt 0 ]; then
            log_info "Configuration CORS avec $rules_count règle(s)"
            
            # Générer le fichier CORS avec toutes les règles
            cors_config="/tmp/cors_${bucket_name}.json"
            
            # Créer la configuration CORS avec plusieurs règles
            jq -n --argjson bucket_config "$(jq ".buckets[$i]" $CONFIG_FILE)" '
            {
                "CORSRules": [
                    $bucket_config.cors.rules[] | {
                        "ID": .id,
                        "AllowedHeaders": .allowed_headers,
                        "AllowedMethods": .allowed_methods,
                        "AllowedOrigins": .allowed_origins,
                        "ExposeHeaders": (.expose_headers // [])
                    }
                ]
            }' > $cors_config
            
            # Appliquer CORS
            if mc cors set $cors_config $MINIO_ALIAS/$bucket_name; then
                log_success "CORS configuré avec $rules_count règle(s)"
                
                # Afficher les détails de chaque règle
                for j in $(seq 0 $((rules_count - 1))); do
                    rule_id=$(jq -r ".buckets[$i].cors.rules[$j].id" $CONFIG_FILE)
                    origins=$(jq -r ".buckets[$i].cors.rules[$j].allowed_origins[]?" $CONFIG_FILE | tr '\n' ' ')
                    methods=$(jq -r ".buckets[$i].cors.rules[$j].allowed_methods[]?" $CONFIG_FILE | tr '\n' ' ')
                    log_info "   Règle $rule_id: $methods depuis [$origins]"
                done
            else
                log_warning "Échec de la configuration CORS"
                bucket_configured=false
            fi
            
            # Nettoyer le fichier temporaire
            rm -f $cors_config
        else
            # Fallback vers l'ancienne structure (rétrocompatibilité)
            origins_count=$(jq ".buckets[$i].cors.allowed_origins | length" $CONFIG_FILE 2>/dev/null || echo "0")
            if [ "$origins_count" -gt 0 ]; then
                log_warning "Structure CORS obsolète détectée, utilisation de la rétrocompatibilité"
                
                cors_config="/tmp/cors_${bucket_name}.json"
                jq -n --argjson bucket_config "$(jq ".buckets[$i]" $CONFIG_FILE)" '
                {
                    "CORSRules": [
                        {
                            "ID": "CORSRule1",
                            "AllowedHeaders": $bucket_config.cors.allowed_headers,
                            "AllowedMethods": $bucket_config.cors.allowed_methods,
                            "AllowedOrigins": $bucket_config.cors.allowed_origins,
                            "ExposeHeaders": []
                        }
                    ]
                }' > $cors_config
                
                if mc cors set $cors_config $MINIO_ALIAS/$bucket_name; then
                    log_success "CORS configuré (mode rétrocompatibilité)"
                fi
                rm -f $cors_config
            else
                log_warning "CORS activé mais aucune règle définie"
            fi
        fi
    else
        log_info "CORS désactivé"
    fi
    
    # Configurer l'accès public en lecture si nécessaire
    if [ "$public_read" = "true" ]; then
        # Vérifier Block Public ACLs (équivalent AWS)
        if [ "$block_public_acls" = "false" ]; then
            log_info "Block Public ACLs: désactivé"
        else
            log_warning "Block Public ACLs activé - l'accès public pourrait être limité"
        fi
        
        policy_file="/tmp/policy_${bucket_name}.json"
        cat > $policy_file <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"AWS": ["*"]},
            "Action": ["s3:GetObject"],
            "Resource": ["arn:aws:s3:::${bucket_name}/*"]
        }
    ]
}
EOF
        if mc policy set-json $policy_file $MINIO_ALIAS/$bucket_name; then
            log_success "Accès public en lecture activé"
        else
            log_warning "Échec de la configuration de l'accès public"
            bucket_configured=false
        fi
        rm -f $policy_file
    else
        if mc policy set none $MINIO_ALIAS/$bucket_name > /dev/null 2>&1; then
            log_success "Accès privé configuré"
        else
            log_info "Accès privé (par défaut)"
        fi
    fi
    
    # Créer un utilisateur IAM dédié si demandé
    if [ "$create_iam" = "true" ]; then
        create_iam_user $bucket_name
    fi
    
    # Configurer les règles de cycle de vie si activées
    lifecycle_enabled=$(jq -r ".buckets[$i].lifecycle.enabled" $CONFIG_FILE)
    if [ "$lifecycle_enabled" = "true" ]; then
        log_warning "Lifecycle: fonctionnalité avancée (nécessite MinIO Enterprise ou configuration manuelle)"
    fi
    
    # Compteur de succès
    if [ "$bucket_configured" = true ]; then
        success_count=$((success_count + 1))
        log_success "Configuration du bucket $bucket_name terminée"
    else
        error_count=$((error_count + 1))
        log_error "Configuration du bucket $bucket_name partiellement échouée"
    fi
done

echo ""
echo "🎉 ===== RÉSUMÉ DE LA CONFIGURATION ====="
log_success "Buckets configurés avec succès: $success_count"
if [ $error_count -gt 0 ]; then
    log_warning "Buckets avec des erreurs: $error_count"
fi

echo ""
log_info "📊 Liste des buckets MinIO:"
mc ls $MINIO_ALIAS

echo ""
log_info "🔍 Vérification des politiques d'accès:"
for i in $(seq 0 $((bucket_count - 1))); do
    bucket_name=$(jq -r ".buckets[$i].name" $CONFIG_FILE)
    if [ "$bucket_name" != "null" ] && [ -n "$bucket_name" ]; then
        echo -n "   $bucket_name: "
        policy_info=$(mc policy get $MINIO_ALIAS/$bucket_name 2>/dev/null | head -1 || echo "privé")
        if echo "$policy_info" | grep -q "Allow"; then
            echo -e "${GREEN}public (lecture)${NC}"
        else
            echo -e "${YELLOW}privé${NC}"
        fi
    fi
done

echo ""
log_info "👥 Utilisateurs IAM créés:"
mc admin user list $MINIO_ALIAS 2>/dev/null | grep -E "\-user" || log_info "   Aucun utilisateur spécifique détecté"

echo ""
if [ $error_count -eq 0 ]; then
    log_success "🎊 Configuration terminée avec succès!"
    exit 0
else
    log_warning "⚠️ Configuration terminée avec des avertissements"
    exit 0
fi
    
    # Configurer les règles de cycle de vie si activées
    lifecycle_enabled=$(jq -r ".buckets[$i].lifecycle.enabled" $CONFIG_FILE)
    if [ "$lifecycle_enabled" = "true" ]; then
        log_warning "Lifecycle: fonctionnalité avancée (nécessite MinIO Enterprise ou configuration manuelle)"
    fi
    
    # Compteur de succès
    if [ "$bucket_configured" = true ]; then
        success_count=$((success_count + 1))
        log_success "Configuration du bucket $bucket_name terminée"
    else
        error_count=$((error_count + 1))
        log_error "Configuration du bucket $bucket_name partiellement échouée"
    fi
done

echo ""
echo "🎉 ===== RÉSUMÉ DE LA CONFIGURATION ====="
log_success "Buckets configurés avec succès: $success_count"
if [ $error_count -gt 0 ]; then
    log_warning "Buckets avec des erreurs: $error_count"
fi

echo ""
log_info "📊 Liste des buckets MinIO:"
mc ls $MINIO_ALIAS

echo ""
log_info "🔍 Vérification des politiques d'accès:"
for i in $(seq 0 $((bucket_count - 1))); do
    bucket_name=$(jq -r ".buckets[$i].name" $CONFIG_FILE)
    if [ "$bucket_name" != "null" ] && [ -n "$bucket_name" ]; then
        echo -n "   $bucket_name: "
        policy_info=$(mc policy get $MINIO_ALIAS/$bucket_name 2>/dev/null | head -1 || echo "privé")
        if echo "$policy_info" | grep -q "Allow"; then
            echo -e "${GREEN}public (lecture)${NC}"
        else
            echo -e "${YELLOW}privé${NC}"
        fi
    fi
done

echo ""
log_info "👥 Utilisateurs IAM créés:"
mc admin user list $MINIO_ALIAS 2>/dev/null | grep -E "\-user" || log_info "   Aucun utilisateur spécifique détecté"

echo ""
if [ $error_count -eq 0 ]; then
    log_success "🎊 Configuration terminée avec succès!"
    exit 0
else
    log_warning "⚠️ Configuration terminée avec des avertissements"
    exit 0
fi