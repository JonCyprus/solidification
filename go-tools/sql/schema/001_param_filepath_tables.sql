CREATE TABLE simulations.twobody_parameters (
                                                    temperature double precision,
                                                    density double precision,
                                                    version text,
                                                    runID uuid UNIQUE,
                                                    note text,
                                                    created_at timestamp NOT NULL,
                                                    updated_at timestamp NOT NULL,
                                                    CONSTRAINT twobody_param_composite_pk PRIMARY KEY (temperature, density, version)
                                                );
)

CREATE TABLE simulations.twobody_filepaths (
                                                   runID uuid,
                                                   category text,
                                                   timestep bigint,
                                                   filename text NOT NULL,
                                                   created_at timestamp NOT NULL,
                                                   updated_at timestamp NOT NULL,
                                                   CONSTRAINT runID_fk FOREIGN KEY (runID)
                                                       REFERENCES simulations.twobody_parameters (runID)
                                                       ON DELETE CASCADE,
                                                   CONSTRAINT twobody_files_composite_pk PRIMARY KEY (runID, category, timestep)
                                               );
)