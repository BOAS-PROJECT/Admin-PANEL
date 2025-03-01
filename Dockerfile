# Utiliser l'image PHP officielle avec Alpine pour un environnement léger
FROM php:8.2-fpm-alpine

# Installation des dépendances système et PHP nécessaires
RUN apk add --no-cache \
    oniguruma-dev \
    libxml2-dev \
    nodejs \
    npm

# Installer les extensions PHP requises
RUN docker-php-ext-install \
    bcmath \
    ctype \
    fileinfo \
    mbstring \
    pdo_mysql \
    xml

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Définir le dossier racine du serveur web
ENV WEB_DOCUMENT_ROOT /app/public
ENV APP_ENV production

# Définir le répertoire de travail
WORKDIR /app

# Copier tout le contenu du projet dans le conteneur
COPY . .

# Créer un utilisateur et un groupe 'application' pour la sécurité
RUN addgroup -S application && adduser -S application -G application

# Changer les permissions des fichiers
RUN chown -R application:application /app

# Copier le fichier .env.example en .env s'il n'existe pas
RUN cp -n .env.example .env

# Installation des dépendances Laravel en mode production
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Générer la clé d'application Laravel
RUN php artisan key:generate

# Optimisation du cache de configuration, routes et vues
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# Installation et compilation des assets frontend
RUN npm install
RUN npm run build

# Changer l'utilisateur exécutant le conteneur pour éviter d'utiliser root
USER application

# Définir la commande d'exécution par défaut
CMD ["php-fpm"]
