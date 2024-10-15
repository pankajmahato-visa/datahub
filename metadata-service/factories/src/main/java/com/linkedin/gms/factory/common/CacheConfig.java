package com.linkedin.gms.factory.common;

import com.github.benmanes.caffeine.cache.Caffeine;
import com.hazelcast.config.Config;
import com.hazelcast.config.YamlConfigBuilder;
import com.hazelcast.core.Hazelcast;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.spring.cache.HazelcastCacheManager;
import java.util.concurrent.TimeUnit;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cache.CacheManager;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CacheConfig {

  @Value("${cache.primary.ttlSeconds:600}")
  private int cacheTtlSeconds;

  @Value("${cache.primary.maxSize:10000}")
  private int cacheMaxSize;

//  @Value("${searchService.cache.hazelcast.serviceName:hazelcast-service}")
//  private String hazelcastServiceName;

  @Bean
  @ConditionalOnProperty(name = "searchService.cacheImplementation", havingValue = "caffeine")
  public CacheManager caffeineCacheManager() {
    CaffeineCacheManager cacheManager = new CaffeineCacheManager();
    cacheManager.setCaffeine(caffeineCacheBuilder());
    return cacheManager;
  }

  private Caffeine<Object, Object> caffeineCacheBuilder() {
    return Caffeine.newBuilder()
        .initialCapacity(100)
        .maximumSize(cacheMaxSize)
        .expireAfterAccess(cacheTtlSeconds, TimeUnit.SECONDS)
        .recordStats();
  }

  @Bean
  @ConditionalOnProperty(name = "searchService.cacheImplementation", havingValue = "hazelcast")
  public CacheManager hazelcastCacheManager() {
    YamlConfigBuilder yamlConfigBuilder = new YamlConfigBuilder();
    Config config = yamlConfigBuilder.build();
    HazelcastInstance hazelcastInstance = Hazelcast.newHazelcastInstance(config);
    return new HazelcastCacheManager(hazelcastInstance);
  }
}
