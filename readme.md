# Connecting a application to multiple GemFire instances

In a typical GemFire deployment there is a 1:1 correlation to Application and GemFire Cluster.   However there are always exceptions to the rule.    GemFire can allow designs where an application would like to connect up to more then one cluster.   But there are some caviots that the architect should heed.

1. Don't use PDX - The PDX type registry on the client wasn't designed for this use case.   
2. Region Names MUST be different - The region names must be unique across clusters.

## How does this work

The method that enables this is GemFire connection pools configured for accessing the various clusters.   The in the application when it is creating the client regions we assign the connection pool to the region.    

In the following example we can get a sense for how this is achieved.

```java
private Region createRegion(ClientCache clientCache, ...) {

    PoolFactory factory = PoolManager.createFactory();
    //... Configure the Pool to connect to the various clusters ...
    factory.create(poolName); // poolName is the name given to the cluster
    return clientCache.
            createClientRegionFactory(ClientRegionShortcut.PROXY).
            setPoolName(poolName).
            create(regionName); //regionName is the unique name of the region across all clusters
}
```

# Running Example

## Start GemFire Locally

In the scripts directory look for a `startGemFire.sh` bash script that will lanuch GemFire.    The script takes an integer argument - for this example just run the script twice to launch two seperate GemFire clusters.

The scripts assume that GemFire has been uncompressed and the `bin` directory has been added to the path.   This is need to launch `gfsh` the GemFire command line interface. 

```bash
./startGemFire.sh 1
./startGemFire.sh 2
```
This will cause two seperate clusters to be started with 2 locators and 2 servers in each cluster.   The locators will be localhost[10334],localhost[10335] and localhost[20334],localhost[20335].    Also pulse can be viewed for both clusters via - http://localhost:10074/pulse and http://localhost:20074/pulse

Once the clusters are up they will have a region defined in both distributed systems - `cluster1` and `cluster2`.   Those regions are need for the application to utilize each cluster.

## Start the application

The project uses spring boot and Apache Geode libaries to connect to GemFire.   To launch the application type:

```bash
mvn clean spring-boot:run
```

This launches a simple application that will inject "customer" records into GemFire once the Rest endpoint is called.

```bash
curl --location --request GET 'http://localhost:8080/create?count=10&regionId=cluster1'
```

That will insert 10 customers into the region called `cluster1`.    That region is located on `cluster1`.

```bash
curl --location --request GET 'http://localhost:8080/create?count=150&regionId=cluster2'
```
That command will insert 150 customers into the region called `cluster2`.   The region is located in `cluster2`.


