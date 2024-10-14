set -e
mongosh <<EOF
use admin
db.createUser({
  user: '$MONGODB_USER',
  pwd:  '$MONGODB_PASSWORD',
  roles: [{
    role: 'readWrite',
    db: '$MONGODB_DATABASE'
  }]
})
use $MONGODB_DATABASE
EOF