ALTER TABLE "twobody_parameters"
ADD COLUMN "is_converged" boolean DEFAULT 'FALSE';

ALTER TABLE "twobody_parameters"
ADD COLUMN "total_time" double precision DEFAULT '0';

