
-- ***********************************************************************
--
-- This script creates a set of tables into qgis_pkg schema
-- feature_geometry_metadata, feature_attribute_metadata and layer_metadata tables will be duplicated under newly created usr_schema
-- List of tables:
--
-- qgis_pkg.usr_schema()
-- qgis_pkg.extents_template()
-- qgis_pkg.classname_lookup()
-- qgis_pkg.attribute_datatype_lookup()
-- qgis_pkg.feature_geometry_metadata_template()
-- qgis_pkg.feature_attribute_metadata_template()
-- qgis_pkg.layer_metadata_template()


------------------------------------------------------------------
-- TABLE qgis_pkg.user_schema
------------------------------------------------------------------
DROP TABLE IF EXISTS qgis_pkg.usr_schema CASCADE;
CREATE TABLE         qgis_pkg.usr_schema (
id				int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
usr_name		varchar,
usr_schema		varchar,
creation_date	timestamptz(0)
);
COMMENT ON TABLE qgis_pkg.usr_schema IS 'List of schemas for qgis users';

CREATE INDEX usr_schema_user_name_idx   ON qgis_pkg.usr_schema (usr_name);
CREATE INDEX usr_schema_user_schema_idx ON qgis_pkg.usr_schema (usr_schema);

-- Add user group, extent template table and two auxiliary lookup tables
DO $MAINBODY$
DECLARE
srid 			integer := (SELECT srid FROM citydb.database_srs LIMIT 1);
grp_name 		varchar;
cdb_schema 		varchar;
sql_statement	varchar;

BEGIN
grp_name := (SELECT qgis_pkg.create_qgis_pkg_usrgroup());
RAISE NOTICE 'Created group "%"',grp_name;

------------------------------------------------------------------
-- TABLE QGIS_PKG.EXTENTS_TEMPLATE
------------------------------------------------------------------
-- Written as dynamic SQL because we need to pass the SRID value
-- for the geometry in the envelope column.
sql_statement := concat('
DROP TABLE IF EXISTS qgis_pkg.extents_template  CASCADE;
CREATE TABLE         qgis_pkg.extents_template (
id				int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
cdb_schema		varchar NOT NULL,
bbox_type		varchar,
label			varchar,
creation_date	timestamptz(3),
envelope		geometry(Polygon,',srid,'),
CONSTRAINT		extents_bbox_type_check CHECK (bbox_type IN (''db_schema'', ''m_view'', ''qgis'')),
CONSTRAINT		extents_schema_bbox_key UNIQUE (cdb_schema, bbox_type)
);
COMMENT ON TABLE qgis_pkg.extents_template IS ''Extents (as bounding box) of data in the cdb_schema(s) and associated layers'';
');
EXECUTE sql_statement;

-- Check if 3DCityDB is set up and reference the tables in the default "citydb" schema
SELECT nspname INTO cdb_schema
FROM pg_namespace
WHERE nspname NOT LIKE 'pg_%'   -- Exclude system schemas
	AND nspname != 'information_schema'
	AND nspname = 'citydb';
IF cdb_schema IS NULL THEN
	RAISE EXCEPTION '3DCityDB is not set up yet, please install it first!';
ELSE
	RAISE NOTICE 'Referencing from the default 3DCityDB schema: "%"', cdb_schema;
END IF;

----------------------------------------------------------------
-- TABLE QGIS_PKG.CLASSNAME_LOOKUP
----------------------------------------------------------------
/*  Create metadata table of classname aliases for the feature that is not abstract */
sql_statement := concat('
DROP TABLE IF EXISTS qgis_pkg.classname_lookup CASCADE;
CREATE TABLE         qgis_pkg.classname_lookup AS
(
	SELECT 
		o.id 				AS oc_id, 
		o.classname			AS oc_name,
		CASE o.classname
			WHEN ''Address''                       THEN ''addr''
			WHEN ''ClosureSurface''                THEN ''cls_surf''
			WHEN ''CityModel''                     THEN ''ct_model''
			WHEN ''ImplicitGeometry''              THEN ''impl_geom''
			WHEN ''GenericLogicalSpace''           THEN ''gen_log_sp''
			WHEN ''GenericOccupiedSpace''          THEN ''gen_occ_sp''
			WHEN ''GenericUnoccupiedSpace''        THEN ''gen_unocc_sp''
			WHEN ''GenericThematicSurface''        THEN ''gen_them_surf''
			WHEN ''LandUse''                       THEN ''luse''
			WHEN ''PointCloud''                    THEN ''pcl''
			WHEN ''ReliefFeature''                 THEN ''rel_feat''
			WHEN ''TINRelief''                     THEN ''rel_tin''
			WHEN ''MassPointRelief''               THEN ''rel_masspt''
			WHEN ''BreaklineRelief''               THEN ''rel_brkline''
			WHEN ''RasterRelief''                  THEN ''rel_raster''
			WHEN ''Railway''                       THEN ''trn_rail''
			WHEN ''Section''                       THEN ''trn_sec''
			WHEN ''Waterway''                      THEN ''trn_wat''
			WHEN ''Intersection''                  THEN ''trn_int''
			WHEN ''Square''                        THEN ''trn_sq''
			WHEN ''Track''                         THEN ''trn_trk''
			WHEN ''Road''                          THEN ''trn_rd''
			WHEN ''AuxiliaryTrafficSpace''         THEN ''trn_aux_tr_sp''
			WHEN ''ClearanceSpace''                THEN ''trn_clr_sp''
			WHEN ''TrafficSpace''                  THEN ''trn_tr_sp''
			WHEN ''Hole''                          THEN ''trn_hole''
			WHEN ''AuxiliaryTrafficArea''          THEN ''trn_aux_tr_ar''
			WHEN ''TrafficArea''                   THEN ''trn_tr_ar''
			WHEN ''Marking''                       THEN ''trn_mark''
			WHEN ''HoleSurface''                   THEN ''trn_hl_surf''
			WHEN ''OtherConstruction''             THEN ''con_other''
			WHEN ''Door''                          THEN ''door''
			WHEN ''Window''                        THEN ''wndw''
			WHEN ''WallSurface''                   THEN ''wall_surf''
			WHEN ''GroundSurface''                 THEN ''gnd_surf''
			WHEN ''InteriorWallSurface''           THEN ''int_wall_surf''
			WHEN ''RoofSurface''                   THEN ''roof_surf''
			WHEN ''FloorSurface''                  THEN ''flr_surf''
			WHEN ''OuterFloorSurface''             THEN ''out_flr_surf''
			WHEN ''CeilingSurface''                THEN ''ceil_surf''
			WHEN ''OuterCeilingSurface''           THEN ''out_ceil_surf''
			WHEN ''DoorSurface''                   THEN ''door_surf''
			WHEN ''WindowSurface''                 THEN ''wndw_surf''
			WHEN ''Tunnel''                        THEN ''tun''
			WHEN ''TunnelPart''                    THEN ''tun_part''
			WHEN ''TunnelConstructiveElement''     THEN ''tun_constr_elem''
			WHEN ''HollowSpace''                   THEN ''tun_hol_sp''
			WHEN ''TunnelInstallation''            THEN ''tun_inst''
			WHEN ''TunnelFurniture''               THEN ''tun_frn''
			WHEN ''Building''                      THEN ''bdg''
			WHEN ''BuildingPart''                  THEN ''bdg_part''
			WHEN ''BuildingConstructiveElement''   THEN ''bdg_constr_elem''
			WHEN ''BuildingRoom''                  THEN ''bdg_room''
			WHEN ''BuildingInstallation''          THEN ''bdg_inst''
			WHEN ''BuildingFurniture''             THEN ''bdg_frn''
			WHEN ''BuildingUnit''                  THEN ''bdg_unit''
			WHEN ''Storey''                        THEN ''bdg_storey''
			WHEN ''Bridge''                        THEN ''bri''
			WHEN ''BridgePart''                    THEN ''bri_part''
			WHEN ''BridgeConstructiveElement''     THEN ''bri_constr_elem''
			WHEN ''BridgeRoom''                    THEN ''bri_room''
			WHEN ''BridgeInstallation''            THEN ''bri_inst''
			WHEN ''BridgeFurniture''               THEN ''bri_frn''
			WHEN ''CityObjectGroup''               THEN ''cityobj_grp''
			WHEN ''SolitaryVegetationObject''      THEN ''sol_veg_obj''
			WHEN ''PlantCover''                    THEN ''plant_cov''
			WHEN ''WaterBody''                     THEN ''wtr_body''
			WHEN ''WaterSurface''                  THEN ''wtr_surf''
			WHEN ''WaterGroundSurface''            THEN ''wtr_gnd_surf''
			WHEN ''CityFurniture''                 THEN ''city_frn''
		END AS oc_alias,
		CASE n.alias 
			WHEN ''core'' THEN ''Core''
			WHEN ''dyn''  THEN ''Dynamizer''
			WHEN ''gen''  THEN ''Generics''
			WHEN ''luse'' THEN ''Landuse''
			WHEN ''pcl''  THEN ''Pointcloud''
			WHEN ''dem''  THEN ''Relief''
			WHEN ''tran'' THEN ''Transportation''
			WHEN ''con''  THEN ''Construction''
			WHEN ''tun'' 	THEN ''Tunnel''
			WHEN ''bldg'' THEN ''Building''
			WHEN ''brid'' THEN ''Bridge''
			WHEN ''app''  THEN ''Appearance''
			WHEN ''grp''  THEN ''Cityobjectgroup''
			WHEN ''veg''  THEN ''Vegetation''
			WHEN ''vers'' THEN ''Versions''
			WHEN ''wtr''  THEN ''Waterbody''
			WHEN ''frn''  THEN ''Cityfurniture''
			WHEN ''depr'' THEN ''Deprecated''
		END AS feature_type,
		o.is_toplevel,
		o.ade_id,
		o.namespace_id
	FROM ',cdb_schema,'.objectclass AS o
		INNER JOIN ',cdb_schema,'.namespace AS n ON o.namespace_id = n.id
	WHERE is_abstract = 0
		AND n.alias NOT IN (''dyn'', ''app'', ''grp'', ''vers'')
	ORDER BY o.id
);
COMMENT ON TABLE qgis_pkg.classname_lookup IS ''List of classname information for layer name creation'';

CREATE INDEX ocl_oc_id_idx 				ON qgis_pkg.classname_lookup (oc_id);
CREATE INDEX ocl_classname_idx     		ON qgis_pkg.classname_lookup (oc_name);
CREATE INDEX ocl_oc_alias_idx      		ON qgis_pkg.classname_lookup (oc_alias);
CREATE INDEX ocl_feature_type_idx      	ON qgis_pkg.classname_lookup (feature_type);
CREATE INDEX ocl_is_top_level_idx   	ON qgis_pkg.classname_lookup (is_toplevel);
CREATE INDEX ocl_ade_id_idx   			ON qgis_pkg.classname_lookup (ade_id);
CREATE INDEX ocl_namesapce_idx 			ON qgis_pkg.classname_lookup (namespace_id);
');
EXECUTE sql_statement;

----------------------------------------------------------------
-- TABLE QGIS_PKG.ATTRIBUTE_DATATYPE_LOOKUP
----------------------------------------------------------------
sql_statement := concat('
DROP TABLE IF EXISTS qgis_pkg.attribute_datatype_lookup CASCADE;
CREATE TABLE qgis_pkg.attribute_datatype_lookup AS(
	SELECT 
		d.id,
		d.typename,
		d.namespace_id,
		n.alias,
		d.schema,
		CASE d.typename
			WHEN ''CityObjectRelation'' 	THEN 1
			WHEN ''Occupancy'' 				THEN 1
			WHEN ''SensorConnection'' 		THEN 1
			WHEN ''TimeseriesComponent''	THEN 1
			WHEN ''TimeValuePair''			THEN 1
			WHEN ''GenericAttributeSet''	THEN 1
			WHEN ''ConstructionEvent''		THEN 1
			WHEN ''Height''					THEN 1
			WHEN ''RoomHeight''				THEN 1
			WHEN ''Role''					THEN 1
			WHEN ''Transaction''			THEN 1
		ELSE 0
		END AS is_nested, -- 1: nested attribute, 0: inline attribute
		CASE d.typename
			WHEN ''Boolean''  				THEN 1
			WHEN ''Integer''  				THEN 1
			WHEN ''Double''  				THEN 1
			WHEN ''String''  				THEN 1
			WHEN ''URI''  					THEN 1
			WHEN ''Timestamp''  			THEN 1
			WHEN ''AddressProperty'' 		THEN 2
			WHEN ''AppearanceProperty''  	THEN 1
			WHEN ''FeatureProperty'' 		THEN 2
			WHEN ''Reference'' 				THEN 1
			WHEN ''Code'' 					THEN 2
			WHEN ''ExternalReference'' 		THEN 3
			WHEN ''Measure'' 				THEN 2
			WHEN ''MeasureOrNilReasonList'' THEN 2
			WHEN ''QualifiedArea'' 			THEN 3
			WHEN ''QualifiedVolume'' 		THEN 3
			WHEN ''StringOrRef'' 			THEN 2
			WHEN ''Elevation'' 				THEN 3
		END AS val_col_num, -- the number of columns in which the attribute values are stored
		CASE d.typename
			WHEN ''Boolean''  				THEN ARRAY[''val_int'']
			WHEN ''Integer''  				THEN ARRAY[''val_int'']
			WHEN ''Double''  				THEN ARRAY[''val_double'']
			WHEN ''String''  				THEN ARRAY[''val_string'']
			WHEN ''URI''  					THEN ARRAY[''val_uri'']
			WHEN ''Timestamp''  			THEN ARRAY[''val_timestamp'']
			WHEN ''AddressProperty'' 		THEN ARRAY[''val_address_id'',''val_relation_type'']
			WHEN ''AppearanceProperty''  	THEN ARRAY[''val_appearance_id'']
			WHEN ''FeatureProperty'' 		THEN ARRAY[''val_feature_id'',''val_relation_type'']
			WHEN ''Reference'' 				THEN ARRAY[''val_uri'']
			WHEN ''Code'' 					THEN ARRAY[''val_string'',''val_codespace'']
			WHEN ''ExternalReference'' 		THEN ARRAY[''val_uri'',''val_codespace'',''val_string'']
			WHEN ''Measure'' 				THEN ARRAY[''val_double'',''val_uom'']
			WHEN ''MeasureOrNilReasonList'' THEN ARRAY[''val_array'',''val_uom'']
			WHEN ''QualifiedArea'' 			THEN ARRAY[''val_double'',''val_string'',''val_codespace'']
			WHEN ''QualifiedVolume'' 		THEN ARRAY[''val_double'',''val_string'',''val_codespace'']
			WHEN ''StringOrRef'' 			THEN ARRAY[''val_string'',''val_uri'']
			WHEN ''Elevation'' 				THEN ARRAY[''val_array'',''val_string'',''val_codespace'']
		END AS val_col
	FROM ',cdb_schema,'.datatype AS d
		INNER JOIN ',cdb_schema,'.namespace AS n ON d.namespace_id = n.id
	ORDER BY d.id
);
COMMENT ON TABLE qgis_pkg.attribute_datatype_lookup IS ''List of attribute values storage column name'';

CREATE INDEX adl_id_idx             ON qgis_pkg.attribute_datatype_lookup (id);
CREATE INDEX adl_dtname_idx         ON qgis_pkg.attribute_datatype_lookup (typename);
CREATE INDEX adl_namespace_id_idx   ON qgis_pkg.attribute_datatype_lookup (namespace_id);
CREATE INDEX adl_nalias_idx      	ON qgis_pkg.attribute_datatype_lookup (alias);
CREATE INDEX adl_val_col_num_idx    ON qgis_pkg.attribute_datatype_lookup (val_col_num);
CREATE INDEX adl_val_col_1_idx     	ON qgis_pkg.attribute_datatype_lookup (val_col);
ALTER TABLE qgis_pkg.attribute_datatype_lookup
ADD CONSTRAINT is_nested_check CHECK (is_nested IN (0, 1));
');
EXECUTE sql_statement;
END $MAINBODY$;


----------------------------------------------------------------
-- TABLE QGIS_PKG.FEATURE_GEOMETRY_METADATA_TEMPLATE
----------------------------------------------------------------
--  Create empty metadata table of existing feature geometries within a given database 
DROP TABLE IF EXISTS qgis_pkg.feature_geometry_metadata_template CASCADE;
CREATE TABLE         qgis_pkg.feature_geometry_metadata_template (
id							bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
cdb_schema					varchar,
bbox_type					varchar,
parent_objectclass_id		integer, 				-- 0 as NULL for space feature
parent_classname			varchar,				-- parent objectclass name, '-' as NULL
objectclass_id				integer, 				-- feature's objectclass_id
classname					varchar,				-- objectclass name
datatype_id					integer, 				-- geometry or implicit geometry id
geometry_name				text, 	 				-- lod & geometry representation
lod							text, 	 				-- value in ('0', '1', '2', '3')
geometry_type				text, 	 				-- geometry representation
postgis_geom_type	 		text,    				-- geometry type stored by postgresql, like "MultiPolygonZ"
last_modification_date		timestamptz(3), 		-- the end time when the feature geometry is checked, excluding the mv part
view_name					varchar,				-- geometry view name
is_matview					boolean DEFAULT FALSE,  -- identifier for which type of layer should be using the MV
mview_name					varchar,				-- geometry materialized view name
mv_creation_time			TIME(3), 				-- creation time of materialized view
mv_refresh_time				TIME(3), 				-- refresh time of materialized view
mv_last_update_time			timestamptz(3),  		-- the end time when the materialized view is refreshed,
CONSTRAINT _g_extents_bbox_type_check CHECK (bbox_type IN ('db_schema', 'm_view', 'qgis'))
-- possibly other columns with other qml files
);
COMMENT ON TABLE qgis_pkg.feature_geometry_metadata_template IS 'List of schema and their exisitng feature geometry metadata';

CREATE INDEX fgmeta_cdb_schema_idx 		ON qgis_pkg.feature_geometry_metadata_template (cdb_schema);
CREATE INDEX fgmeta_bbox_type_idx 		ON qgis_pkg.feature_geometry_metadata_template (bbox_type);
CREATE INDEX fgmeta_poc_id_idx    		ON qgis_pkg.feature_geometry_metadata_template (parent_objectclass_id);
CREATE INDEX fgmeta_poc_name_idx    	ON qgis_pkg.feature_geometry_metadata_template (parent_classname);
CREATE INDEX fgmeta_oc_id_idx      		ON qgis_pkg.feature_geometry_metadata_template (objectclass_id);
CREATE INDEX fgmeta_oc_name_idx    		ON qgis_pkg.feature_geometry_metadata_template (classname);
CREATE INDEX fgmeta_datatype_idx   		ON qgis_pkg.feature_geometry_metadata_template (datatype_id);
CREATE INDEX fgmeta_gname_idx      		ON qgis_pkg.feature_geometry_metadata_template (geometry_name);
CREATE INDEX fgmeta_lod_idx	       		ON qgis_pkg.feature_geometry_metadata_template (lod);
CREATE INDEX fgmeta_gtype_idx      		ON qgis_pkg.feature_geometry_metadata_template (geometry_type);
CREATE INDEX fgmeta_pgtype_idx     		ON qgis_pkg.feature_geometry_metadata_template (postgis_geom_type);
CREATE INDEX fgmeta_lupdate_idx    	 	ON qgis_pkg.feature_geometry_metadata_template (last_modification_date);
CREATE INDEX fgmeta_vname_idx    	 	ON qgis_pkg.feature_geometry_metadata_template (view_name);
CREATE INDEX fgmeta_ismv_idx  			ON qgis_pkg.feature_geometry_metadata_template (is_matview);
CREATE INDEX fgmeta_mvname_idx    	 	ON qgis_pkg.feature_geometry_metadata_template (mview_name);
CREATE INDEX fgmeta_mvcreate_idx  		ON qgis_pkg.feature_geometry_metadata_template (mv_creation_time);
CREATE INDEX fgmeta_mvrefresh_idx  		ON qgis_pkg.feature_geometry_metadata_template (mv_refresh_time);
CREATE INDEX fgmeta_mvlupdate_idx  		ON qgis_pkg.feature_geometry_metadata_template (mv_last_update_time);

ALTER TABLE qgis_pkg.feature_geometry_metadata_template
ADD CONSTRAINT unique_fg_metadata
UNIQUE (cdb_schema, parent_objectclass_id, objectclass_id, datatype_id, geometry_name, lod, geometry_type, postgis_geom_type);

----------------------------------------------------------------
-- TABLE QGIS_PKG.FEATURE_ATTIBUTE_METADATA_TEMPLATE
----------------------------------------------------------------
--  Create empty metadata table of existing feature attributes within a given database 
DROP TABLE IF EXISTS qgis_pkg.feature_attribute_metadata_template CASCADE;
CREATE TABLE         qgis_pkg.feature_attribute_metadata_template (
id							bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
cdb_schema					varchar,
bbox_type					varchar,
objectclass_id				integer,
classname					varchar,
parent_attribute_name		varchar, -- NULL if not nested attribute
parent_attribute_typename	varchar, -- NULL if not nested attribute
attribute_name				varchar,
attribute_typename			varchar,
is_nested					boolean, -- false: inline, true: nested
is_multiple     			boolean, -- false: single, true: multiple
max_multiplicity			integer, 
is_multiple_value_columns	boolean, -- false: single value columns, true: multiple value columns
ct_type_name				varchar, -- null if the attribute has only one value column
n_value_columns				integer,
value_column				text[],
last_modification_date		timestamptz(3),
view_name 					varchar, -- maximum length of the view name
view_creation_date			timestamptz(3),
mview_name					varchar, ---- maximum length of the view name
mview_refresh_date			timestamptz(3),	-- include the mview_creation_date since it is refreshed after its creation,
CONSTRAINT _a_extents_bbox_type_check CHECK (bbox_type IN ('db_schema', 'm_view', 'qgis'))
-- possibly other columns with other qml files
);

COMMENT ON TABLE qgis_pkg.feature_attribute_metadata_template IS 'List of schema and the existing feature attribute metadata';
CREATE INDEX fameta_id_idx 					ON qgis_pkg.feature_attribute_metadata_template (id);
CREATE INDEX fameta_cdb_schema_idx 			ON qgis_pkg.feature_attribute_metadata_template (cdb_schema);
CREATE INDEX fameta_bbox_type_idx 			ON qgis_pkg.feature_attribute_metadata_template (bbox_type);
CREATE INDEX fameta_oc_id_idx     			ON qgis_pkg.feature_attribute_metadata_template (objectclass_id);
CREATE INDEX fameta_oc_name_idx     		ON qgis_pkg.feature_attribute_metadata_template (classname);
CREATE INDEX fameta_p_attri_name_idx   		ON qgis_pkg.feature_attribute_metadata_template (parent_attribute_name);
CREATE INDEX fameta_p_attri_tname_idx   	ON qgis_pkg.feature_attribute_metadata_template (parent_attribute_typename);
CREATE INDEX fameta_attri_name_idx   		ON qgis_pkg.feature_attribute_metadata_template (attribute_name);
CREATE INDEX fameta_attri_tname_idx   		ON qgis_pkg.feature_attribute_metadata_template (attribute_typename);
CREATE INDEX fameta_is_nested_idx   		ON qgis_pkg.feature_attribute_metadata_template (is_nested);
CREATE INDEX fameta_is_multiple_idx   		ON qgis_pkg.feature_attribute_metadata_template (is_multiple);
CREATE INDEX fameta_max_multi_idx   		ON qgis_pkg.feature_attribute_metadata_template (max_multiplicity);
CREATE INDEX fameta_is_multi_val_col_idx   	ON qgis_pkg.feature_attribute_metadata_template (is_multiple_value_columns);
CREATE INDEX fameta_ct_type_name_idx   		ON qgis_pkg.feature_attribute_metadata_template (ct_type_name);
CREATE INDEX fameta_n_val_cols_idx   		ON qgis_pkg.feature_attribute_metadata_template (n_value_columns);
CREATE INDEX fameta_val_col_idx   			ON qgis_pkg.feature_attribute_metadata_template (value_column);
CREATE INDEX fameta_lupdate_idx    			ON qgis_pkg.feature_attribute_metadata_template (last_modification_date);
CREATE INDEX fameta_vname_idx    			ON qgis_pkg.feature_attribute_metadata_template (view_name);
CREATE INDEX fameta_vdate_idx    			ON qgis_pkg.feature_attribute_metadata_template (view_creation_date);
CREATE INDEX fameta_mvname_idx    			ON qgis_pkg.feature_attribute_metadata_template (mview_name);
CREATE INDEX fameta_mv_refresh_idx    		ON qgis_pkg.feature_attribute_metadata_template (mview_refresh_date);

ALTER TABLE qgis_pkg.feature_attribute_metadata_template
ADD CONSTRAINT unique_fa_metadata
UNIQUE (cdb_schema, objectclass_id, classname, parent_attribute_name, attribute_name);


------------------------------------------------------------------
-- TABLE QGIS_PKG.LAYER_METADATA_TEMPLATE
------------------------------------------------------------------
DROP TABLE IF EXISTS qgis_pkg.layer_metadata_template CASCADE;
CREATE TABLE         qgis_pkg.layer_metadata_template (
id						bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
cdb_schema				varchar,
-- ade_prefix		varchar, -- NULL for standard CityGML, otherwise the prefix used by the selected ADE.
-- layer_type		varchar, -- Value in (VectorLayer, DetailView, VectorLayerNoGeom, DetailViewNoGeom)
feature_type			varchar, -- CityGML package/module name
-- root_class		varchar, -- The CityGML top class in the respective CityGML module (Building, Road, ...)
parent_objectclass_id  	integer, -- Null for Space features
parent_classname		varchar, -- Null for Space features
objectclass_id  		integer,
classname				varchar,
lod						varchar(4), -- value in ('lod0', 'lod1', 'lod2', 'lod3', 'lodx' for no lod)
geometry_type			varchar,
layer_name				varchar UNIQUE, -- contains the layer name
gv_name					varchar,
inline_attris			varchar[], -- stores the selected inline attribute names by users
nested_attris			varchar[], -- stores the selected nested attribute names by users
is_matview				boolean, -- indicates whether the generated layer is stored as view or matview
is_all_attris			boolean, -- indicates whether all exisiting attributes regarding the class are selected
is_joins				boolean DEFAULT FALSE, -- indicates the approach for layer creation (TRUE for using approach 1 & 2 to have multiple joins)
av_table_name			varchar, -- stores the integrated attribute table view name, null for using approach 1 & 2 (multiple joins)
av_join_names			varchar[], -- stores the selected individual attribute view names, null for using the default approach 3 (table)
n_features				integer,
creation_date			timestamptz(3)
-- refresh_date			timestamptz(3)
-- qml_form		varchar, -- name of the qml file containing QGIS Field and Forms configurations
-- qml_symb		varchar, -- name of the qml file containing QGIS 2D symbology configuration
-- qml_3d			varchar,  -- name of the qml file containing QGIS 3D symbology configuration
-- possibly other columns with other qml files
-- enum_cols		varchar[][], -- array containing the class and column names that are linked to enumerations in the GUI form
-- codelist_cols	varchar[][]  -- array containing class and column names that may be linked to codelists in the GUI form
);
COMMENT ON TABLE qgis_pkg.layer_metadata_template IS 'List of layers and their metadata';

CREATE INDEX lmeta_id_idx 		  		ON qgis_pkg.layer_metadata_template (id);
CREATE INDEX lmeta_cdb_schema_idx 		ON qgis_pkg.layer_metadata_template (cdb_schema);
CREATE INDEX lmeta_f_type_idx     		ON qgis_pkg.layer_metadata_template (feature_type);
CREATE INDEX lmeta_p_oc_id_idx    		ON qgis_pkg.layer_metadata_template (parent_objectclass_id);
CREATE INDEX lmeta_p_class_idx    		ON qgis_pkg.layer_metadata_template (parent_classname);
CREATE INDEX lmeta_oc_id_idx      		ON qgis_pkg.layer_metadata_template (objectclass_id);
CREATE INDEX lmeta_class_idx      		ON qgis_pkg.layer_metadata_template (classname);
CREATE INDEX lmeta_lod_idx        		ON qgis_pkg.layer_metadata_template (lod);
CREATE INDEX lmeta_g_type_idx        	ON qgis_pkg.layer_metadata_template (geometry_type);
CREATE INDEX lmeta_l_name_idx     		ON qgis_pkg.layer_metadata_template (layer_name);
CREATE INDEX lmeta_gv_name_idx    		ON qgis_pkg.layer_metadata_template (gv_name);
CREATE INDEX lmeta_i_attri_names_idx    ON qgis_pkg.layer_metadata_template (inline_attris);
CREATE INDEX lmeta_n_attri_names_idx    ON qgis_pkg.layer_metadata_template (nested_attris);
CREATE INDEX lmeta_is_matview_idx   	ON qgis_pkg.layer_metadata_template (is_matview);
CREATE INDEX lmeta_is_all_attris_idx   	ON qgis_pkg.layer_metadata_template (is_all_attris);
CREATE INDEX lmeta_is_joins_idx   		ON qgis_pkg.layer_metadata_template (is_joins);
CREATE INDEX lmeta_av_table_name_idx   	ON qgis_pkg.layer_metadata_template (av_table_name);
CREATE INDEX lmeta_av_join_names_idx   	ON qgis_pkg.layer_metadata_template (av_join_names);
CREATE INDEX lmeta_nf_idx         		ON qgis_pkg.layer_metadata_template (n_features);
CREATE INDEX lmeta_cd_idx         		ON qgis_pkg.layer_metadata_template (creation_date);


--**************************
DO $$
BEGIN
RAISE NOTICE E'\n\nDone\n\n';
END $$;
--**************************
