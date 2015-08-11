# data container holding Fernet keys, shared by all keystone instances
name="keystone-fernet-keys"
echo "Creating '$name' data container"
mkdir -p /tmp/keystone-fernet-keys
docker create -v /tmp/keystone-fernet-keys:/etc/keystone/fernet-keys \
    --name $name ubuntu > /dev/null

