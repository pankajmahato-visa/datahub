package com.visa.vdc;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Properties;

public class HiveTest {

    private HiveTest() {
    }

    private static ObjectMapper objectMapper = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);

    public static void main(String[] args) throws SQLException, IOException {


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
        System.out.println(outputPath);
        outputPath = outputPath == null || outputPath.isBlank() ? "./" : outputPath.endsWith("/") ? outputPath : outputPath + "/";

        String username = prop.getProperty("username");
        String keytab = prop.getProperty("keytab");
        String jdbcUrl = prop.getProperty("jdbcUrl");
        String schema = prop.getProperty("schema");

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


        HiveConnectionService hiveConnectionService = new HiveConnectionService(ldapUrl, driverName);
        List<Map<String, String>> databaseMap = hiveConnectionService
                .executeHiveQuery(username, keytab, jdbcUrl, coreSite, hdfsSite, hiveSite, krb5Path, databaseQuery);

        String databaseOutputPath = outputPath + "database-list.txt";
        FileUtil.writeFile(databaseOutputPath, objectMapper.writeValueAsString(databaseMap));
        System.out.println("\n\n#############\n\nWriting file " + databaseOutputPath + " \n\n#############\n\n");

        new File("schemas").mkdirs();

        List<String> schemaList = Arrays.asList(schema.split(","));
        for (String schemaName : schemaList) {
            List<Map<String, String>> data = hiveConnectionService
                    .executeHiveQuery(username, keytab, jdbcUrl, coreSite, hdfsSite, hiveSite, krb5Path, String.format(tablesQuery, schemaName));

            String schemaOutputPath = outputPath + "schemas/" + schemaName + ".txt";
            FileUtil.writeFile(schemaOutputPath, objectMapper.writeValueAsString(data));
            System.out.println("\n\n#############\n\nWriting file " + schemaOutputPath + " \n\n#############\n\n");

            new File("schemas/" + schemaName).mkdirs();
            String table = prop.getProperty(schema + ".table");
            if (table == null || "*".equals(table) || table.isBlank()) {
                for (Map<String, String> map : data) {
                    crawlTable(outputPath, datasetQuery, username, keytab, jdbcUrl, coreSite, hdfsSite, hiveSite, krb5Path,
                            hiveConnectionService, schemaName, map.get("tab_name"));
                }
            } else {
                List<String> tableList = Arrays.asList(table.split(","));
                for (String tableName : tableList) {
                    crawlTable(outputPath, datasetQuery, username, keytab, jdbcUrl, coreSite, hdfsSite, hiveSite, krb5Path,
                            hiveConnectionService, schemaName, tableName);
                }
            }
        }

    }

    private static void crawlTable(String outputPath, String tablesQuery, String username, String keytab, String jdbcUrl, String coreSite,
                                   String hdfsSite, String hiveSite, String krb5Path, HiveConnectionService hiveConnectionService,
                                   String schemaName, String tableName) throws SQLException, IOException {
        List<Map<String, String>> tableData = hiveConnectionService
                .executeHiveQuery(username, keytab, jdbcUrl, coreSite, hdfsSite, hiveSite, krb5Path, String.format(tablesQuery, schemaName, tableName));

        String tableOutputPath = outputPath + "schemas/" + schemaName + "/" + tableName + ".txt";
        FileUtil.writeFile(tableOutputPath, objectMapper.writeValueAsString(tableData));
        System.out.println("\n\n#############\n\nWriting file " + tableOutputPath + " \n\n#############\n\n");
    }
}
