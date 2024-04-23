package com.visa.vdc;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import java.io.FileInputStream;
import java.io.IOException;
import java.sql.SQLException;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.stream.Collectors;

public class HiveTest {

    private HiveTest() {
    }

    // TODO: Add schema splitting with configuration to crawler test
    private static ObjectMapper objectMapper = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);

    public static void main(String[] args) throws SQLException, IOException {

        Instant globalStart = Instant.now();
        Properties prop = new Properties();
        prop.load(new FileInputStream(args[0]));

        String databaseQuery = "SHOW DATABASES";
        String tablesQuery = "SHOW TABLES IN %s";
        String datasetQuery = "DESCRIBE FORMATTED %s.%s";

        String krb5Debug = prop.getProperty("sun.security.krb5.debug");
        String spnegoDebug = prop.getProperty("sun.security.spnego.debug");
        String securityDebug = prop.getProperty("java.security.debug");
        String sslDebug = prop.getProperty("javax.net.debug");
        String driverName = prop.getProperty("driverName");
        String ldapUrl = prop.getProperty("ldapUrl");
        String krb5Path = prop.getProperty("krb5Path");
        String coreSite = prop.getProperty("coreSite");
        String hdfsSite = prop.getProperty("hdfsSite");
        String hiveSite = prop.getProperty("hiveSite");
        String outputPath = prop.getProperty("output");
        outputPath = outputPath == null || outputPath.trim().length() == 0 ? "./" : outputPath.endsWith("/") ? outputPath : outputPath + "/";

        String username = prop.getProperty("username");
        String keytab = prop.getProperty("keytab");
        String jdbcUrl = prop.getProperty("jdbcUrl");
        String schema = prop.getProperty("schema");
        String fetchSchemasOnly = prop.getProperty("fetchSchemasOnly") == null ? "" : prop.getProperty("fetchSchemasOnly");

        System.out.println(String.format("sun.security.krb5.debug: %s", krb5Debug));
        System.out.println(String.format("sun.security.spnego.debug: %s", spnegoDebug));
        System.out.println(String.format("java.security.debug: %s", securityDebug));
        System.out.println(String.format("javax.net.debug: %s", sslDebug));
        System.out.println(String.format("Driver name: %s", driverName));
        System.out.println(String.format("LDAP Url: %s", ldapUrl));
        System.out.println(String.format("krb5 Path: %s", krb5Path));
        System.out.println(String.format("Core Site: %s", coreSite));
        System.out.println(String.format("HDFS Site: %s", hdfsSite));
        System.out.println(String.format("Hive Site: %s", hiveSite));
        System.out.println(String.format("Output Path: %s", outputPath));
        System.out.println(String.format("Username: %s", username));
        System.out.println(String.format("Keytab: %s", keytab));
        System.out.println(String.format("JDBC Url: %s", jdbcUrl));
        System.out.println(String.format("Schema: %s", schema));
        System.out.println(String.format("Fetch Schemas Only: %s", fetchSchemasOnly));


        if (krb5Debug != null) {
            System.setProperty("sun.security.krb5.debug", krb5Debug);
        }
        if (spnegoDebug != null) {
            System.setProperty("sun.security.spnego.debug", spnegoDebug);
        }
        if (securityDebug != null) {
            System.setProperty("java.security.debug", securityDebug);
        }
        if (sslDebug != null) {
            System.setProperty("javax.net.debug", sslDebug);
        }


        HiveConnectionService hiveConnectionService = new HiveConnectionService(ldapUrl, driverName, jdbcUrl);
        hiveConnectionService.authenticate(username, keytab, coreSite, hdfsSite, hiveSite, krb5Path);
        Instant start = Instant.now();
        List<Map<String, String>> databaseMap = hiveConnectionService
                .executeHiveQuery(databaseQuery);

        Instant end = Instant.now();
        String databaseOutputPath = outputPath + "database-list.txt";
        FileUtil.writeFile(databaseOutputPath, objectMapper.writeValueAsString(databaseMap));
        System.out.println(String.format("\n\n#############\n\nWriting file %s \n\nTime Taken: %s\n\n#############\n\n",
                databaseOutputPath, ReadableTime.format(end.toEpochMilli() - start.toEpochMilli())));

        List<String> schemaList;
        if (schema == null || "".equals(schema.trim())) {
            schemaList = databaseMap.stream().map(map -> map.get("database_name")).collect(Collectors.toList());
            System.out.println("\n\nSchema list from Hive Source\n\n");
            System.out.println(schemaList);
        } else {
            schemaList = Arrays.asList(schema.trim().split("\\s*,+\\s*,*\\s*"));
        }
        for (String schemaName : schemaList) {
            start = Instant.now();
            List<Map<String, String>> data = hiveConnectionService
                    .executeHiveQuery(String.format(tablesQuery, schemaName));

            end = Instant.now();
            String schemaOutputPath = outputPath + "schemas/" + schemaName + ".txt";
            FileUtil.writeFile(schemaOutputPath, objectMapper.writeValueAsString(data));
            System.out.println(String.format("\n\n#############\n\nWriting file %s \n\nTime Taken: %s\n\n#############\n\n",
                    schemaOutputPath, ReadableTime.format(end.toEpochMilli() - start.toEpochMilli())));

            if ("true".equalsIgnoreCase(fetchSchemasOnly)) {
                continue;
            }
            String table = prop.getProperty(schema + ".table");
            if (table == null || "*".equals(table) || table.trim().length() == 0) {
                for (Map<String, String> map : data) {
                    crawlTable(outputPath, datasetQuery, hiveConnectionService, schemaName, map.get("tab_name"));
                }
            } else {
                List<String> tableList = Arrays.asList(table.trim().split("\\s*,+\\s*,*\\s*"));
                for (String tableName : tableList) {
                    crawlTable(outputPath, datasetQuery, hiveConnectionService, schemaName, tableName);
                }
            }
        }

        hiveConnectionService.close();

        Instant globalEnd = Instant.now();
        System.out.println(String.format("Time taken for completion: %s",
                ReadableTime.format(globalEnd.toEpochMilli() - globalStart.toEpochMilli())));

    }

    private static void crawlTable(String outputPath, String tablesQuery, HiveConnectionService hiveConnectionService,
                                   String schemaName, String tableName) throws SQLException, IOException {
        Instant start = Instant.now();
        List<Map<String, String>> tableData = hiveConnectionService
                .executeHiveQuery(String.format(tablesQuery, schemaName, tableName));

        Instant end = Instant.now();
        String tableOutputPath = outputPath + "schemas/" + schemaName + "/" + tableName + ".txt";
        FileUtil.writeFile(tableOutputPath, objectMapper.writeValueAsString(tableData));
        System.out.println(String.format("\n\n#############\n\nWriting file %s \n\nTime Taken: %s\n\n#############\n\n",
                tableOutputPath, ReadableTime.format(end.toEpochMilli() - start.toEpochMilli())));
    }
}
