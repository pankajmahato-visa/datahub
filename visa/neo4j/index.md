## Neo4J

### Indexes created for Neo4j

| Nodes/label | IndexIndexed | Property |
| ----------- | ------------ | -------- |
|     container        |       container_index       |  urn        |
|     corpuser        |       corpuser_index       |  urn        |
|     dataset        |       dataset_index       |  urn        |
|     domain        |       domain_index       |  urn        |
|     glossaryNode        |       glossaryNode_index       |  urn        |
|     glossaryTerm        |       glossaryTerm_index       |  urn        |
|     schemaField        |       schemaField_index       |  urn        |
|     dataFlow        |       dataFlow_index       |  urn        |
|     dataJob        |       dataJob_index       |  urn        |
|     dataProcessInstance        |       dataProcessInstance_index       |  urn        |

### Queries

- CREATE INDEX dataset_index FOR (n:dataset) ON (n.urn)
- CREATE INDEX domain_index FOR (n:domain) ON (n.urn)
- CREATE INDEX corpuser_index FOR (n:corpuser) ON (n.urn)
- CREATE INDEX glossaryTerm_index FOR (n:glossaryTerm) ON (n.urn)
- CREATE INDEX glossaryNode_index FOR (n:glossaryNode) ON (n.urn)
- CREATE INDEX container_index FOR (n:container) ON (n.urn)
- CREATE INDEX schemaField_index FOR (n:schemaField) ON (n.urn)
- CREATE INDEX dataFlow_index FOR (n:dataFlow) ON (n.urn)
- CREATE INDEX dataProcessInstance_index FOR (n:dataProcessInstance) ON (n.urn)
- CREATE INDEX dataJob_index FOR (n:dataJob) ON (n.urn)
