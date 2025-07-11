db = db.getSiblingDB('admin');

// Création de l'utilisateur avec les permissions
db.createUser({
  user: process.env.MONGODB_USER,
  pwd: process.env.MONGODB_PASSWORD,
  roles: [
    {
      role: 'readWrite',
      db: process.env.MONGODB_DATABASE
    },
    {
      role: 'readWrite',
      db: 'admin'
    }
  ]
});

// Basculer vers la base de données cible
db = db.getSiblingDB(process.env.MONGODB_DATABASE);

// Vous pouvez ajouter d'autres opérations d'initialisation ici
// Par exemple, créer des collections, insérer des données de base, etc.

print('Initialisation terminée avec succès pour la base:', process.env.MONGODB_DATABASE);