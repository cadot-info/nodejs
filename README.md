# nodejs
Docker for nodejs,npm and php   with composer, yarn, nodejs and npm
## execution in your symfony directory
`
docker run -d -p 80:80  --name nodejs -v .:/app cadotinfo/nodejs
`
## or by docker-compose with traefik
`
...
image: cadotinfo/nodejs 
    container_name: nodejs
    volumes:
      - /home/ubuntu/my_symfony:/app
    networks:
      - web
    restart: always
    labels:
        - "traefik.enable=true"
        - "traefik.http.routers.nodejs.rule=Host(`nodejs.website.com`)"
...
`
# nodejs
