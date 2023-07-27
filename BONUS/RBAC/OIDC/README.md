# Boundary and Auth0 - OIDC Integration

Let's create an Auth0 dev Org where the first step would be to create an Application with access to Auth0 MGMT API

![1690452689777](image/README/1690452689777.png)

This attributes will have to be set as enviromental variables

![1690452738465](image/README/1690452738465.png)

```bash
export AUTH0_DOMAIN="<domain>"
export AUTH0_CLIENT_ID="<client-id>" 
export AUTH0_CLIENT_SECRET="<client_secret>"
```

Now what we are going to do is Terraform the content of this guide: https://developer.hashicorp.com/boundary/tutorials/identity-management/oidc-auth
