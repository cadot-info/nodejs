# symfony5
Docker for symfony 5 with composer, yarn, nodejs and npm
## execution in your symfony directory
`
docker run -d -p 80:80  --name symfony5 -v .:/app cadotinfo/symfony5
`
## or by docker-compose with traefik
`
...
image: cadotinfo/symfony5 
    container_name: symfony5
    volumes:
      - /home/ubuntu/my_symfony:/app
    networks:
      - web
    restart: always
    labels:
        - "traefik.enable=true"
        - "traefik.http.routers.symfony5.rule=Host(`symfony5.website.com`)"
...
`
