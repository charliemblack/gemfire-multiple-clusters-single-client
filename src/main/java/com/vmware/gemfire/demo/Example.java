package com.vmware.gemfire.demo;

import io.codearte.jfairy.Fairy;
import io.codearte.jfairy.producer.person.Person;
import org.apache.geode.cache.Region;
import org.apache.geode.cache.client.*;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

@SpringBootApplication
@RestController
public class Example {

    @Resource(name = "clusterMap")
    private Map<String, Region> clusterMap;

    @Bean
    public Map<String, Region> clusterMap() {

        ClientCache clientCache = new ClientCacheFactory()
                .set("log-level", "config")
                .create();

        Map<String, Region> map = new HashMap<>();

        map.put("cluster1", createRegion(clientCache, "cluster1", 10334, 10335));
        map.put("cluster2", createRegion(clientCache, "cluster2", 20334, 20335));

        return map;
    }

private Region createRegion(ClientCache clientCache, String regionName, int... port) {

    PoolFactory factory = PoolManager.createFactory();

    for (int currPort : port) {
        factory.addLocator("localhost", currPort);
    }
    Pool pool = factory.create(regionName);
    return clientCache.
            createClientRegionFactory(ClientRegionShortcut.PROXY).
            setPoolName(regionName).
            create(regionName);
}


    @RequestMapping("/create")
    public String search(@RequestParam(value = "count", required = false, defaultValue = "50") long count,
                         @RequestParam(value = "regionId", required = false, defaultValue = "cluster1") String regionId) {
        Region clusterRegion = clusterMap.get(regionId);
        Fairy fairy = Fairy.create();
        HashMap bulk = new HashMap();
        final AtomicLong counter = new AtomicLong(0);
        for (long i = 0; i < count; i++) {
            Person person = fairy.person();
            Customer customer = Customer.builder()
                    .firstName(person.getFirstName())
                    .middleName(person.getMiddleName())
                    .lastName(person.getLastName())
                    .email(person.getEmail())
                    .username(person.getUsername())
                    .passportNumber(person.getPassportNumber())
                    .password(person.getPassword())
                    .telephoneNumber(person.getTelephoneNumber())
                    .dateOfBirth(person.getDateOfBirth().toString())
                    .age(person.getAge())
                    .companyEmail(person.getCompanyEmail())
                    .nationalIdentificationNumber(person.getNationalIdentificationNumber())
                    .nationalIdentityCardNumber(person.getNationalIdentityCardNumber())
                    .passportNumber(person.getPassportNumber())
                    .guid(UUID.randomUUID().toString()).build();
            bulk.put(customer.getGuid(), customer);
            if (bulk.size() > 1000) {
                clusterRegion.putAll(bulk);
                System.out.println("Stored " + bulk.size() + " at " + new Date() + " total amount " + counter.addAndGet(bulk.size()));
                bulk.clear();
            }
        }
        if (!bulk.isEmpty()) {
            clusterRegion.putAll(bulk);
            System.out.println("Stored " + bulk.size() + " at " + new Date() + " total amount " + counter.addAndGet(bulk.size()));
        }
        return "Region " + clusterRegion.getName() + " has " + clusterRegion.keySetOnServer().size() + " entries.";
    }

    public static void main(String[] args) {
        System.out.println("Example.main");
        SpringApplication.run(Example.class, args);
    }
}
