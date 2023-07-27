package com.visa.vdc;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.security.UserGroupInformation;

import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;


public class HiveConnectionService {

    private String driverName;
    private String ldapUrl;

    public HiveConnectionService(String ldapUrl, String driverName) {
        this.ldapUrl = ldapUrl;
        this.driverName = driverName;
    }

    public List<Map<String, String>> executeHiveQuery(String userName, String keyTabPath, String jdbcURL,
                                                      String coreSite, String hdfsSite, String hiveSite, String krb5Path, String query)
            throws SQLException {
        try {
            if (driverName != null) {
                String absolutePath = new File(".").getAbsolutePath();
                System.out.println(absolutePath);


                String classpath = System.getProperty("java.class.path");
                String[] classPathValues = classpath.split(File.pathSeparator);
                for (String classPath : classPathValues) {
                    System.out.println(classPath);
                }
                Class.forName(driverName);
            }
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
        Configuration systemConf = new Configuration();
        System.setProperty("javax.security.auth.useSubjectCredsOnly", "false");
        if (krb5Path != null) {
            System.setProperty("java.security.krb5.conf", krb5Path);
        }
        if (coreSite != null) {
            systemConf.addResource(new Path(coreSite));
        }
        if (hdfsSite != null) {
            systemConf.addResource(new Path(hdfsSite));
        }
        if (hiveSite != null) {
            systemConf.addResource(new Path(hiveSite));
        }
        systemConf.set("hadoop.security.authentication", "kerberos");
        if (ldapUrl == null) {
            systemConf.set("hadoop.security.group.mapping", "org.apache.hadoop.security.LdapGroupsMapping");
//            systemConf.set("hadoop.security.group.mapping.ldap.url", "ldap://visanpadoce.visa.com:389");
            systemConf.set("hadoop.security.group.mapping.ldap.url", "ldaps://test.visa.com:636");
        } else if (!"false".equals(ldapUrl)) {
            systemConf.set("hadoop.security.group.mapping", "org.apache.hadoop.security.LdapGroupsMapping");
            systemConf.set("hadoop.security.group.mapping.ldap.url", ldapUrl);
        }
        UserGroupInformation.setConfiguration(systemConf);
        try {
            UserGroupInformation.loginUserFromKeytab(userName, keyTabPath);
        } catch (IOException e) {
            e.printStackTrace();
        }
        List<Map<String, String>> resultList = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(jdbcURL)) {

            Statement stmt = conn.createStatement();
            ResultSet res = stmt.executeQuery(query);
            while (res.next()) {
                Map<String, String> map = new LinkedHashMap<>();
                for (int i = 1; i <= res.getMetaData().getColumnCount(); i++) {
                    map.put(res.getMetaData().getColumnName(i), res.getString(i));
                }
                resultList.add(map);
            }
        }
        return resultList;
    }
}
