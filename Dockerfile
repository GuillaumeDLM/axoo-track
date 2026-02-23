# On utilise une image allégée de Node.js (idéal pour la performance)
FROM node:20-alpine

# On définit le dossier de travail dans le conteneur
WORKDIR /app

# On copie d'abord les fichiers de dépendances pour optimiser le cache Docker
COPY package*.json ./
COPY prisma ./prisma/

# On installe les dépendances Node.js
RUN npm install

# ⚠️ ÉTAPE CRUCIALE POUR PRISMA : On génère le client à partir de ton schema.prisma
RUN npx prisma generate

# On copie le reste du code source
COPY . .

# Si tu utilises TypeScript, on compile le code (dé-commente cette ligne si besoin)
# RUN npm run build

# On indique que l'application va écouter sur le port 3000
EXPOSE 3000

# La commande pour démarrer l'API
CMD ["npm", "start"]