# Code change 1
# Add try catch to method loop_tables ( line 594)
    def loop_tables(  # noqa: C901
        self,
        inspector: Inspector,
        schema: str,
        sql_config: SQLCommonConfig,
    ) -> Iterable[Union[SqlWorkUnit, MetadataWorkUnit]]:
        tables_seen: Set[str] = set()
        data_reader = self.make_data_reader(inspector)
        with data_reader or contextlib.nullcontext():
            try:
                for table in inspector.get_table_names(schema):
                    try:
                        dataset_name = self.get_identifier(
                            schema=schema, entity=table, inspector=inspector
                        )

                        if dataset_name not in tables_seen:
                            tables_seen.add(dataset_name)
                        else:
                            logger.debug(
                                f"{dataset_name} has already been seen, skipping..."
                            )
                            continue

                        self.report.report_entity_scanned(dataset_name, ent_type="table")
                        if not sql_config.table_pattern.allowed(dataset_name):
                            self.report.report_dropped(dataset_name)
                            continue

                        try:
                            yield from self._process_table(
                                dataset_name,
                                inspector,
                                schema,
                                table,
                                sql_config,
                                data_reader,
                            )
                        except Exception as e:
                            self.report.warning(
                                "Error processing table",
                                context=f"{schema}.{table}",
                                exc=e,
                            )
                    except Exception as e:
                        self.report.failure(
                            "Error processing tables",
                            context=schema,
                            exc=e,
                        )
            except Exception as e:
                self.report.failure(
                    "Error processing tables",
                    context=schema,
                    exc=e,
                )

# Code change 2
# Add exception log message

    def _get_columns(
        self, dataset_name: str, inspector: Inspector, schema: str, table: str
    ) -> List[dict]:
        columns = []
        try:
            columns = inspector.get_columns(table, schema)
            if len(columns) == 0:
                self.warn(logger, MISSING_COLUMN_INFO, dataset_name)
        except Exception as e:
            self.warn(
                logger,
                dataset_name,
                f"unable to get column information due to an error -> {''.join(traceback.format_tb(e.__traceback__))}",
            )
        return columns

# Code change 3
# Comment out "sqlalchemy_log._add_default_handler"
def get_workunits_internal(self) -> Iterable[Union[MetadataWorkUnit, SqlWorkUnit]]:
        sql_config = self.config
        if logger.isEnabledFor(logging.DEBUG):
            # If debug logging is enabled, we also want to echo each SQL query issued.
            sql_config.options.setdefault("echo", True)
            # Patch to avoid duplicate logging
            # Known issue with sqlalchemy https://stackoverflow.com/questions/60804288/pycharm-duplicated-log-for-sqlalchemy-echo-true
            # sqlalchemy_log._add_default_handler = lambda x: None  # type: ignore
