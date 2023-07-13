# Boundary Demo 


# 1. Crear clusters de Vault y Boundary en HCP

```bash
cd \#1_Plataforma/

<export AWS Creds>
terraform init
terraform apply -auto-approve
terraform output -json > data.json
export BOUNDARY_ADDR=$(cat data.json | jq -r .boundary_public_url.value)
export VAULT_ADDR=$(cat data.json | jq -r .vault_public_url.value)
export VAULT_NAMESPACE=admin
boundary authenticate
export VAULT_TOKEN=$(cat data.json | jq -r .vault_token.value)
```

# 2. Crear una instancia de EC2 sobre la que loguearse vía Boundary

```bash
cd ../\#2_First_target
terraform init
# Creamos primero la RSA key y el certificado
terraform apply -auto-approve -target=aws_key_pair.ec2_key -target=tls_private_key.rsa_4096_key
# La configuración de EC2 + boundary
terraform apply -auto-approve
```

Una vez se ha desplegado, comprobamos que podemos acceder a la instancia usando la key generada

```bash
ssh -i cert.pem ubuntu@$(terraform output -json | jq -r .target_publicIP.value)
```

Nos logueamos en el desktop y obtenemos los credenciales. En este caso estamos haciendo uso de “Credential Brokering” donde los credenciales se definen de forma estática en Boundary directamente.

![Untitled](Boundary%20Demo%20NTT%20f4c523f026c24c13829de892037080fc/Untitled.png)

![Untitled](Boundary%20Demo%20NTT%20f4c523f026c24c13829de892037080fc/Untitled%201.png)

En base a los datos de arriba nos podemos conectar por medio de una sesión tunelizada por Boundary

```bash
ssh [ubuntu@127.0.0.1](mailto:ubuntu@127.0.0.1) -p 49165 -i cert.pem
```

o mejor todavía podemos usar el cliente de boundary. Puesto que no precisaremos de definir ningún atributo adicional (nombre de usuario o pasar el certificado)

```bash
# Para obtener la list de los targets
boundary targets list -recursive
# Para conectar con el target en cuestión
boundary connect ssh -target-id=<id>
```

![Untitled](Boundary%20Demo%20NTT%20f4c523f026c24c13829de892037080fc/Untitled%202.png)

# 3.  Usar Vault credential Brokering

En este ejemplo vamos a hacer dos cosas.

1. Por un lado vamos a instalar un servidor linux donde instalaremos una base de datos. Esta base de datos se va a configurar para hacer uso de Vault.
2. Por otro lado vamos a instalar un servidor windows  y usar boundary para acceder vía RDP. En este caso, los credenciales se definirán de forma estática en Boundary

Antes de comenzar el workflow de Terraform debemos obtener un admin token de Vault para poder aplicar la configuración.  En el primer paso añadimos el token mediante variable de entorno

```bash
export VAULT_TOKEN = "hvs.CAESIAihr7BXA4WosJTKMLIzFcDS3u8nk0WZmiRBzPjtNuB-GicKImh2cy5zNE9mQjF3QTNVZGN4aUE2bHlqcVhna20ud2FNY00QmwI”
```

Puesto que la instancia que corre la base de datos necesita algo de tiempo para estar lista, una vez se corren los init scripts, la vamos a correr antes junto con la instancia de windows. Posteriormente correremos el resto del código de terraform.

```bash
cd ../\#3_Vault_Credential_Brokering
terraform init
# Instalamos primero los hosts en AWS
terraform apply -auto-approve -target=aws_instance.postgres_target -target=aws_instance.windows-server
# Configuramos Vault y Boundary
terraform apply -auto-approve
```

Llegados a este punto podemos chequear el acceso a la base de datos con dos accesos distintos, db admin y analyst.

![Untitled](Boundary%20Demo%20NTT%20f4c523f026c24c13829de892037080fc/Untitled%203.png)

Lo que resulta en la siguiente conexión

```bash
psql -h 127.0.0.1 -p 54229 -U v-token-to-dba-caBAedEO2ShtIVxXd3NM-1689081824 -d northwind
```

Con la CLI podemos pasar los credenciales directamente a psql usando los exec plugins

```bash
boundary connect postgres -target-id <id> -dbname northwind
```

puesto que hemos instalado IIS en el host de windows podemos también hacer uso de un target para procesar tráfico web Usando el Windows HTTP target

# 4.  SSH Certificate Injection

Como en el caso anterior tenemos que actualizar el token usado para acceder a Vault. Separamos el código en dos porque primeros tenemos que crear la SSH Secret Engine, derivar de esta la CA, que en un segundo paso subiremos al linux host.

```bash
cd ../#4_Vault_SSH_Injection/vault_config
terraform init
terraform apply -auto-approve
cd ..
terraform init 
terraform apply -auto-approve
```

Una vez aplicada la configuración tendremos un target más en nuestra lista de targets. Conectamos con el target y como estamos usando ssh injection no obtendremos ningún tipo de credenciales

![Untitled](Boundary%20Demo%20NTT%20f4c523f026c24c13829de892037080fc/Untitled%204.png)

De tal manera que solo tendremos que hacer un

```bash
ssh 127.0.0.1 -p 56533
```

Igualmente desde la cli podemos hacer uso del boundary client sabiendo el target id

```bash
boundary connect ssh -target-id=<id>
```

# 5.  Self Managed Workers

```bash
cd ../\#5\ Self_Managed_Worker/
terraform init
cp ../\#4_Vault_SSH_Injection/vault_ca.pub vault_ca.pub
terraform apply -auto-approve
```

En este ejemplo vamos a instalar un self-managed worker y registrarlo de forma automática con boundary. Este Worker se va a desplegar en una public subnet con acceso a internet que estará conectada a una private subnet donde desplegaremos un Ubuntu. Este Ubuntu se ha configurado con la CA de Vault de tal manera que haremos uso de Vault para la inyección de certificados

# 6.  Multi Hop

```bash
cd ../\#6_Multi_hop/
terraform init
cp ../\#4_Vault_SSH_Injection/vault_ca.pub vault_ca.pub
terraform apply -auto-approve
```

En este caso para que funcione el egress worker con un ingress worker tenemos que modificar la configuración del `downstream_worker.tf` para que dicho worker apunte correctamente

![Untitled](Boundary%20Demo%20NTT%20f4c523f026c24c13829de892037080fc/Untitled%205.png)

en el caso previo, el worker que instalamos se registraba contra el control plane directamente mientras que en este caso, el worker se registra via uno de los managed workers, que en este caso actua como upstream worker.
