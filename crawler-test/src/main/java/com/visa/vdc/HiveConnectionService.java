package com.visa.vdc;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.security.UserGroupInformation;

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
    private String jdbcUrl;
    private Connection conn;

    public HiveConnectionService(String ldapUrl, String driverName, String jdbcUrl) {
        this.ldapUrl = ldapUrl;
        this.driverName = driverName;
        this.jdbcUrl = jdbcUrl;
    }

    public void authenticate(String userName, String keyTabPath, String coreSite, String hdfsSite, String hiveSite, String krb5Path) throws SQLException {
        try {
            if (driverName != null) {
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
        conn = DriverManager.getConnection(jdbcUrl);
    }

    public List<Map<String, String>> executeHiveQuery(String query) throws SQLException {
        List<Map<String, String>> resultList = new ArrayList<>();
        Statement stmt = conn.createStatement();
        ResultSet res = stmt.executeQuery(query);
        while (res.next()) {
            Map<String, String> map = new LinkedHashMap<>();
            for (int i = 1; i <= res.getMetaData().getColumnCount(); i++) {
                map.put(res.getMetaData().getColumnName(i), res.getString(i));
            }
            resultList.add(map);
        }
        return resultList;
    }

    public void close() throws SQLException {
        conn.close();
    }
}
