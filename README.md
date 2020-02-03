# azure-terraform-script

Ce script terraform permet de créer des resources nécessaires pour avoir l'architecture demander par le _client_.


## Deploiement

`cd azure-terraform/`

`./script.sh TENANT_ID SUB_ID CLIENT_ID CLIENT_SECRET APP_GIT`


## Serverless function ([wut...](https://www.memecreator.org/static/images/memes/5005887.jpg))

Pour cette partie, nous avons utilisé Azure Functions:

![1](misc/1.png)
![2](misc/2.png)


## API

Dans l'API nous avons utilisé NODE JS.

La requete suivante nous permet d'appeller la _serverless function_:

![3](misc/3.png)

Pour ensuite sauvegarder:

![3](misc/4.png)
