# TP 23 · Migration d’Eureka vers Consul

Mohamed Hamza Ibntalib

Le projet reprend les services Client, Voiture et Gateway du [dépôt de départ](https://github.com/lachgar/ms_rest_template/tree/177c56bc6f0f3e8b5ecaf7be876a2bc38e7c739c). Les trois services s’enregistrent auprès de Consul et exposent leur état via Spring Boot Actuator. La passerelle crée ses routes à partir du catalogue Consul. Le service Voiture résout directement `SERVICE-CLIENT` avec Spring Cloud LoadBalancer.

| Composant | Nom enregistré | Port local |
| --- | --- | --- |
| Consul | — | 8500 |
| Client | `SERVICE-CLIENT` | 8088 |
| Voiture | `SERVICE-CAR` | 8082 |
| Gateway | `SERVICE-GATEWAY` | 8888 |

## 1. État de départ avec Eureka

Pour reproduire l’état initial, utiliser une copie séparée du projet source.

```bash
git clone https://github.com/lachgar/ms_rest_template.git
cd ms_rest_template
git checkout 177c56bc6f0f3e8b5ecaf7be876a2bc38e7c739c
```

Importer les POM de `server_eureka`, `client`, `car` et `gateway` dans l’IDE. Avec Java 17 et une base MySQL locale joignable sur le port 3306 pour les deux services métier, démarrer les quatre modules dans des terminaux séparés, dans cet ordre.

```bash
mvn -f server_eureka/pom.xml spring-boot:run
mvn -f client/pom.xml spring-boot:run
mvn -f car/pom.xml spring-boot:run
mvn -f gateway/pom.xml spring-boot:run
```

Le tableau de bord Eureka est disponible sur [localhost:8761](http://localhost:8761/).

## 2. Démarrer Consul

Installer [Consul](https://developer.hashicorp.com/consul/install), puis arrêter les applications de l’état initial et démarrer l’agent de développement. Sous Windows, la même commande fonctionne avec `consul.exe` dans le `PATH`.

```bash
consul agent -dev
```

Ouvrir [la liste des services Consul](http://localhost:8500/ui/dc1/services).

## 3. Compiler et lancer les services migrés

Les POM utilisent `spring-cloud-starter-consul-discovery` et les classes principales conservent `@EnableDiscoveryClient`. Chaque `application.yml` définit le nom du service, l’adresse de l’agent et la vérification Actuator. Le serveur Eureka s’exécute uniquement lors de la reproduction de l’état initial.

Depuis la racine de `Lab23C2` avec Java 17 et Maven :

```bash
mvn -q -DskipTests clean package
mvn test
```

Pour le démarrage local, les configurations par défaut utilisent MySQL sur le port 3309 et les schémas `Micro_ClientDB` et `carservicedb`. Adapter `DB_URL`, `DB_USER` et `DB_PASSWORD` à l’installation. On peut aussi modifier `CONSUL_HOST` et `CONSUL_PORT` si nécessaire.

```bash
mvn -f client/pom.xml spring-boot:run
mvn -f car/pom.xml spring-boot:run
mvn -f gateway/pom.xml spring-boot:run
```

## 4. Vérifier la migration

Dans Consul, vérifier que chaque service a une instance avec l’état `passing`, puis ouvrir les routes de la passerelle. La base Voiture est vide au premier démarrage. Sa route retourne alors `[]` après avoir consulté le service Client.

```bash
curl -fsS 'http://localhost:8500/v1/health/service/SERVICE-CLIENT?passing=true'
curl -fsS 'http://localhost:8500/v1/health/service/SERVICE-CAR?passing=true'
curl -fsS 'http://localhost:8500/v1/health/service/SERVICE-GATEWAY?passing=true'
curl -fsS http://localhost:8888/SERVICE-CLIENT/api/client
curl -fsS http://localhost:8888/SERVICE-CAR/api/car
```

## Démarrage avec Docker Compose

Arrêter l’agent et les applications lancés en local avant de démarrer Compose. Compose installe l’agent Consul, les trois services et les deux bases MySQL. Les données sont stockées dans des volumes distincts. La configuration accepte `LAB_DB_PASSWORD` via l’environnement ou un fichier `.env`.

```bash
docker compose config --quiet
docker compose up --build -d
docker compose ps
```

Consul et le Gateway restent accessibles sur les mêmes ports. Les commandes de validation de l’étape 4 s’appliquent également à ce déploiement.

```bash
docker compose down
```
