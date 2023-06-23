package org.visa.hive;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.linkedin.common.DatasetUrnArray;
import com.linkedin.common.urn.DatasetUrn;
import com.linkedin.datajob.DataJobInputOutput;
import datahub.client.Callback;
import datahub.client.MetadataWriteResponse;
import datahub.client.rest.RestEmitter;
import datahub.event.MetadataChangeProposalWrapper;
import org.apache.hadoop.hive.ql.QueryPlan;
import org.apache.hadoop.hive.ql.hooks.ExecuteWithHookContext;
import org.apache.hadoop.hive.ql.hooks.HookContext;
import org.apache.hadoop.hive.ql.hooks.ReadEntity;
import org.apache.hadoop.hive.ql.hooks.WriteEntity;
import org.apache.hadoop.hive.ql.plan.HiveOperation;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.hadoop.hive.metastore.api.Database;
import org.apache.hadoop.hive.ql.hooks.Entity;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.URISyntaxException;
import java.util.*;

public class DataHubHiveLineageHook implements ExecuteWithHookContext{

    private static final String CLUSTER_NAME = "CLUSTER_NAME";
    private static final String ENV_NAME = "ENV_NAME";
    private static final String PLATFORM_NAME = "PLATFORM_NAME";
    private static final String PLATFORM_INSTANCE = "PLATFORM_INSTANCE";

    private static final String DATAHUB_GMS_URL = "DATAHUB_GMS_URL";
    private static final String DATAHUB_API_TOKEN = "DATAHUB_API_TOKEN";
    private static final Logger LOGGER = LoggerFactory.getLogger(org.visa.hive.DataHubHiveLineageHook.class);

    public static String dataHubGmsUrl= "https://dev.vdc.visa.com/api/gms";
    public static String dataHubToken= "eyJhbGciOiJIUzI1NiJ9.eyJhY3RvclR5cGUiOiJVU0VSIiwiYWN0b3JJZCI6ImhhcnNodWd1IiwidHlwZSI6IlBFUlNPTkFMIiwidmVyc2lvbiI6IjIiLCJqdGkiOiI1MWIxYjY2Yy1hYmEwLTQzYjMtYTNlMC04Mzk4OTU1NjQzNDAiLCJzdWIiOiJoYXJzaHVndSIsImV4cCI6MTY4OTgzODM2NywiaXNzIjoiZGF0YWh1Yi1tZXRhZGF0YS1zZXJ2aWNlIn0.T6l1-wUYHEwiyjVu3bLxtRNnQtHqD_A6cuOmYi3RbR8";

    private static final HashSet<String> OPERATION_NAMES = new HashSet<>();

    static {
        OPERATION_NAMES.add(HiveOperation.CREATETABLE.getOperationName());
        OPERATION_NAMES.add(HiveOperation.CREATETABLE_AS_SELECT.getOperationName());
        OPERATION_NAMES.add(HiveOperation.QUERY.getOperationName());

        OPERATION_NAMES.add(HiveOperation.ALTERTABLE_EXCHANGEPARTITION.getOperationName());
        OPERATION_NAMES.add(HiveOperation.ALTERTABLE_RENAME.getOperationName());
        OPERATION_NAMES.add(HiveOperation.ALTERTABLE_ADDCOLS.getOperationName());

        OPERATION_NAMES.add(HiveOperation.TRUNCATETABLE.getOperationName());
        OPERATION_NAMES.add(HiveOperation.DROPTABLE.getOperationName());
       // OPERATION_NAMES.add(HiveOperation.DESCTABLE.getOperationName());

      //  OPERATION_NAMES.add(HiveOperation.SHOW_CREATETABLE.getOperationName());
      //  OPERATION_NAMES.add(HiveOperation.SHOW_TRANSACTIONS.getOperationName());


        OPERATION_NAMES.add(HiveOperation.LOAD.getOperationName());
        OPERATION_NAMES.add(HiveOperation.IMPORT.getOperationName());
   //     OPERATION_NAMES.add(HiveOperation.SHOWTABLES.getOperationName());
    }

    @Override
    public void run(HookContext hookContext) throws Exception {

        try {

            QueryPlan plan = hookContext.getQueryPlan();

            String operationName = plan.getOperationName();

            Properties prop = new Properties();
            //FileInputStream reader = new FileInputStream("src/main/resources/config.properties");
            //prop.load(reader);

            Map<String, String> envVariables = System.getenv();
            String clusterName = envVariables.get(CLUSTER_NAME);
            String environmentName = envVariables.get(ENV_NAME);
            String platformName = envVariables.get(PLATFORM_NAME);
            String platformInstanceName = envVariables.get(PLATFORM_INSTANCE);

            if (envVariables.get(DATAHUB_GMS_URL) != null) {
                dataHubGmsUrl = envVariables.get(DATAHUB_GMS_URL);
            }
            if (envVariables.get(DATAHUB_API_TOKEN) != null) {
                dataHubToken = envVariables.get(DATAHUB_API_TOKEN);
            }


            if (clusterName == null || clusterName.isEmpty()) {
                logWithHeader("Cluster Name is not set or is null.");
            } else {
                logWithHeader("Cluster Name: " + clusterName);
            }
            if (environmentName == null || environmentName.isEmpty()) {
                logWithHeader("Environment Name is not set or is null.");
            } else {
                logWithHeader("Environment Name: " + environmentName);
            }
            if (platformName == null || platformName.isEmpty()) {
                logWithHeader("Platform Name is not set or is null.");
            } else {
                logWithHeader("Platform Name: " + platformName);
            }
            if (platformInstanceName == null || platformInstanceName.isEmpty()) {
                logWithHeader("Platform Instance Name is not set or is null.");
            } else {
                logWithHeader("Platform Instance Name: " + platformInstanceName);
            }

            logWithHeader("Query executed: " + plan.getQueryString());

            String outputTable = "";

            if (OPERATION_NAMES.contains(operationName) && !plan.isExplain()) {

                logWithHeader("Monitored Operation " + operationName);

                RestEmitter emitter = RestEmitter.create(b -> b.server(dataHubGmsUrl).token(dataHubToken));

                Set<ReadEntity> inputs = hookContext.getInputs();

                for (Entity entity : inputs) {
                    logWithHeader("Hook metadata input value: " + toJson(entity));
                }

                DatasetUrnArray in = createDatasetUrnArray(inputs, platformName, clusterName, platformInstanceName, environmentName);

                Set<WriteEntity> outputs = hookContext.getOutputs();

                for (Entity entity : outputs) {
                    logWithHeader("Hook metadata output value: " + toJson(entity));
                    outputTable = String.valueOf(entity.getTable());
                }

                DatasetUrnArray out = createDatasetUrnArray(outputs, platformName, clusterName, platformInstanceName, environmentName);

                DataJobInputOutput io = new DataJobInputOutput().setInputDatasets(in)
                        .setOutputDatasets(out);

                String pipelineUrn = "urn:li:dataJob:(urn:li:dataFlow:(" + platformName + "," + clusterName + "." + outputTable + "_pipeline,yarn),QueryExecId_0)";

                MetadataChangeProposalWrapper mcpw = MetadataChangeProposalWrapper.builder()
                        .entityType("dataJob")
                        .entityUrn(pipelineUrn)
                        .upsert()
                        .aspect(io)
                        .build();


                // Non-blocking using callback
                logWithHeader("MetadataChangeProposalWrapper=" + mcpw);

                emitter.emit(mcpw, new Callback() {
                    @Override
                    public void onCompletion(MetadataWriteResponse response) {
                        if (response.isSuccess()) {
                            logWithHeader(String.format("Successfully emitted metadata event for %s", mcpw.getEntityUrn()));
                        }
                    }

                    @Override
                    public void onFailure(Throwable exception) {
                        logWithHeader(
                                String.format("Failed to emit metadata event for %s, aspect: %s due to %s", mcpw.getEntityUrn(),
                                        mcpw.getAspectName(), exception.getMessage()));
                    }
                });
            }
        }catch (Throwable t) {
            StringWriter s = new StringWriter();
            PrintWriter p = new PrintWriter(s);
            t.printStackTrace(p);
            logWithHeader(s.toString());
            p.close();
        }
    }

    private static String toJson(Entity entity) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        switch (entity.getType()) {
            case DATABASE:
                Database db = entity.getDatabase();
                return mapper.writeValueAsString(db);
            case TABLE:
                return mapper.writeValueAsString(entity.getTable().getTTable());
        }
        return null;
    }

    private void logWithHeader(Object obj) {
        LOGGER.info("[CustomHook][Thread: " + Thread.currentThread().getName() + "] | " + obj);
    }

    public <T extends Entity> DatasetUrnArray createDatasetUrnArray(Set<T> inputs, String platformName, String clusterName, String platformInstanceName, String environmentName) throws URISyntaxException {
        DatasetUrnArray in = new DatasetUrnArray();

        for (Entity entity : inputs) {
            String table = String.valueOf(entity.getTable().getTableName());
            String urn1 = "urn:li:dataset:(urn:li:dataPlatform:" + platformName + "," + clusterName + "." + platformInstanceName + "." + table + "," + environmentName + ")";

            in.add(DatasetUrn.createFromString(urn1));
        }

        return in;
    }

}
