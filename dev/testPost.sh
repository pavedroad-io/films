
#!/bin/bash

curl -H "Content-Type: application/json" \
     -X POST \
     -d @films.json \
     -v http://localhost:8083/api/v1/namespace/pavedroad.io/films
