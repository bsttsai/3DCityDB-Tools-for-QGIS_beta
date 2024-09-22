-- List of functions:
--
-- qgis_pkg.check_layer()

----------------------------------------------------------------
-- Create FUNCTION QGIS_PKG.CHECK_LAYER
----------------------------------------------------------------
DROP FUNCTION IF EXISTS qgis_pkg.check_layer(varchar, varchar, integer, integer, varchar) CASCADE;
CREATE OR REPLACE FUNCTION qgis_pkg.check_layer(
	usr_schema varchar,
	cdb_schema varchar,
	objectclass_id integer,
	srid integer,
	cdb_bbox_type varchar DEFAULT 'db_schema'
) 
RETURNS void AS $$
DECLARE
	qi_cdb_schema varchar 				:= quote_ident(cdb_schema);
	cdb_schema_name varchar 			:= quote_literal(cdb_schema);
	cdb_bbox_type_array CONSTANT varchar[]	:= ARRAY['db_schema', 'm_view', 'qgis']; cdb_envelope geometry; srid integer;
	classname varchar					:= (SELECT qgis_pkg.objectclass_id_to_classname(qi_cdb_schema, objectclass_id));
	geom_datatype_id integer 			:= NULL;
	implicit_geom_datatype_id integer 	:= NULL;
	sql_space_feature text 				:= NULL;
	sql_where text 						:= NULL;

BEGIN
-- Check if cdb_schema exists
IF qi_cdb_schema IS NULL or NOT EXISTS(SELECT 1 FROM information_schema.schemata AS i WHERE i.schema_name::varchar = qi_cdb_schema) THEN
	RAISE EXCEPTION 'cdb_schema (%) not found. It must be an existing schema', qi_cdb_schema;
END IF;

-- Check if feature geometry metadata table exists
IF NOT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'qgis_pkg' AND table_name = 'feature_geometry_metadata') THEN
	RAISE EXCEPTION 'qgis_pkg.feature_geometry_metadata table not yet created. Please create it first';
END IF;

-- Check that the cdb_box_type is a valid value
IF cdb_bbox_type IS NULL OR NOT (cdb_bbox_type = ANY (cdb_bbox_type_array)) THEN
	RAISE EXCEPTION 'cdb_bbox_type value is invalid. It must be one of (%)', cdb_bbox_type_array;
END IF;

-- Get the srid from the cdb_schema
EXECUTE format('SELECT srid FROM %I.database_srs LIMIT 1', cdb_schema) INTO srid;
-- Get the cdb_envelope from the extents table in the usr_schema
EXECUTE format ('SELECT envelope FROM %I.extents WHERE cdb_schema = %L AND bbox_type = %L', usr_schema, cdb_schema, cdb_bbox_type) INTO cdb_envelope;

-- Check whether the retrived extent exists 
IF cdb_envelope IS NULL THEN
	RAISE EXCEPTION 'cdb_envelope is invalid. Please first upsert the extent of cdb_bbox_type: %', cdb_bbox_type;
END IF;

-- Check that the srid is the same to the cdb_envelope
IF ST_SRID(cdb_envelope) IS NULL OR ST_SRID(cdb_envelope) <> srid OR cdb_bbox_type = 'db_schema' THEN
	sql_where := NULL;
ELSE
	sql_where := concat(' AND ST_MakeEnvelope(',ST_XMin(cdb_envelope),',',ST_YMin(cdb_envelope),',',ST_XMax(cdb_envelope),',',ST_YMax(cdb_envelope),',',srid,') && f.envelope ');
END IF;
	
-- Get the datatype_id of GeometryProperty and ImplicitGeometryProperty
EXECUTE format('SELECT * FROM qgis_pkg.datatype_name_to_type_id(%L, %L)', qi_cdb_schema, 'GeometryProperty') INTO geom_datatype_id;
EXECUTE format('SELECT * FROM qgis_pkg.datatype_name_to_type_id(%L, %L)', qi_cdb_schema, 'ImplicitGeometryProperty') INTO implicit_geom_datatype_id;


sql_space_feature := concat('');

EXCEPTION
	WHEN QUERY_CANCELED THEN
		RAISE EXCEPTION 'qgis_pkg.check_layer(): Error QUERY_CANCELED';
 	WHEN OTHERS THEN
		RAISE EXCEPTION 'qgis_pkg.check_layer(): %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION qgis_pkg.check_layer(varchar, varchar, integer, integer, varchar) IS 'Check the existence of the generated layers in the usr_schema';
REVOKE EXECUTE ON FUNCTION qgis_pkg.check_layer(varchar, varchar, integer, integer, varchar) FROM PUBLIC;