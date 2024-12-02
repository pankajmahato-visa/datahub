# Code change 1    
    def get_inspectors(self):
        # This method can be overridden in the case that you want to dynamically
        # run on multiple databases.
        url = self.config.get_sql_alchemy_url()
        logger.debug(f"sql_alchemy_url={url}")
        engine = create_engine(url, **self.config.options)
        with engine.connect() as conn:
            inspector = inspect(conn)
            if self.config.database and self.config.database != "":
                databases = [self.config.database]
            else:
                databases = inspector.get_schema_names()
            for db in databases:
                try:
                    if self.config.database_pattern.allowed(db):
                        url = self.config.get_sql_alchemy_url(current_db=db)
                        with create_engine(
                            url, **self.config.options
                        ).connect() as conn:
                            inspector = inspect(conn)
                            yield inspector
                except Exception as e:
                    logger.exception(f"Failed to create connection with Database {db} -> {e}")
