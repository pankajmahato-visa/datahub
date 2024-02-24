package com.linkedin.metadata.spring;

import com.visa.cloud.client.ConfigClient;
import java.io.IOException;
import java.io.StringReader;
import java.util.Arrays;
import java.util.Properties;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;

@Slf4j
public class CloudViewPropertySource {

  static CloudViewPropertySource instance;
  private final Properties vaultProps;

  private CloudViewPropertySource() throws IOException {
    log.info("Fetching config properties from cloudview vault");

    String configLocation = System.getenv("CONFIG_LOCATION");
    if (!StringUtils.isEmpty(System.getProperty("CONFIG_LOCATION"))) {
      configLocation = System.getProperty("CONFIG_LOCATION");
    }

    String configFile = System.getenv("CONFIG_FILE");
    if (!StringUtils.isEmpty(System.getProperty("CONFIG_FILE"))) {
      configFile = System.getProperty("CONFIG_FILE");
    }

    vaultProps = new Properties();
    if (configLocation != null) {
      ConfigClient client = new ConfigClient().build();
      String configurations = client.loadVMConfigurations(configFile);
      vaultProps.load(new StringReader(configurations));
      log.info(
          "Keys received from cloudview vault: {}",
          Arrays.toString(vaultProps.keySet().toArray(new Object[0])));
    } else {
      log.error("Config location for CV vault not provided. No properties retrieved.");
    }
  }

  public static CloudViewPropertySource getInstance() throws IOException {
    if (instance == null) {
      instance = new CloudViewPropertySource();
    }
    return instance;
  }

  public Properties getVaultProps() {
    return vaultProps;
  }
}
