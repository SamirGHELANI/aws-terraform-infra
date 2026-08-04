# Infrastructure AWS automatisée avec Terraform & CI/CD

Déploiement d'une infrastructure cloud sécurisée sur AWS, entièrement décrite en
**Infrastructure as Code** (Terraform), avec un **pipeline CI/CD** (GitHub Actions)
qui valide le code à chaque changement et un **backend distant** (S3) pour l'état.

---

## Aperçu

Ce projet met en place un réseau AWS segmenté (zones publique et privée), des
règles de pare-feu, et des serveurs, le tout géré par du code versionné. Un
pipeline vérifie automatiquement la qualité et la validité de l'infrastructure
avant tout déploiement.

**Approche GitOps** : le dépôt Git est la source de vérité de l'infrastructure.

---

## Architecture

```
                        Internet
                            │
                    ┌───────────────┐
                    │ Internet GW   │
                    └───────────────┘
                            │
        ┌───────────────────────────────────────┐
        │              VPC 10.0.0.0/16           │
        │                                        │
        │   ┌────────────────────────────────┐   │
        │   │  Subnet PUBLIC  10.0.1.0/24    │   │
        │   │  ┌──────────────────────────┐  │   │
        │   │  │ EC2 web (SG: SSH/80/443) │  │   │
        │   │  └──────────────────────────┘  │   │
        │   └────────────────────────────────┘   │
        │                                        │
        │   ┌────────────────────────────────┐   │
        │   │  Subnet PRIVÉ   10.0.2.0/24    │   │
        │   │  ┌──────────────────────────┐  │   │
        │   │  │ EC2 backend              │  │   │
        │   │  │ (SG: trafic du web only) │  │   │
        │   │  └──────────────────────────┘  │   │
        │   └────────────────────────────────┘   │
        └───────────────────────────────────────┘

  Le subnet public a une route vers Internet (via l'Internet Gateway).
  Le subnet privé est isolé : accessible uniquement depuis le tier web.
```

---

## Stack technique

| Domaine          | Technologie          |
|------------------|----------------------|
| Infrastructure as Code | Terraform      |
| Cloud            | AWS (VPC, EC2, S3, IAM) |
| CI/CD            | GitHub Actions       |
| État distant     | Backend S3           |
| Accès serveurs   | SSH par clé publique |

---

## Composants de l'infrastructure

| Ressource              | Rôle                                          |
|------------------------|-----------------------------------------------|
| VPC                    | Réseau privé isolé (10.0.0.0/16)              |
| Subnet public          | Zone exposée à Internet (serveur web)         |
| Subnet privé           | Zone isolée (backend protégé)                 |
| Internet Gateway       | Porte vers Internet pour le subnet public     |
| Route Table            | Routage du trafic (0.0.0.0/0 → IGW)           |
| Security Group web     | Autorise SSH, HTTP, HTTPS depuis Internet     |
| Security Group backend | Autorise uniquement le trafic du tier web     |
| EC2 web                | Serveur dans le subnet public                 |
| EC2 backend            | Serveur dans le subnet privé                  |
| Key Pair               | Clé SSH pour l'accès aux instances            |

---

## Sécurité

- **Segmentation réseau** : séparation public / privé. Le backend n'est pas
  joignable depuis Internet, seulement depuis le tier web.
- **Security groups par tier** : le SG backend autorise en source le SG web
  (référence par groupe, pas par IP) — principe du moindre privilège.
- **Accès par clé SSH** : authentification par clé publique, pas de mot de passe.
- **Utilisateur IAM dédié** : Terraform utilise un utilisateur IAM (pas le compte
  root) pour créer les ressources.
- **Secrets protégés** : les credentials AWS et la clé publique passent par les
  secrets GitHub, jamais en clair dans le code. Le tfstate (potentiellement
  sensible) est exclu du dépôt et stocké sur S3.

---

## Pipeline CI/CD

À chaque push sur `main`, GitHub Actions exécute automatiquement :

| Étape              | Rôle                                            |
|--------------------|-------------------------------------------------|
| Terraform Format   | Vérifie le formatage du code (`fmt -check`)     |
| Terraform Init     | Initialise et se connecte au backend S3         |
| Terraform Validate | Vérifie la validité et la cohérence du code     |
| Terraform Plan     | Génère la prévisualisation des changements      |

Le pipeline **valide** le code avant tout déploiement. L'`apply` reste manuel :
un humain applique en connaissance de cause une fois le pipeline au vert. Ce
choix évite les déploiements automatiques non maîtrisés sur l'infrastructure.

---

## État distant (backend S3)

Le fichier d'état Terraform (`tfstate`) est stocké dans un bucket S3, et non en
local. Cela permet de partager le même état entre le poste de travail et le
pipeline CI/CD, garantissant la cohérence et évitant les conflits.

```
Poste local ──┐
              ├──► Bucket S3 (tfstate)
Pipeline CI ──┘
```

---

## Structure du projet

```
aws-terraform-infra/
├── provider.tf          # Configuration du provider AWS
├── vpc.tf               # VPC (réseau)
├── subnets.tf           # Subnets public et privé
├── gateway.tf           # Internet Gateway + routing
├── security.tf          # Security groups
├── data.tf              # Récupération dynamique de l'AMI
├── keypair.tf           # Clé SSH (via variable)
├── ec2.tf               # Instances EC2
├── variables.tf         # Déclaration des variables
├── outputs.tf           # Sorties (IP, commande SSH)
├── backend.tf           # Configuration du backend S3
├── .gitignore           # Exclut state, cache, secrets
└── .github/workflows/
    └── terraform.yml    # Pipeline CI/CD
```

---

## Utilisation

### Prérequis
- Un compte AWS avec un utilisateur IAM et ses clés d'accès
- Terraform et l'AWS CLI installés
- Une clé SSH générée (`ssh-keygen`)

### Configuration locale
```bash
# Configurer les credentials AWS
aws configure

# Renseigner la clé publique SSH dans terraform.tfvars
echo 'ssh_public_key = "ssh-rsa AAAA..."' > terraform.tfvars
```

### Déploiement
```bash
terraform init      # initialise + connecte au backend S3
terraform plan      # prévisualise les changements
terraform apply     # crée l'infrastructure
```

### Connexion au serveur web
```bash
# l'IP est affichée dans les outputs après apply
ssh -i ~/.ssh/aws-terraform ec2-user@<IP_PUBLIQUE>
```

### Destruction
```bash
terraform destroy   # supprime toute l'infrastructure
```

### Pipeline
Le pipeline se déclenche automatiquement à chaque push sur `main`.
Les secrets nécessaires (configurés dans GitHub) :
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `TF_VAR_ssh_public_key`

---

## Concepts mis en œuvre

- **Infrastructure as Code** : toute l'infrastructure décrite en code, versionnée
  et reproductible.
- **Segmentation réseau** : zones publique / privée, routage, pare-feu par tier.
- **GitOps** : le dépôt Git pilote l'infrastructure, validation automatique via CI.
- **Gestion d'état distant** : tfstate sur S3 pour le travail collaboratif.
- **Gestion des secrets** : credentials hors du code, dans les secrets GitHub.
- **Variables Terraform** : code portable, valeurs injectées selon l'environnement.

---

## Améliorations possibles

- Étape `apply` avec approbation manuelle dans le pipeline (déploiement contrôlé)
- Monitoring avec CloudWatch (alarmes CPU, réseau)
- Analyse de sécurité du code Terraform (tfsec, checkov)
- Modularisation avec des modules Terraform réutilisables
- Répartition sur plusieurs zones de disponibilité (haute disponibilité)
